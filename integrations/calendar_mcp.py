from fastmcp import FastMCP

from calendar_service import get_upcoming_events


mcp = FastMCP("Anchor Calendar")


@mcp.tool
def list_calendar_events(
    max_results: int = 20,
) -> list[dict]:
    """
    Fetch upcoming events from the user's Google Calendar.

    Args:
        max_results: Maximum number of events to return.

    Returns:
        A list of calendar events with useful event information.
    """

    events = get_upcoming_events(max_results=max_results)

    result = []

    for event in events:
        start = event.get("start", {})
        end = event.get("end", {})

        attendees = [
            attendee.get("email")
            for attendee in event.get("attendees", [])
            if attendee.get("email")
        ]

        result.append(
            {
                "source": "calendar",
                "external_id": event.get("id"),
                "title": event.get("summary", ""),
                "description": event.get("description", ""),
                "start_time": start.get("dateTime") or start.get("date"),
                "end_time": end.get("dateTime") or end.get("date"),
                "location": event.get("location", ""),
                "status": event.get("status", ""),
                "attendees": attendees,
                "organizer": event.get("organizer", {}).get("email", ""),
            }
        )

    return result


if __name__ == "__main__":
    mcp.run()