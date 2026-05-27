import os
from langchain.agents import create_agent
from langchain.tools import tool
from pydantic import BaseModel, Field

from dotenv import load_dotenv
load_dotenv()


class ContactInfo(BaseModel):
    """Contact information for a person."""
    name: str = Field(description="The name of the person")
    email: str = Field(description="The email address of the person")
    phone: str = Field(description="The phone number of the person")


@tool
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b


agent = create_agent(
    model="openrouter:qwen/qwen-plus",
    system_prompt="You are a helpful assistant",
    tools=[add],
    # response_format=ContactInfo
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "What is 2 + 2?"}]
})

print(result["messages"][-1].content)