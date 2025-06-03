import os
import time
import logging
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from dotenv import load_dotenv
from .db import init_db
from .routers import submit, files

# Ladda miljövariabler
load_dotenv()

# Konfigurera logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# API-konfiguration
app = FastAPI(
    title="Husqvarna Forms API",
    description="Centraliserad API för alla formulär och frontend-applikationer",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS-middleware för att tillåta flera frontend-applikationer
origins = os.getenv(
    "ALLOWED_ORIGINS", 
    "http://localhost:5173,http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:3003"
).split(",")

# Lägg till dynamiska origins för utveckling
if os.getenv("ENVIRONMENT", "development") == "development":
    # Tillåt alla localhost-portar för utveckling
    origins.extend([
        "http://localhost:3000",
        "http://localhost:3001", 
        "http://localhost:3002",
        "http://localhost:3003",
        "http://localhost:5173",
        "http://localhost:5174",
        "http://localhost:8080"
    ])

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware för loggning
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    logger.info(
        f"Request: {request.method} {request.url.path} - "
        f"Status: {response.status_code} - Time: {process_time:.4f}s"
    )
    return response

# Hantera valideringsfel
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    errors = []
    for error in exc.errors():
        errors.append(f"{error.get('loc', [''])[1]}: {error.get('msg', '')}")
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"status": "error", "message": "Valideringsfel", "errors": errors},
    )

@app.on_event("startup")
async def startup():
    """Initialisera PostgreSQL-databas vid uppstart"""
    logger.info("Startar FormAPI och initierar PostgreSQL-databas")
    try:
        init_db()
        logger.info("PostgreSQL-databas initierad och tabeller skapade")
    except Exception as e:
        logger.error(f"Kunde inte initialisera databas: {str(e)}")

# Root-endpoint med API-info
@app.get("/")
def read_root():
    environment = os.getenv("ENVIRONMENT", "development")
    return {
        "message": "Välkommen till HSQ Forms API",
        "description": "Centraliserad API för formulärhantering och filuppladdningar",
        "environment": environment,
        "version": "1.0.0",
        "docs": "/docs",
        "api_endpoints": {
            "forms": {
                "submit": "POST /submit - Skicka in formulärdata",
                "list": "GET /submissions - Hämta tidigare inlämningar", 
                "get": "GET /submission/{id} - Hämta specifik inlämning",
                "update_status": "PUT /submission/{id}/status - Uppdatera bearbetningsstatus"
            },
            "future_endpoints": {
                "auth": "POST /auth/login - Användareautenticering (kommande)",
                "admin": "GET /admin/* - Administrationsendpoints (kommande)"
            },
            "files": {
                "upload": "POST /files/upload/{submission_id} - Ladda upp filer till formulär",
                "list": "GET /files/submission/{submission_id} - Hämta filer för formulär",
                "delete": "DELETE /files/{file_id} - Ta bort fil",
                "info": "GET /files/{file_id}/info - Hämta filinformation"
            }
        },
        "supported_form_types": [
            "contact",
            "newsletter", 
            "job_application",
            "support_ticket"
        ]
    }

# Lägg till endpoints från routers
app.include_router(submit.router)
app.include_router(files.router)