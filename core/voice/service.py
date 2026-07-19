from __future__ import annotations

import os
import sys


class VoiceService:
    """Handles speech-to-text transcription and text-to-speech playback."""

    def transcribe(self, audio_path: str) -> str:
        """Transcribe an audio file to text using OpenAI Whisper API.

        Returns the transcribed text, or an empty string if transcription fails.
        """
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            print("VoiceService: OPENAI_API_KEY not set — transcription unavailable.", file=sys.stderr)
            return ""
        try:
            from openai import OpenAI

            client = OpenAI(api_key=api_key)
            with open(audio_path, "rb") as f:
                result = client.audio.transcriptions.create(model="whisper-1", file=f)
            return result.text.strip()
        except Exception as exc:
            print(f"VoiceService.transcribe error: {exc}", file=sys.stderr)
            return ""

    def speak(self, text: str) -> None:
        """Convert text to speech using the system TTS engine.

        Runs synchronously — call from a background thread.
        """
        try:
            import pyttsx3

            engine = pyttsx3.init()
            engine.say(text)
            engine.runAndWait()
            engine.stop()
        except Exception as exc:
            print(f"VoiceService.speak error: {exc}", file=sys.stderr)
