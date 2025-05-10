# tools.py
import datetime

def calculator(expr: str) -> str:
    """
    Evaluate a mathematical expression and return the result as a string.
    Returns an error message if the expression is invalid.
    """
    try:
        # WARNING: eval can be unsafe for untrusted input
        return str(eval(expr))
    except Exception:
        return "Error: invalid expression."

def time_now(_: str) -> str:
    """
    Return the current date and time as a formatted string.
    """
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
