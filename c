# main.py

import os
import openai
from db import db_get, db_set

# 1. Configure OpenAI
openai.api_key = os.environ["OPENAI_API_KEY"]

def ask_agent(prompt: str) -> str:
    """Send the user prompt to the LLM and return its reply."""
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content.strip()

def main():
    # 2. Greet or ask for name
    name = db_get("user:name")
    if not name:
        name = input("👋 Hello! What is your name? ")
        db_set("user:name", name)
        print(f"Nice to meet you, {name}! How can I help today?")
    else:
        print(f"Welcome back, {name}! What can I do for you today?")

    # 3. Chat loop
    while True:
        user_input = input("You: ")
        if user_input.lower() in ("exit", "quit"):
            print("Goodbye!")
            break
        reply = ask_agent(user_input)
        print("Agent:", reply)

if __name__ == "__main__":
    main()
