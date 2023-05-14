#!/bin/python
#

import openai
import sys

arg1 = sys.argv[1]
openai.api_key = "YOUR_KEY"
model_engine = "gpt-3.5-turbo"

response = openai.ChatCompletion.create(
    model='model_engine,
    messages=[
        {"role": "user", "content": arg1},
    ])

message = response.choices[0]['message']
print("{}".format(message['content']))
