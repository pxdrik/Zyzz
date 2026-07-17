from enum import Enum

from pydantic import BaseModel


class Provider(str, Enum):
    CHATGPT = "ChatGPT"
    CLAUDE = "Claude"
    GEMINI = "Gemini"


class RouteDecision(BaseModel):
    provider: Provider
    reason: str
