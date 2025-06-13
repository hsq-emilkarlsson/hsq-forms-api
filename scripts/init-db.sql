#!/bin/bash
set -e

# Initialize database for production deployment
# This script runs when the PostgreSQL container starts for the first time

echo "Creating hsqforms user and database..."

# Create user if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hsqforms') THEN
            CREATE USER hsqforms WITH PASSWORD '$POSTGRES_PASSWORD';
        END IF;
    END
    \$\$;
    
    -- Grant necessary privileges
    GRANT ALL PRIVILEGES ON DATABASE hsqforms TO hsqforms;
    GRANT ALL ON SCHEMA public TO hsqforms;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO hsqforms;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hsqforms;
    
    -- Set default privileges for future objects
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO hsqforms;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO hsqforms;
    
    -- Create extensions if needed
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOSQL

echo "Database initialization completed successfully!"
