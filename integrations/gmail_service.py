from pathlib import Path
import requests


from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build


SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly"
]

BASE_DIR = Path(__file__).resolve().parent
CREDENTIALS_FILE = BASE_DIR / "credentials.json"
TOKEN_FILE = BASE_DIR / "token_gmail.json"

SIGNALS_API_URL = "http://localhost:3000/signals"


def get_gmail_service():
    """Authenticate with Google and return a Gmail API service."""

    credentials = None

    if TOKEN_FILE.exists():
        credentials = Credentials.from_authorized_user_file(
            TOKEN_FILE,
            SCOPES
        )

    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    if not credentials or not credentials.valid:
        flow = InstalledAppFlow.from_client_secrets_file(
            CREDENTIALS_FILE,
            SCOPES
        )

        credentials = flow.run_local_server(port=0)

        TOKEN_FILE.write_text(credentials.to_json())

    return build(
        "gmail",
        "v1",
        credentials=credentials
    )

def get_recent_emails(max_results=10):
    """Fetch recent emails from the user's Gmail account."""

    service = get_gmail_service()

    results = service.users().messages().list(
        userId="me",
        maxResults=max_results
    ).execute()

    messages = results.get("messages", [])

    emails = []

    for message in messages:
        email = service.users().messages().get(
            userId="me",
            id=message["id"],
            format="metadata",
            metadataHeaders=[
                "From",
                "To",
                "Subject",
                "Date"
            ]
        ).execute()

        emails.append(email)

    return emails

def print_emails(emails):
    """Print basic information about fetched emails."""

    print(f"\nFound {len(emails)} emails:\n")

    for email in emails:
        headers = {
            header["name"]: header["value"]
            for header in email.get("payload", {}).get("headers", [])
        }

        print("-" * 70)
        print(f"ID:      {email.get('id')}")
        print(f"From:    {headers.get('From', '')}")
        print(f"To:      {headers.get('To', '')}")
        print(f"Subject: {headers.get('Subject', '')}")
        print(f"Date:    {headers.get('Date', '')}")

def get_email_details(email):
    """Convert a Gmail API message into a simple dictionary."""

    headers = {
        header["name"]: header["value"]
        for header in email.get("payload", {}).get("headers", [])
    }

    return {
        "source": "gmail",
        "external_id": email.get("id"),
        "thread_id": email.get("threadId"),
        "from": headers.get("From", ""),
        "to": headers.get("To", ""),
        "subject": headers.get("Subject", ""),
        "date": headers.get("Date", ""),
    }

def email_to_signal(email: dict):
    return {
        "source": "gmail",
        "kind": "ask",
        "title": email.get("subject", ""),
        "occurred_at": email.get("date"),
    }

def post_signal(signal: dict):
    """Send an extracted signal to the Express backend."""

    response = requests.post(
        SIGNALS_API_URL,
        json=signal,
        timeout=10,
    )

    response.raise_for_status()

    return response.json()


if __name__ == "__main__":
    emails = get_recent_emails(max_results=10)
    print_emails(emails)



#     {
#   source: 'calendar' | 'gmail',
#   kind: 'event' | 'ask' | 'purchase',
#   title?: string,
#   merchant?: string,
#   amount?: number,
#   category?: string,
#   occurred_at?: string
# }