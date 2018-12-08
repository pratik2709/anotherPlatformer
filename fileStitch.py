#!/usr/bin/python
import os


items = os.listdir("src/")
f = open("bigfile.p8", "w")

header= open("src/headers.p8", 'r')
f.write(header.read())

header.close()

# for item in items:
#     f.write(item.read())

f.close()