#!/bin/python
#

import openai
import sys

arg1 = sys.argv[1]

openai.api_key = "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"

model_engine = "gpt-3.5-turbo"

response = openai.ChatCompletion.create(
    model='gpt-3.5-turbo',
    messages=[
        {"role": "user", "content": arg1},
    ])

message = response.choices[0]['message']
print("{}".format(message['content']))
