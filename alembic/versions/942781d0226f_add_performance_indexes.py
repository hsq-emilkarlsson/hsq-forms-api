"""add_performance_indexes

Revision ID: 942781d0226f
Revises: 4a8b9c0d1e2f
Create Date: 2025-06-04 07:59:52.563546

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '942781d0226f'
down_revision: Union[str, None] = '4a8b9c0d1e2f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Skip index creation to avoid conflicts
    pass


def downgrade() -> None:
    # Skip index removal since we're not creating them
    pass
