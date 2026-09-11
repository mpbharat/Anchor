from fastmcp import FastMCP

from gmail_service import get_recent_emails, get_email_details


mcp = FastMCP("Anchor Gmail")


@mcp.tool
def search_emails(max_results: int = 10) -> list[dict]:
    """
    Fetch recent emails from the user's Gmail account.

    Args:
        max_results: Maximum number of recent emails to return.

    Returns:
        A list of simplified Gmail messages.
    """

    emails = get_recent_emails(max_results=max_results)

    return [
        get_email_details(email)
        for email in emails
    ]


if __name__ == "__main__":
    mcp.run()