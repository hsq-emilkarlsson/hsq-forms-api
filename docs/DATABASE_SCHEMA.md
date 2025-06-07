# HSQ Forms API Database Schema

This document provides detailed information about how form responses, file attachments, and templates are stored in the PostgreSQL database within the HSQ Forms API.

## Overview

The HSQ Forms API uses PostgreSQL as its primary database for storing:
- Form submissions
- File attachment metadata
- Form templates
- Relationships between these entities

This document outlines the database schema, relationships, and data flow to help with integration and querying.

## Database Tables

### Core Tables

The database includes these primary tables:

1. **form_submissions**: Stores standard contact form submissions
2. **file_attachments**: Stores metadata for files uploaded with form submissions
3. **form_templates**: Stores dynamic form templates with JSON schemas
4. **flexible_form_submissions**: Stores submissions for dynamic form templates
5. **flexible_form_attachments**: Stores file attachments for flexible forms

## Schema Definitions

### form_submissions

This table stores basic form submissions with a fixed schema:

```sql
CREATE TABLE form_submissions (
    id VARCHAR PRIMARY KEY,                                     -- UUID for submission
    form_type VARCHAR(50) NOT NULL DEFAULT 'contact',           -- Type identifier (contact, feedback, etc.)
    name VARCHAR(100) NOT NULL,                                 -- Submitter's name
    email VARCHAR(255) NOT NULL,                                -- Submitter's email
    message TEXT NOT NULL,                                      -- Primary message content
    form_metadata JSONB,                                        -- Additional metadata as JSON
    ip_address VARCHAR(45),                                     -- Submitter's IP address
    user_agent TEXT,                                            -- Browser/client information
    is_processed BOOLEAN NOT NULL DEFAULT false,                -- Processing status flag
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), -- Creation timestamp
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()  -- Last update timestamp
);

-- Indexes for query optimization
CREATE INDEX idx_form_submissions_form_type ON form_submissions(form_type);
CREATE INDEX idx_form_submissions_email ON form_submissions(email);
CREATE INDEX idx_form_submissions_created_at ON form_submissions(created_at DESC);
```

### file_attachments

This table stores metadata about files uploaded with form submissions:

```sql
CREATE TABLE file_attachments (
    id VARCHAR PRIMARY KEY,                                     -- UUID for file record
    submission_id VARCHAR NOT NULL,                             -- Foreign key to form_submissions
    original_filename VARCHAR(255) NOT NULL,                    -- Original filename from user
    stored_filename VARCHAR(255) NOT NULL,                      -- Actual storage filename or blob name
    file_size INTEGER NOT NULL,                                 -- File size in bytes
    content_type VARCHAR(100) NOT NULL,                         -- MIME type
    blob_url VARCHAR(500),                                      -- Full URL for Azure Blob Storage
    upload_status VARCHAR(20) NOT NULL DEFAULT 'uploaded',      -- Status: uploaded, processing, error
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), -- Upload timestamp
    
    -- Relationship constraint with cascade delete
    FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE
);

-- Index for efficient queries by submission
CREATE INDEX idx_file_attachments_submission_id ON file_attachments(submission_id);
```

### form_templates

This table stores dynamic form templates with JSON schemas:

```sql
CREATE TABLE form_templates (
    id VARCHAR PRIMARY KEY,                                      -- UUID for template
    name VARCHAR(100) NOT NULL,                                  -- Template name
    description TEXT,                                            -- Optional description
    project_id VARCHAR(50) NOT NULL DEFAULT 'default',           -- Project identifier
    schema JSONB NOT NULL,                                       -- JSON schema for the form
    validation_rules JSONB,                                      -- Optional validation rules
    is_active BOOLEAN NOT NULL DEFAULT true,                     -- Active status flag
    created_by VARCHAR(100),                                     -- Creator identifier
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),  -- Creation timestamp
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()   -- Last update timestamp
);

-- Indexes
CREATE INDEX idx_form_templates_project_id ON form_templates(project_id);
CREATE INDEX idx_form_templates_is_active ON form_templates(is_active);
```

### flexible_form_submissions

This table stores submissions for dynamic forms defined by templates:

