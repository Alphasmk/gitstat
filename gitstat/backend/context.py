from contextvars import ContextVar
from typing import Optional

request_token: ContextVar[Optional[str]] = ContextVar('request_token', default=None)