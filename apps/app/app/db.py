import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Ladda miljövariabler
load_dotenv()

# Hämta databasanslutning från miljövariabel
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://formuser:formpassword@localhost:5432/formdb")

# Skapa SQLAlchemy engine
engine = create_engine(DATABASE_URL)

# Skapa sessionmaker
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Bas för SQLAlchemy modeller
Base = declarative_base()

# Dependency för att få databasession
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialisera databasen och skapa tabeller"""
    from app import models
    Base.metadata.create_all(bind=engine)