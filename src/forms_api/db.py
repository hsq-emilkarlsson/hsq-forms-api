"""
Database connection and session management.
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from src.forms_api.config import settings

# Skapa SQLAlchemy engine
engine = create_engine(settings.database_url)

# Skapa sessionmaker
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Bas för SQLAlchemy modeller
Base = declarative_base()

# Dependency för att få databasession
def get_db():
    """
    Dependency för att få en databasession som automatiskt stängs när den är klar.
    För användning med FastAPI dependency injection.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialisera databasen och skapa tabeller"""
    # Import models so they are registered with the Base
    from src.forms_api import models
    
    Base.metadata.create_all(bind=engine)
