"""
Date and time utilities for HSQ Forms API.

This module contains helper functions for date and time operations.
"""

import datetime
from typing import Optional, Union

from dateutil import parser
from dateutil.relativedelta import relativedelta


def parse_date(date_str: str) -> Optional[datetime.date]:
    """
    Parse a date string into a date object.
    
    Args:
        date_str: The date string to parse
        
    Returns:
        datetime.date: The parsed date or None if parsing fails
    """
    try:
        parsed_date = parser.parse(date_str).date()
        return parsed_date
    except (ValueError, TypeError):
        return None


def parse_datetime(datetime_str: str) -> Optional[datetime.datetime]:
    """
    Parse a datetime string into a datetime object.
    
    Args:
        datetime_str: The datetime string to parse
        
    Returns:
        datetime.datetime: The parsed datetime or None if parsing fails
    """
    try:
        parsed_datetime = parser.parse(datetime_str)
        return parsed_datetime
    except (ValueError, TypeError):
        return None


def format_date(
    date_obj: Union[datetime.date, datetime.datetime], 
    format_str: str = "%Y-%m-%d"
) -> str:
    """
    Format a date object as a string.
    
    Args:
        date_obj: The date or datetime object to format
        format_str: The format string (default: "%Y-%m-%d")
        
    Returns:
        str: The formatted date string
    """
    return date_obj.strftime(format_str)


def format_datetime(
    datetime_obj: datetime.datetime, 
    format_str: str = "%Y-%m-%d %H:%M:%S"
) -> str:
    """
    Format a datetime object as a string.
    
    Args:
        datetime_obj: The datetime object to format
        format_str: The format string (default: "%Y-%m-%d %H:%M:%S")
        
    Returns:
        str: The formatted datetime string
    """
    return datetime_obj.strftime(format_str)


def get_current_datetime() -> datetime.datetime:
    """
    Get the current datetime.
    
    Returns:
        datetime.datetime: The current datetime
    """
    return datetime.datetime.now()


def get_current_date() -> datetime.date:
    """
    Get the current date.
    
    Returns:
        datetime.date: The current date
    """
    return datetime.date.today()


def add_days(
    date_obj: Union[datetime.date, datetime.datetime], 
    days: int
) -> Union[datetime.date, datetime.datetime]:
    """
    Add days to a date or datetime.
    
    Args:
        date_obj: The date or datetime object
        days: Number of days to add
        
    Returns:
        Union[datetime.date, datetime.datetime]: The resulting date or datetime
    """
    return date_obj + datetime.timedelta(days=days)


def date_diff_in_days(
    date1: Union[datetime.date, datetime.datetime], 
    date2: Union[datetime.date, datetime.datetime]
) -> int:
    """
    Calculate the difference in days between two dates.
    
    Args:
        date1: The first date
        date2: The second date
        
    Returns:
        int: The difference in days (date1 - date2)
    """
    # Convert to date if datetime
    if isinstance(date1, datetime.datetime):
        date1 = date1.date()
    if isinstance(date2, datetime.datetime):
        date2 = date2.date()
    
    return (date1 - date2).days
