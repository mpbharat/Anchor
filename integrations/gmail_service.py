from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
import re

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

from signal_client import post_signal


SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]

BASE_DIR = Path(__file__).resolve().parent
CREDENTIALS_FILE = BASE_DIR / "credentials.json"
TOKEN_FILE = BASE_DIR / "token_gmail.json"

# These labels and terms protect privacy by keeping non-load-related mail out of Anchor.
EXCLUDED_LABELS = {"SPAM", "TRASH", "CATEGORY_PROMOTIONS", "CATEGORY_SOCIAL", "CATEGORY_FORUMS"}
PURCHASE_TERMS = (
    "receipt", "order", "invoice", "payment", "paid", "purchase", "booking confirmation",
    "subscription", "renewal", "transaction", "bill",
)
ASK_TERMS = (
    "action required", "action needed", "please review", "please respond", "request",
    "deadline", "due", "invitation", "invite", "rsvp", "meeting", "interview",
    "follow up", "follow-up", "approval needed",
)
NOISE_TERMS = ("newsletter", "digest", "unsubscribe", "weekly roundup", "daily roundup")


def get_gmail_service():
    """Authenticate with Google and return a Gmail API service."""

    credentials = None
    if TOKEN_FILE.exists():
        credentials = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    if not credentials or not credentials.valid:
        flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
        credentials = flow.run_local_server(port=0)
        TOKEN_FILE.write_text(credentials.to_json())

    return build("gmail", "v1", credentials=credentials)


def _headers(email: dict) -> dict[str, str]:
    return {
        header["name"].lower(): header["value"]
        for header in email.get("payload", {}).get("headers", [])
    }


def classify_email(email: dict) -> str | None:
    """Return the only Gmail signal kinds Anchor tracks, or None for private noise."""

    if EXCLUDED_LABELS.intersection(email.get("labelIds", [])):
        return None

    subject = _headers(email).get("subject", "").lower()
    if any(term in subject for term in NOISE_TERMS):
        return None
    if any(term in subject for term in PURCHASE_TERMS):
        return "purchase"
    if any(term in subject for term in ASK_TERMS):
        return "ask"
    return None


def get_relevant_emails(max_results: int = 10, days_back: int = 30) -> list[dict]:
    """Fetch only recent purchases and actionable asks; never return the inbox wholesale."""

    if max_results < 1:
        return []
    if days_back < 1:
        raise ValueError("days_back must be at least 1")

    service = get_gmail_service()
    # Gmail applies this query before message metadata is fetched. The local classifier
    # below is deliberately stricter, so promotions and ordinary correspondence stay local.
    results = service.users().messages().list(
        userId="me",
        q=f"newer_than:{days_back}d -in:spam -in:trash",
        maxResults=min(max_results * 5, 500),
    ).execute()

    emails = []
    for message in results.get("messages", []):
        email = service.users().messages().get(
            userId="me",
            id=message["id"],
            format="metadata",
            metadataHeaders=["From", "To", "Subject", "Date"],
        ).execute()
        if classify_email(email):
            emails.append(email)
        if len(emails) == max_results:
            break
    return emails


def get_recent_emails(max_results: int = 10) -> list[dict]:
    """Backward-compatible name for the filtered email reader."""

    return get_relevant_emails(max_results=max_results)


def print_emails(emails: list[dict]) -> None:
    """Print the metadata of the selected emails, not bodies or attachments."""

    print(f"\nFound {len(emails)} relevant emails:\n")
    for email in emails:
        headers = _headers(email)
        print("-" * 70)
        print(f"ID:      {email.get('id')}")
        print(f"From:    {headers.get('from', '')}")
        print(f"Subject: {headers.get('subject', '')}")
        print(f"Kind:    {classify_email(email)}")
        print(f"Date:    {headers.get('date', '')}")


def get_email_details(email: dict) -> dict:
    """Convert a pre-filtered Gmail message into the minimum useful metadata."""

    headers = _headers(email)
    return {
        "source": "gmail",
        "external_id": email.get("id"),
        "thread_id": email.get("threadId"),
        "from": headers.get("from", ""),
        "to": headers.get("to", ""),
        "subject": headers.get("subject", ""),
        "date": headers.get("date", ""),
        "kind": classify_email(email),
    }


def _occurred_at(email: dict) -> str:
    """Convert an RFC 2822 Gmail Date header to the API's RFC 3339 requirement."""

    date = _headers(email).get("date")
    if date:
        try:
            parsed = parsedate_to_datetime(date)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        except (TypeError, ValueError, IndexError):
            pass
    return datetime.fromtimestamp(
        int(email.get("internalDate", "0")) / 1000, timezone.utc
    ).isoformat().replace("+00:00", "Z")


def _merchant(from_header: str) -> str:
    return re.sub(r"\s*<[^>]+>", "", from_header).strip()[:200]


def email_to_signal(email: dict) -> dict | None:
    """Build a backend payload, or None when the email is not relevant."""

    kind = classify_email(email)
    if not kind:
        return None

    headers = _headers(email)
    return {
        "source": "gmail",
        "kind": kind,
        "title": headers.get("subject", "")[:500],
        "merchant": _merchant(headers.get("from", "")) if kind == "purchase" else None,
        "category": "email_purchase" if kind == "purchase" else "email_ask",
        "occurred_at": _occurred_at(email),
    }


def sync_relevant_emails(max_results: int = 10, days_back: int = 30) -> list[dict]:
    """Post only classified Gmail signals to the authenticated backend endpoint."""

    signals = (email_to_signal(email) for email in get_relevant_emails(max_results, days_back))
    return [post_signal(signal) for signal in signals if signal]


if __name__ == "__main__":
    emails = get_relevant_emails(max_results=10)
    print_emails(emails)
