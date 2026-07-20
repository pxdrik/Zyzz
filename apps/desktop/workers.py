"""
QThread workers for background operations.

Extracted from main_window.py so they can be reused by the QML bridge
without depending on any UI framework.
"""

from __future__ import annotations

import sys

from PySide6.QtCore import QThread, Signal

from core.providers.providers import BaseProvider
from core.voice.service import VoiceService


class StreamWorker(QThread):
    """Runs a provider.stream() call in a background thread and emits each chunk."""

    chunk_received = Signal(str)
    error_occurred = Signal(str)

    def __init__(self, provider: BaseProvider, messages: list[dict]) -> None:
        super().__init__()
        self._provider = provider
        self._messages = messages

    def run(self) -> None:
        """Stream response chunks from the provider."""
        try:
            for chunk in self._provider.stream(self._messages):
                self.chunk_received.emit(chunk)
        except Exception as exc:
            print(f"StreamWorker error: {exc}", file=sys.stderr)
            self.error_occurred.emit(str(exc))


class ParallelWorker(QThread):
    """Runs all AI providers simultaneously and emits each result as it completes."""

    result_received = Signal(str, str)

    def __init__(self, prompt: str) -> None:
        super().__init__()
        self._prompt = prompt

    def run(self) -> None:
        """Dispatch the prompt to all providers in parallel via the Orchestrator."""
        from core.brain.orchestrator import Orchestrator

        orchestrator = Orchestrator()
        for provider_name, response in orchestrator.run_all_parallel(self._prompt):
            self.result_received.emit(provider_name, response)


class RecordWorker(QThread):
    """Records audio from the microphone and emits the path to the saved WAV file."""

    recording_stopped = Signal(str)

    SAMPLE_RATE = 16000

    def __init__(self) -> None:
        super().__init__()
        self._active = True

    def stop_recording(self) -> None:
        """Signal the worker to stop recording."""
        self._active = False

    def run(self) -> None:
        """Record microphone input until stop_recording() is called, then save to a temp WAV."""
        import tempfile

        import numpy as np
        import sounddevice as sd
        import soundfile as sf

        frames: list[np.ndarray] = []

        def callback(indata: np.ndarray, _frames: int, _time: object, _status: object) -> None:
            frames.append(indata.copy())

        try:
            with sd.InputStream(
                samplerate=self.SAMPLE_RATE, channels=1, dtype="float32", callback=callback
            ):
                while self._active:
                    self.msleep(100)
        except Exception as exc:
            print(f"RecordWorker error: {exc}", file=sys.stderr)
            return

        if not frames:
            return

        audio = np.concatenate(frames, axis=0)
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            sf.write(tmp.name, audio, self.SAMPLE_RATE)
            self.recording_stopped.emit(tmp.name)


class TranscribeWorker(QThread):
    """Transcribes an audio file using VoiceService in a background thread."""

    transcription_ready = Signal(str)

    def __init__(self, voice_service: VoiceService, audio_path: str) -> None:
        super().__init__()
        self._voice_service = voice_service
        self._audio_path = audio_path

    def run(self) -> None:
        """Send the audio file to Whisper and emit the resulting text."""
        text = self._voice_service.transcribe(self._audio_path)
        self.transcription_ready.emit(text)


class TtsWorker(QThread):
    """Speaks text using VoiceService in a background thread."""

    def __init__(self, voice_service: VoiceService, text: str) -> None:
        super().__init__()
        self._voice_service = voice_service
        self._text = text

    def run(self) -> None:
        """Speak the stored text via the system TTS engine."""
        self._voice_service.speak(self._text)
