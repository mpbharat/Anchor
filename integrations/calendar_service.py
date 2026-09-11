from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from datetime import datetime, timezone



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
    """Fetch upcoming events from the user's primary calendar."""

    service = get_calendar_service()

    now = datetime.now(timezone.utc)
    time_max = now + timedelta(days=30)

    events_result = service.events().list(
        calendarId="primary",
        timeMin=now.isoformat(),
        timeMax=time_max.isoformat(),
        maxResults=max_results,
        singleEvents=True,
        orderBy="startTime"
    ).execute()

    return events_result.get("items", [])


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