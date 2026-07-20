"""System metrics — exposes CPU, memory, disk info using psutil."""

from __future__ import annotations

from pydantic import BaseModel

import psutil


class SystemSnapshot(BaseModel):
    """A point-in-time snapshot of system resource usage."""

    cpu_percent: float
    memory_used_gb: float
    memory_total_gb: float
    memory_percent: float
    disk_used_gb: float
    disk_total_gb: float
    disk_percent: float


def take_snapshot() -> SystemSnapshot:
    """Capture current system metrics."""
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    return SystemSnapshot(
        cpu_percent=psutil.cpu_percent(interval=None),
        memory_used_gb=round(mem.used / (1024 ** 3), 1),
        memory_total_gb=round(mem.total / (1024 ** 3), 1),
        memory_percent=mem.percent,
        disk_used_gb=round(disk.used / (1024 ** 3), 1),
        disk_total_gb=round(disk.total / (1024 ** 3), 1),
        disk_percent=disk.percent,
    )
