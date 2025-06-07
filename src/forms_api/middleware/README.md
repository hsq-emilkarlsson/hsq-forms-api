# HSQ Forms API - Middleware Components

This directory contains middleware components that can be applied to the FastAPI application. Middleware functions run before and/or after route handlers and can modify requests and responses.

## Available Middleware

### `LoggingMiddleware`
Logs incoming requests and outgoing responses with timing information.

### `CORSMiddleware`
Handles Cross-Origin Resource Sharing (CORS) to enable secure cross-origin requests.

### `RequestValidationMiddleware`
Additional validation for incoming requests beyond Pydantic's automatic validation.

### `AuthenticationMiddleware`
Handles authentication via API keys or tokens, validating credentials before allowing access to protected routes.

### `RateLimitingMiddleware`
Implements rate limiting to protect the API from abuse or overuse.

## Usage

Middleware is configured in the `create_app` function in `app.py`:

```python
from src.forms_api.middleware import setup_middlewares

def create_app() -> FastAPI:
    app = FastAPI(...)
    
    # Configure middleware
    setup_middlewares(app)
    
    return app
```

## Creating New Middleware

To create a new middleware, add a new class that extends `BaseHTTPMiddleware` to this package, then update the `setup_middlewares` function in `__init__.py` to include it:

```python
class ExampleMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Pre-processing code here
        
        response = await call_next(request)
        
        # Post-processing code here
        
        return response
```
