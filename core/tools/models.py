from __future__ import annotations

from pydantic import BaseModel


class ToolSpec(BaseModel):
    """Definition of a tool that AI providers can invoke."""

    name: str
    description: str
    parameters: dict  # JSON Schema for the tool's input parameters


class ToolResult(BaseModel):
    """Result produced by executing a tool."""

    tool_name: str
    output: str
    success: bool
