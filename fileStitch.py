#!/usr/bin/python
import os


items = os.listdir("src/")
f = open("game.p8", "w")

header= open("src/headers.p8", 'r')
f.write(header.read())

header.close()


for item in items:
    if(item != "headers.p8" and item != "gfx.p8"):
        f.write("\n\n -- **************" + item + "****************\n\n")
        ff = open("src/" + item, "r")
        f.write(ff.read())
        ff.close()

f.write("\n\n -- **************" + "gfx.p8" + "****************\n\n")
footer= open("src/gfx.p8", 'r')
f.write(footer.read())
f.close()