from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from pathlib import Path

from core.calendar.models import CalendarEvent

SCOPES = ["https://www.googleapis.com/auth/calendar"]

TOKEN_FILE = Path.home() / ".zyzz" / "google_token.json"

# Credentials file is searched in these locations, in order
_CREDENTIALS_CANDIDATES = [
    Path.home() / ".zyzz" / "credentials.json",
    Path("credentials.json"),
]


class CalendarService:
    """Provides read and write access to the user's primary Google Calendar."""

    def __init__(self) -> None:
        self._service: object | None = None

    def list_events(self, max_results: int = 10, days_ahead: int = 7) -> list[CalendarEvent]:
        """Return upcoming events from now until days_ahead days from now."""
        service = self._get_service()
        now = datetime.now(timezone.utc)
        result = (
            service.events()
            .list(
                calendarId="primary",
                timeMin=now.isoformat(),
                timeMax=(now + timedelta(days=days_ahead)).isoformat(),
                maxResults=max_results,
                singleEvents=True,
                orderBy="startTime",
            )
            .execute()
        )
        return [_parse_event(e) for e in result.get("items", [])]

    def create_event(
        self,
        title: str,
        start: str,
        end: str,
        description: str = "",
        location: str = "",
    ) -> CalendarEvent:
        """Create a new event on the primary calendar and return the created event."""
        service = self._get_service()
        body = {
            "summary": title,
            "description": description,
            "location": location,
            "start": {"dateTime": start, "timeZone": "UTC"},
            "end": {"dateTime": end, "timeZone": "UTC"},
        }
        created = service.events().insert(calendarId="primary", body=body).execute()
        return _parse_event(created)

    def get_daily_agenda(self, date_str: str | None = None) -> list[CalendarEvent]:
        """Return all events for the given date (YYYY-MM-DD), defaulting to today."""
        target = date.fromisoformat(date_str) if date_str else date.today()
        day_start = datetime(target.year, target.month, target.day, tzinfo=timezone.utc)
        day_end = day_start + timedelta(days=1)
        service = self._get_service()
        result = (
            service.events()
            .list(
                calendarId="primary",
                timeMin=day_start.isoformat(),
                timeMax=day_end.isoformat(),
                singleEvents=True,
                orderBy="startTime",
            )
            .execute()
        )
        return [_parse_event(e) for e in result.get("items", [])]

    def _get_service(self) -> object:
        """Return a cached Google Calendar service, rebuilding only when credentials expire."""
        if self._service is not None:
            return self._service
        self._service = self._build_service()
        return self._service

    def _build_service(self) -> object:
        """Authenticate via OAuth2 and return a ready-to-use Google Calendar service."""
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build

        TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)

        creds: Credentials | None = None
        if TOKEN_FILE.exists():
            creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                credentials_path = next(
                    (p for p in _CREDENTIALS_CANDIDATES if p.exists()), None
                )
                if credentials_path is None:
                    raise FileNotFoundError(
                        "Google Calendar credentials.json not found. "
                        "Download it from the Google Cloud Console (OAuth 2.0 client for a Desktop app) "
                        f"and place it at: {_CREDENTIALS_CANDIDATES[0]}"
                    )
                flow = InstalledAppFlow.from_client_secrets_file(str(credentials_path), SCOPES)
                creds = flow.run_local_server(port=0)
            TOKEN_FILE.write_text(creds.to_json(), encoding="utf-8")

        return build("calendar", "v3", credentials=creds)


def _parse_event(raw: dict) -> CalendarEvent:
    """Convert a raw Google Calendar API event dict into a CalendarEvent model."""
    start = raw.get("start", {})
    end = raw.get("end", {})
    return CalendarEvent(
        id=raw.get("id"),
        title=raw.get("summary", "(sem título)"),
        start=start.get("dateTime") or start.get("date", ""),
        end=end.get("dateTime") or end.get("date", ""),
        description=raw.get("description", ""),
        location=raw.get("location", ""),
    )
