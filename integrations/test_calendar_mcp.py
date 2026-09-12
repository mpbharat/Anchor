import asyncio
from pathlib import Path

from fastmcp import Client


async def main():
    """Test the Anchor Calendar MCP server."""

    server_path = Path(__file__).parent / "calendar_mcp.py"

    async with Client(server_path) as client:

        print("✅ Connected to Calendar MCP server")

        # Discover available tools
        tools = await client.list_tools()

        print("\nAvailable MCP tools:")

        for tool in tools:
            print(f"- {tool.name}")

        # Call our Calendar tool
        result = await client.call_tool(
            "list_calendar_events",
            {
                "max_results": 20
            }
        )

        print("\nCalendar events:")
        print("=" * 70)

        print(result)


if __name__ == "__main__":
    asyncio.run(main())