"""add_flexible_forms_tables

Revision ID: 4a8b9c0d1e2f
Revises: 3e7f1234abcd
Create Date: 2025-06-03 10:30:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '4a8b9c0d1e2f'
down_revision = '3e7f1234abcd'
branch_labels = None
depends_on = None


def upgrade():
    # Create form_templates table
    op.create_table('form_templates',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('project_id', sa.String(length=50), nullable=False),
        sa.Column('schema', sa.JSON(), nullable=False),
        sa.Column('validation_rules', sa.JSON(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_by', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create flexible_form_submissions table
    op.create_table('flexible_form_submissions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('template_id', sa.String(), nullable=False),
        sa.Column('data', sa.JSON(), nullable=False),
        sa.Column('submitted_by', sa.String(length=100), nullable=True),
        sa.Column('submitted_from_ip', sa.String(length=45), nullable=True),
        sa.Column('submitted_from_project', sa.String(length=50), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('is_processed', sa.Boolean(), nullable=False),
        sa.Column('processing_notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['template_id'], ['form_templates.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create flexible_form_attachments table
    op.create_table('flexible_form_attachments',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('submission_id', sa.String(), nullable=False),
        sa.Column('field_name', sa.String(length=100), nullable=False),
        sa.Column('original_filename', sa.String(length=255), nullable=False),
        sa.Column('stored_filename', sa.String(length=255), nullable=False),
        sa.Column('file_size', sa.Integer(), nullable=False),
        sa.Column('content_type', sa.String(length=100), nullable=False),
        sa.Column('blob_url', sa.String(length=500), nullable=True),
        sa.Column('upload_status', sa.String(length=20), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['submission_id'], ['flexible_form_submissions.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create indexes for better performance
    op.create_index('idx_form_templates_project_id', 'form_templates', ['project_id'])
    op.create_index('idx_form_templates_is_active', 'form_templates', ['is_active'])
    op.create_index('idx_form_templates_created_at', 'form_templates', ['created_at'])
    
    op.create_index('idx_flexible_form_submissions_template_id', 'flexible_form_submissions', ['template_id'])
    op.create_index('idx_flexible_form_submissions_created_at', 'flexible_form_submissions', ['created_at'])
    op.create_index('idx_flexible_form_submissions_is_processed', 'flexible_form_submissions', ['is_processed'])
    op.create_index('idx_flexible_form_submissions_project', 'flexible_form_submissions', ['submitted_from_project'])
    
    op.create_index('idx_flexible_form_attachments_submission_id', 'flexible_form_attachments', ['submission_id'])
    op.create_index('idx_flexible_form_attachments_field_name', 'flexible_form_attachments', ['field_name'])


def downgrade():
    # Drop indexes
    op.drop_index('idx_flexible_form_attachments_field_name', table_name='flexible_form_attachments')
    op.drop_index('idx_flexible_form_attachments_submission_id', table_name='flexible_form_attachments')
    op.drop_index('idx_flexible_form_submissions_project', table_name='flexible_form_submissions')
    op.drop_index('idx_flexible_form_submissions_is_processed', table_name='flexible_form_submissions')
    op.drop_index('idx_flexible_form_submissions_created_at', table_name='flexible_form_submissions')
    op.drop_index('idx_flexible_form_submissions_template_id', table_name='flexible_form_submissions')
    op.drop_index('idx_form_templates_created_at', table_name='form_templates')
    op.drop_index('idx_form_templates_is_active', table_name='form_templates')
    op.drop_index('idx_form_templates_project_id', table_name='form_templates')
    
    # Drop tables
    op.drop_table('flexible_form_attachments')
    op.drop_table('flexible_form_submissions')
    op.drop_table('form_templates')
