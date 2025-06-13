"""rename_form_template_title_to_name

Revision ID: 6f4d0c206cd5
Revises: 5a7b9c0d1e2f
Create Date: 2025-06-07 20:47:02.901671

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6f4d0c206cd5'
down_revision: Union[str, None] = '5a7b9c0d1e2f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Rename title column to name in form_templates table
    op.alter_column('form_templates', 'title', new_column_name='name')


def downgrade() -> None:
    # Rename name column back to title in form_templates table
    op.alter_column('form_templates', 'name', new_column_name='title')
