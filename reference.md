cmd + r : for reloading current file in pico8

map: draw maps

https://tutorialedge.net/gamedev/aabb-collision-detection-tutorial/

class player {
  public int x = 5;
  public int y = 5;
  public int width = 50;
  public int height = 50;
}

If we had 2 instantiated player objects then we could perform AABB collision detection using the following:

if(player1.x < player2.x + player2.width &&
    player1.x + player1.width > player2.x &&
    player1.y < player2.y + player2.height &&
    player1.y + player1.height > player2.y)
{
    System.out.println("Collision Detected");
}

Mget(cellx, celly): sprite number of a cell on the map

fget(spritenumber, flag_index): set flags for a particular sprite(total 8)

flr(): floor of a number

sgn( [number] )
Returns the sign of a number, 1 for positive, -1 for negative

spr( n, x, y, [w,] [h,] [flip_x,] [flip_y] )
Draw sprite

https://www.lexaloffle.com/bbs/?tid=3115
Animation function

btnp() implements a keyboard-like repeat mechanism: if the player holds the button for 15 frames, it registers as on again for one frame, then again every four frames after that. The frame counter resets when the player releases the button.
http://pico-8.wikia.com/wiki/Btnp

sspr()
Sprite sheet treated as a 128x128 image, uses pixel locations


map( celx, cely, sx, sy, celw, celh, [layer] )
draws the map

rnd( max )
Generates a random number between 0 and the given maximum.

pset( x, y, [c] )
Sets a pixel in the graphics buffer.
[c]
The color value. If not specified, uses the current color of the draw state.

http://pico-8.wikia.com/wiki/Rnd

run pico8:
/Applications/PICO-8.app/Contents/MacOS/pico8 ~/projects/test-platformer/player.p8