```sql
CREATE TABLE flexible_form_submissions (
    id VARCHAR PRIMARY KEY,                                      -- UUID for submission
    template_id VARCHAR NOT NULL,                                -- Foreign key to form_templates
    data JSONB NOT NULL,                                         -- Dynamic form data as JSON
    submitted_by VARCHAR(100),                                   -- Submitter identifier
    submitted_from_ip VARCHAR(45),                               -- Submitter's IP address
    submitted_from_project VARCHAR(50),                          -- Source project
    user_agent TEXT,                                             -- Browser/client information
    is_processed BOOLEAN NOT NULL DEFAULT false,                 -- Processing status flag
    processing_notes TEXT,                                       -- Optional processing notes
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),  -- Creation timestamp
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),  -- Last update timestamp
    
    -- Relationship constraint
    FOREIGN KEY (template_id) REFERENCES form_templates(id)
);

-- Indexes
CREATE INDEX idx_flexible_form_submissions_template_id ON flexible_form_submissions(template_id);
CREATE INDEX idx_flexible_form_submissions_created_at ON flexible_form_submissions(created_at DESC);
CREATE INDEX idx_flexible_form_submissions_is_processed ON flexible_form_submissions(is_processed);
```

### flexible_form_attachments

This table stores file attachments for flexible form submissions:

```sql
CREATE TABLE flexible_form_attachments (
    id VARCHAR PRIMARY KEY,                                      -- UUID for file record
    submission_id VARCHAR NOT NULL,                              -- Foreign key to flexible_form_submissions
    field_name VARCHAR(100) NOT NULL,                            -- Form field name this file belongs to
    original_filename VARCHAR(255) NOT NULL,                     -- Original filename from user
    stored_filename VARCHAR(255) NOT NULL,                       -- Actual storage filename or blob name
    file_size INTEGER NOT NULL,                                  -- File size in bytes
    content_type VARCHAR(100) NOT NULL,                          -- MIME type
    blob_url VARCHAR(500),                                       -- Full URL for Azure Blob Storage
    upload_status VARCHAR(20) NOT NULL DEFAULT 'uploaded',       -- Status: uploaded, processing, error
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),  -- Upload timestamp
    
    -- Relationship constraint with cascade delete
    FOREIGN KEY (submission_id) REFERENCES flexible_form_submissions(id) ON DELETE CASCADE
);

-- Index
CREATE INDEX idx_flexible_form_attachments_submission_id ON flexible_form_attachments(submission_id);
```

## Database Relationships

The database design follows these relationships:

1. **One-to-Many**: A `form_submission` can have multiple `file_attachments`
2. **One-to-Many**: A `form_template` can have multiple `flexible_form_submissions`
3. **One-to-Many**: A `flexible_form_submission` can have multiple `flexible_form_attachments`

## Data Flow

### Form Submission Process

When a form is submitted, the data flows through the system as follows:

1. **Form Data Received**
   - Data is validated against schema (fixed or dynamic)
   - A new record is created in `form_submissions` or `flexible_form_submissions`
   - A submission ID is generated and returned to the client

2. **File Upload Process**
   - Files are uploaded to the API with the submission ID
   - Files are stored either locally or in Azure Blob Storage
   - File metadata is stored in `file_attachments` or `flexible_form_attachments`
   - The file records are linked to the submission via `submission_id`

3. **Retrieval Process**
   - When retrieving a submission, the API joins the tables to return the complete data
   - File URLs are constructed for client access

## Database Design Considerations

### UUID Primary Keys

All tables use UUID strings as primary keys instead of auto-incrementing integers for:
- Security (non-guessable IDs)
- Scalability across distributed systems
- Universality across environments

### JSON/JSONB Fields

The database uses JSONB fields for:
- **form_metadata**: Additional form submission data
- **schema**: Dynamic form structure
- **validation_rules**: Custom validation logic
- **data**: Flexible form submission values

This allows for dynamic data structures while maintaining relational integrity.

### Cascade Deletes

File attachments use CASCADE DELETE constraints to ensure when a submission is deleted, all associated files are also removed from the database (though actual file cleanup may be handled separately).

### Indexing Strategy

Indexes are created on:
- Foreign key relationships (`submission_id`, `template_id`)
- Frequently queried fields (`form_type`, `email`)
- Sort fields (`created_at`)
- Filter fields (`is_processed`, `is_active`)

