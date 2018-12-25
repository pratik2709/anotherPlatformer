--__lua__
function _init()
  t=0
  splashscreentimer = 0
  player_lives = 5
  mapwidth = 128
  mapheight = 64
  mycam = cam:new(mapwidth, mapheight)
  player1 = player:new(10,0)
  initialize_shooter()
  boss1 = boss:new(0, 0)
end


function _update()
  if globals.level == 1 then
    player1:move()
    player1:update()
    checkwallcollision(player1)
    spawn_baddies(player1:getx())
  	for i,actor in pairs(baddies) do
  		actor:move()
  		checkwallcollisionenemy(actor)
  		player1:actorenemycollision(actor)
  	end
  elseif globals.level == 2 then
    update_stars()
    update_shooter()
  elseif globals.level == 3 then
    update_stars()
    update_shooter()
  end
  updateplayerlives()
end


function _draw()
 cls()
 if globals.level==1 then
   initial_splash_screen()
   mycam:followplayer(player1:getx(), player1.y)
   player1:draw()
   map(0,0,0,0,128,128)
   for i, actor in pairs(baddies) do
 		actor:draw()
 	 end
 elseif globals.level==2 then
   map(0,0,0,0,128,128)
   draw_shooter()
 elseif globals.level==3 then
   map(0,0,0,0,128,128)
   draw_shooter()
 end
 player1:drawlives()
 draw_debug()
end

function draw_debug()
 -- do something
 -- print(globals.enemies,ship:x,(ship.y-mapheight)-10,11)
 print(globals.enemies,ship.x,(ship.y-10),11)
 print(globals.level,ship.x,(ship.y-20),11)

end
