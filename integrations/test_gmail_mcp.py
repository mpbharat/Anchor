import asyncio
from pathlib import Path

from fastmcp import Client


async def main():
    """Test the Anchor Gmail MCP server."""

    server_path = Path(__file__).parent / "gmail_mcp.py"

    async with Client(server_path) as client:

        print("✅ Connected to Gmail MCP server")

        tools = await client.list_tools()

        print("\nAvailable MCP tools:")

        for tool in tools:
            print(f"- {tool.name}")

        result = await client.call_tool(
            "search_relevant_emails",
            {
                "max_results": 10
            }
        )

        print("\nRecent emails:")
        print("=" * 70)

        print(result)


if __name__ == "__main__":
    asyncio.run(main())
