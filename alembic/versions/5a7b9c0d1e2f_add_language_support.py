"""add language support

Revision ID: 5a7b9c0d1e2f
Revises: 942781d0226f
Create Date: 2025-06-06 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '5a7b9c0d1e2f'
down_revision = '942781d0226f'
branch_labels = None
depends_on = None


def upgrade():
    # Add language support columns to form_templates table
    op.add_column('form_templates', sa.Column('default_language', sa.String(5), nullable=False, server_default='en'))
    op.add_column('form_templates', sa.Column('available_languages', postgresql.JSON(astext_type=sa.Text()), nullable=False, server_default='["en"]'))
    op.add_column('form_templates', sa.Column('translations', postgresql.JSON(astext_type=sa.Text()), nullable=False, server_default='{}'))


def downgrade():
    # Remove language support columns
    op.drop_column('form_templates', 'translations')
    op.drop_column('form_templates', 'available_languages')
    op.drop_column('form_templates', 'default_language')
