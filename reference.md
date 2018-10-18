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