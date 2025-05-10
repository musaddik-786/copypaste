import os
import openai
from openai.error import RateLimitError
from db import db_get, db_set
from tools import calculator, time_now

# Set your OpenAI API key from Secrets
openai.api_key = os.environ["OPENAI_API_KEY"]

def ask_agent(prompt: str) -> str:
    """Ask the OpenAI agent with caching and error handling."""
    cache_key = f"cache:{prompt}"
    
    # 1. Return cached reply if it exists
    cached = db_get(cache_key)
    if cached:
        return cached

    # 2. Try calling OpenAI
    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.6,
            max_tokens=100
        )
        reply = response.choices[0].message.content.strip()
        db_set(cache_key, reply)
        return reply
    except RateLimitError:
        return None

def main():
    # Ask for or recall user's name
    name = db_get("user:name")
    if not name:
        name = input("👋 Hello! What is your name? ")
        db_set("user:name", name)
        print(f"Nice to meet you, {name}! How can I help today?")
    else:
        print(f"Welcome back, {name}! What can I do for you today?")

    # Loop for conversation
    while True:
        user_input = input("You: ")
        if user_input.lower() in ("exit", "quit"):
            print("Agent: Goodbye!")
            break

        reply = ask_agent(user_input)

        # If OpenAI quota hit or error
        if reply is None:
            if user_input.lower().startswith("calc "):
                expr = user_input[5:]
                reply = calculator(expr)
            elif "time" in user_input.lower():
                reply = time_now("")
            else:
                reply = ("Sorry, my AI brain is out of quota. "
                         "You can still try ‘calc 2+2’ or ask for the time.")

        print("Agent:", reply)

if __name__ == "__main__":
    main()
