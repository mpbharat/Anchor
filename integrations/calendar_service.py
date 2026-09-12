from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from datetime import datetime, timezone

from signal_client import post_signal



# Read-only access to calendar events.
SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly"
]

BASE_DIR = Path(__file__).resolve().parent

CREDENTIALS_FILE = BASE_DIR / "credentials.json"
TOKEN_FILE = BASE_DIR / "token_calendar.json"


def get_calendar_service():
    """Authenticate with Google and return a Calendar API service."""

    credentials = None

    # Reuse previously generated token if available.
    if TOKEN_FILE.exists():
        credentials = Credentials.from_authorized_user_file(
            TOKEN_FILE,
            SCOPES
        )

    # Refresh expired token when possible.
    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    # Start OAuth flow if there is no valid token.
    if not credentials or not credentials.valid:

        flow = InstalledAppFlow.from_client_secrets_file(
            CREDENTIALS_FILE,
            SCOPES
        )

        credentials = flow.run_local_server(port=0)

        TOKEN_FILE.write_text(credentials.to_json())

    return build(
        "calendar",
        "v3",
        credentials=credentials
    )



def get_upcoming_events_future(max_results=20):
    """Fetch upcoming events from the user's primary calendar."""

    service = get_calendar_service()

    now = datetime.now(timezone.utc).isoformat()

    events_result = service.events().list(
        calendarId="primary",
        timeMin=now,
        maxResults=max_results,
        singleEvents=True,
        orderBy="startTime"
    ).execute()

    return events_result.get("items", [])

from datetime import datetime, timedelta, timezone


def get_upcoming_events(max_results=20):
    """Fetch upcoming regular calendar events that can affect the user's load."""

    service = get_calendar_service()

    now = datetime.now(timezone.utc)
    time_max = now + timedelta(days=30)

    events_result = service.events().list(
        calendarId="primary",
        timeMin=now.isoformat(),
        timeMax=time_max.isoformat(),
        maxResults=max_results,
        eventTypes="default",
        showDeleted=False,
        showHiddenInvitations=False,
        singleEvents=True,
        orderBy="startTime"
    ).execute()

    return events_result.get("items", [])


def is_relevant_event(event: dict) -> bool:
    """Keep actual upcoming commitments, excluding cancelled or declined invitations."""

    if event.get("status") == "cancelled":
        return False
    return not any(
        attendee.get("self") and attendee.get("responseStatus") == "declined"
        for attendee in event.get("attendees", [])
    )


def get_relevant_upcoming_events(max_results: int = 20) -> list[dict]:
    return [event for event in get_upcoming_events(max_results) if is_relevant_event(event)]


def event_to_signal(event: dict) -> dict | None:
    """Convert a relevant calendar event into the small load-signal API shape."""

    if not is_relevant_event(event):
        return None
    start = event.get("start", {})
    occurred_at = start.get("dateTime")
    if not occurred_at and start.get("date"):
        occurred_at = f"{start['date']}T00:00:00Z"
    if not occurred_at:
        return None
    return {
        "source": "calendar",
        "kind": "event",
        "title": event.get("summary", "Calendar event")[:500],
        "category": "calendar_event",
        "occurred_at": occurred_at,
    }


def sync_relevant_events(max_results: int = 20) -> list[dict]:
    """Post only confirmed/tentative regular events to the backend."""

    signals = (event_to_signal(event) for event in get_relevant_upcoming_events(max_results))
    return [post_signal(signal) for signal in signals if signal]


def print_events_min(events):
    """Print calendar events in a simple readable format."""

    print(f"\nFound {len(events)} upcoming events:\n")

    for event in events:

        start = event.get("start", {})

        start_time = (
            start.get("dateTime")
            or start.get("date")
        )

        print("-" * 60)

        print(f"ID:       {event.get('id')}")
        print(f"Title:    {event.get('summary', '(No title)')}")
        print(f"Start:    {start_time}")
        print(f"Location: {event.get('location', '')}")

def print_events(events):
    """Print detailed calendar event information."""

    print(f"\nFound {len(events)} upcoming events:\n")

    for event in events:

        start = event.get("start", {})
        end = event.get("end", {})

        start_time = (
            start.get("dateTime")
            or start.get("date")
        )

        end_time = (
            end.get("dateTime")
            or end.get("date")
        )

        attendees = [
            attendee.get("email")
            for attendee in event.get("attendees", [])
            if attendee.get("email")
        ]

        print("-" * 70)

        print(f"ID:          {event.get('id')}")
        print(f"Title:       {event.get('summary', '(No title)')}")
        print(f"Description: {event.get('description', '')}")
        print(f"Start:       {start_time}")
        print(f"End:         {end_time}")
        print(f"Location:    {event.get('location', '')}")
        print(f"Organizer:   {event.get('organizer', {}).get('email', '')}")
        print(f"Status:      {event.get('status', '')}")
        print(f"Attendees:   {attendees}")
        print(f"Created:     {event.get('created', '')}")
        print(f"Updated:     {event.get('updated', '')}")


if __name__ == "__main__":

    events = get_upcoming_events(max_results=10)

    print_events(events)
