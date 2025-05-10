# main.py

import os
from openai import OpenAI            # <— new import
from db import db_get, db_set

# 1. Instantiate the new OpenAI client
client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

def ask_agent(prompt: str) -> str:
    """Send the user prompt to the LLM and return its reply."""
    resp = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
    )
    # .choices[0].message.content still holds the text
    return resp.choices[0].message.content.strip()

def main():
    # Greet or ask for name
    name = db_get("user:name")
    if not name:
        name = input("👋 Hello! What is your name? ")
        db_set("user:name", name)
        print(f"Nice to meet you, {name}! How can I help today?")
    else:
        print(f"Welcome back, {name}! What can I do for you today?")

    # Chat loop
    while True:
        user_input = input("You: ")
        if user_input.lower() in ("exit", "quit"):
            print("Goodbye!")
            break
        reply = ask_agent(user_input)
        print("Agent:", reply)

if __name__ == "__main__":
    main()
