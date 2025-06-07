# HSQ Forms API - Utility Modules

This directory contains utility modules that provide helper functions used across the application.

## Available Modules

### `__init__.py`
Basic utility functions that are imported directly from the `utils` package.

### `validation.py`
Functions for validating data like email addresses, phone numbers, form inputs, etc.

### `file_helpers.py`
Functions for file operations like saving uploaded files, checking file sizes, validating file types, etc.

### `date_helpers.py`
Functions for date and time manipulation, parsing dates from strings, formatting dates, etc.

### `string_helpers.py`
Functions for string manipulation, like case conversion, random string generation, etc.

### `logging_config.py`
Configuration for application logging, including different handlers and formatters.

## Usage

Import these utility functions as needed:

```python
from src.forms_api.utils import filter_none_values
from src.forms_api.utils.validation import validate_email
from src.forms_api.utils.file_helpers import save_uploaded_file
from src.forms_api.utils.date_helpers import format_date, get_current_datetime
from src.forms_api.utils.string_helpers import camel_to_snake, generate_random_string
from src.forms_api.utils.logging_config import get_logger
```
