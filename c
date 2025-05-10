Environment updated. Reloading shell...

Welcome back, Alice! What can I do for you today?

You: HI Traceback (most recent call last):

File "/home/runner/workspace/main.py", line 42, in <module> main()

File "/home/runner/workspace/main.py", line 37, in main reply ask_agent(user_input)

File "/home/runner/workspace/main.py", line 13, in ask agent response = openai.ChatCompletion.create(model="gpt-3.5-turbo",

File "/home/runner/workspace/.pythonlibs/lib/python3.11/site-packages/openai/lib/_old_api

py", line 39, in_call raise APIRemovedInV1(symbol=self._symbol)

openai.lib._old_api APIRemovedInV1:

You tried to access openai.ChatCompletion, but this is no longer supported in openai>-1.0.0 see the README at https://github.com/openai/openat-python for the API.

You can run openat migrate to automatically upgrade your codebase to use the 1.0.0 interf ace.

Alternatively, you can pin your installation to the old version, e.g. 'pip install openai 0.28

A detailed migration guide is available here: https://github.com/openai/openai-python/discu