This optimizes common query patterns while balancing write performance.

## Querying Common Scenarios

### Find All Submissions for a Form Template

```sql
SELECT 
    ffs.id, ffs.data, ffs.created_at, ffs.is_processed,
    ft.name AS form_name
FROM 
    flexible_form_submissions ffs
JOIN 
    form_templates ft ON ffs.template_id = ft.id
WHERE 
    ft.id = 'template_id_here'
ORDER BY 
    ffs.created_at DESC;
```

### Get Submission with All Files

```sql
-- For standard forms
SELECT 
    fs.*, 
    json_agg(fa.*) AS attachments
FROM 
    form_submissions fs
LEFT JOIN 
    file_attachments fa ON fs.id = fa.submission_id
WHERE 
    fs.id = 'submission_id_here'
GROUP BY 
    fs.id;

-- For flexible forms
SELECT 
    ffs.*, 
    ft.name AS template_name,
    json_agg(ffa.*) AS attachments
FROM 
    flexible_form_submissions ffs
JOIN 
    form_templates ft ON ffs.template_id = ft.id
LEFT JOIN 
    flexible_form_attachments ffa ON ffs.id = ffa.submission_id
WHERE 
    ffs.id = 'submission_id_here'
GROUP BY 
    ffs.id, ft.name;
```

### Find Unprocessed Submissions

```sql
SELECT 
    id, data, created_at
FROM 
    flexible_form_submissions
WHERE 
    is_processed = false
ORDER BY 
    created_at ASC;
```

### Count Submissions by Type

```sql
SELECT 
    form_type, 
    COUNT(*) as submission_count
FROM 
    form_submissions
GROUP BY 
    form_type
ORDER BY 
    submission_count DESC;
```

## Database Migrations

The HSQ Forms API uses Alembic for database migrations. Key migration files:

1. `2ac5845444f5_initial_migration_with_formsubmission_.py` - Initial schema
2. `3e7f1234abcd_add_file_attachments_table.py` - File attachment support
3. `4a8b9c0d1e2f_add_flexible_forms_tables.py` - Dynamic form templates
4. `942781d0226f_add_performance_indexes.py` - Performance optimization

## Storage Considerations

### Form Data Storage

Form data is stored directly in PostgreSQL:
- Standard forms have fixed columns
- Flexible forms use JSONB for dynamic fields

### File Storage

Only file metadata is stored in PostgreSQL. Actual file content is stored:

1. **Local Storage**:
   - Location: `uploads/{submission_id}/{filename}`
   - Used primarily in development

2. **Azure Blob Storage**:
   - Container: `form-uploads`
   - Blob path: `{submission_id}/{uuid-filename}`
   - Used in production

The database stores the reference to the storage location, allowing the API to retrieve files when needed.

## Performance and Scaling

### Query Optimization

For larger installations, consider:

1. Adding composite indexes for common query patterns
2. Using materialized views for reporting queries
3. Implementing database partitioning by date for large submission tables

### Connection Pooling

The API uses SQLAlchemy's connection pooling to efficiently manage database connections.

## Backup and Maintenance

The database should be backed up regularly:

1. **Scheduled PostgreSQL Dumps**:
   ```bash
   pg_dump -U postgres -d hsq_forms -f hsq_forms_backup.sql
   ```

2. **Maintenance Tasks**:
   - Regular VACUUM ANALYZE to optimize performance
   - Periodic cleanup of old submissions based on retention policy

## Security Considerations

The database implements several security measures:

1. **No Direct Public Access**: 
   - Database is only accessible through the API
   - No direct public network exposure

2. **Data Sanitization**:
   - All user input is validated before storage
   - SQL injection protection via parameterized queries

3. **Sensitive Data Handling**:
   - IP addresses are stored for audit purposes
   - Consider encryption for sensitive fields if required

## Conclusion

This documentation provides a comprehensive overview of the database structure used in the HSQ Forms API. Understanding this schema is crucial for:

- Building custom integrations
- Creating reports and analytics
- Troubleshooting data issues
- Planning for scaling and performance optimization

For more details on the API endpoints that interact with this database, refer to the API documentation.
