> “In main.py, replace the existing test code with a chat assistant that:

1. Imports os, openai, db_get, and db_set.


2. Reads OPENAI_API_KEY from os.environ and sets openai.api_key.


3. Defines ask_agent(prompt: str) -> str which sends the prompt to gpt-3.5-turbo and returns the reply.


4. In main():

Checks db_get("user:name").

If there’s no name, prompts “What is your name?”, stores it with db_set("user:name", name), and says “Nice to meet you, {name}! How can I help today?”.

Otherwise, greets the user by name: “Welcome back, {name}! What can I do for you?”.

Enters a loop: reads input("You: "), breaks on “exit”/“quit”, calls ask_agent, and prints “Agent: {reply}”.



5. Calls main() under the if __name__ == "__main__": guard.

  
  
