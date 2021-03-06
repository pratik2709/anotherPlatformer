--__lua__
function _init()
  t=0
  numberOfTicks=0
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
  numberOfTicks += 1
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
    update_shooter()
  elseif globals.level == 3 then
    updateBossBattle()
    updatebosslives()
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
   battleDraw()
 end
 player1:drawlives()
 draw_debug()
end

function draw_debug()
 -- do something
 -- if boss1 ~= nil then
   print(boss1.lives,ship.x,(ship.y-20),11)
 -- end


 -- if ship.isfaceright and self.isfaceright then
 --   print("YRE",ship.x,(ship.y-20),11)
 -- end
 -- for bullet in all(bossbullet) do
    -- print(ship.imm,ship.x,(ship.y-20),11)
 -- end
  -- printh(tprint(shooterShipBulletPool.bulletPool,0))

end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end
