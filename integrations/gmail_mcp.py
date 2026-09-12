from fastmcp import FastMCP

from gmail_service import get_relevant_emails, get_email_details


mcp = FastMCP("Anchor Gmail")


@mcp.tool
def search_relevant_emails(max_results: int = 10, days_back: int = 30) -> list[dict]:
    """
    Fetch only relevant emails: purchases and actionable asks. Promotional,
    social, forum, spam, and ordinary correspondence are excluded locally.

    Args:
        max_results: Maximum number of relevant emails to return.
        days_back: Only consider messages received in this many days.

    Returns:
        A list of simplified Gmail messages.
    """

    emails = get_relevant_emails(max_results=max_results, days_back=days_back)

    return [
        get_email_details(email)
        for email in emails
    ]


if __name__ == "__main__":
    mcp.run()
