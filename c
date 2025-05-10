# main.py

import os
import openai
from openai.error import RateLimitError
from db import db_get, db_set
from tools import calculator, time_now

# Configure your API key
openai.api_key = os.environ["OPENAI_API_KEY"]

def ask_agent(prompt: str) -> str:
    """Send the user prompt to the LLM with caching and handle rate limits."""
    cache_key = f"cache:{prompt}"
    # 1. Check cache
    cached = db_get(cache_key)
    if cached:
        return cached

    # 2. Call the API with budget settings
    try:
        resp = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.6,
            max_tokens=100
        )
        reply = resp.choices[0].message.content.strip()
        # 3. Store in cache
        db_set(cache_key, reply)
        return reply
    except RateLimitError:
        # 4. Signal quota hit
        return None

def main():
    # Greet or ask for name
    name = db_get("user:name")
    if not name:
        name = input("👋 Hello! What is your name? ")
        db_set("user:name", name)
        print(f"Nice to meet you, {name}! How can I help today?")
    else:
        print(f"Welcome back, {name}! What can I do for you today?")

    # Chat loop with tool‐fallbacks
    while True:
        prompt = input("You: ")
        if prompt.lower() in ("exit", "quit"):
            print("Goodbye!")
            break

        reply = ask_agent(prompt)
        if reply is None:
            # Fallback to tools
            if prompt.lower().startswith("calc "):
                expr = prompt[5:]
                reply = calculator(expr)
            elif "time" in prompt.lower():
                reply = time_now("")
            else:
                reply = ("I’m sorry, I’ve hit my API limit. "
                         "Try ‘calc <expression>’ for math or ask for the current time.")
        print("Agent:", reply)

if __name__ == "__main__":
    main()
