"""Authenticated client for submitting selected Google signals to Anchor."""

import os
from typing import Any

import requests


SIGNALS_API_URL = os.environ.get(
    "ANCHOR_SIGNALS_API_URL",
    "https://anchor-qo9j.onrender.com/signals",
)


def post_signal(signal: dict[str, Any], access_token: str | None = None) -> dict[str, Any]:
    """Submit one already-filtered signal using a Supabase user access token."""

    token = access_token or os.environ.get("ANCHOR_API_TOKEN")
    if not token:
        raise RuntimeError(
            "Set ANCHOR_API_TOKEN to the signed-in user's Supabase access token before syncing signals."
        )

    response = requests.post(
        SIGNALS_API_URL,
        json=signal,
        headers={"Authorization": f"Bearer {token}"},
        timeout=10,
    )
    response.raise_for_status()
    return response.json()
