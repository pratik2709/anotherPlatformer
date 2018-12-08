function updateplayerlives()
  if player_lives <= 0 then
    game_over()
  end
end

function initial_splash_screen()
  splashscreentimer += 1
  if splashscreentimer < 100 then
    print("Starting soon \n Get Ready!",
       player1:getx() + 20, player1.y,4)
   end
end


function iswall(tile)
  if(tile==1 or tile==3 or tile==7) then
    return true
  end
end


--collision code
function checkwallcollision(actor)
  actor.standing = false

  if actor.hanging then
    actor.dx=0
    actor.dy=0
  else
    actor.dy += globals.gravity

  end

  local steps = abs(actor.dx*globals.dt)
  for i=0,steps do
    local d=min(1,steps-i)

    --x axis collision
    if collide(actor, sgn(actor.dx)*d,0) then
      actor.dx=0
      break
    else
      actor.x+=sgn(actor.dx)*d
    end
  end

  --y axis collision
  steps=abs(actor.dy*globals.dt)
  for i=0,steps do
    local d=min(1,steps-i)
    if collide(actor,0,sgn(actor.dy)*d) then
       --halt velocity
      actor.dy=0
      break
    else
      actor.y+=sgn(actor.dy)*d

      --code for ledges
      if actor.dy > 0 and not hitjump then
        -- check left and right
        for j=-1,1,2 do
          if not collide(actor, j, -1, "toponly") then
            if collide(actor,j,0, "toponly") then
              actor.hanging=true
              -- actor.hangdir=j
              actor.dx=0
              actor.dy=0
            end
          end
        end
        if (actor.hanging) break
      end
    end
  end

  --standing on something code
  if(collide(actor,0,1,"level_change")) and not actor.hanging then
    globals.level = 2
  elseif collide(actor,0,1) and not actor.hanging then
    actor.standing=true
    actor.falltimer=0

  else
    actor.falltimer+=1
  end

  actor.dx*=.98

end

function player:drawlives()
	for i=1, player_lives do
		spr(0,mycam.x+(i*8),mycam.y)
	end
end

function player:new(x, y)
 local o={}
 setmetatable(o,self)
 self.__index = self
 o.x =x
 o.y = y
 o.dx = 0
 o.dy = 0
 o.w=4
 o.h=7

 o.standing=false
 o.hanging=false
 o.isfacingright = true
 o.jumppressed = false
 o.jumpvelocity = 4
 o.falltimer = 0
 o.landtimer = 0
 o.hurtimer = 0

 o.score = 0
 o.lives = 3

 o.bounce = false
 o.flash = false
 o.wall_climb = false

 o.bad = false
 o.invuln = false
 o.invtimer = 0

 return o
end

function collide(agent,vx,vy,collide_condition)
	local x1,x2,y1,y2

	-- we'll test two points:
  --  p--.--p (depending on the vs sign?)
  -- origin point + up-down or left right
  -- needs a proper diagram!
	if vx!=0 then
    --notice only the sign is being used here
    if sgn(vx) == -1 then
      --left corners
      x1=agent.x
      y1=agent.y
      x2=agent.x
      y2=agent.y+agent.h
    else
      -- right corners
      x1=agent.x + agent.w
      y1=agent.y
      x2=agent.x + agent.w
      y2=agent.y + agent.h
    end

	else
    if sgn(vy) == -1 then
      y1=agent.y
      x1=agent.x + agent.w
      y2=agent.y
      x2=agent.x
    else
      y1=agent.y+sgn(vy)*agent.h
      x1=agent.x + agent.w
      y2=agent.y+sgn(vy)*agent.h
      x2=agent.x
    end
	end

	-- add our potential movement
	-- to our test points
  -- todo: why we need potential movements?
	x1+=vx
	x2+=vx
	y1+=vy
	y2+=vy

	-- check for map-tile hits
	local tile1=mget(x1/8,y1/8)
	local tile2=mget(x2/8,y2/8)

  if collide_condition == "level_change" then
    if fget(tile1,1) or fget(tile2,1) then
      return true
    end
	-- check two corners
  elseif collide_condition == "toponly" then
    if iswall(tile1) then
	 		return true
	 	end
  else
    -- for standard collisions,
		if iswall(tile1) or iswall(tile2) then
	 		return true
	 	end
  end

 	-- no hits have been returned
	return false
end

function player:getx()
 return self.x
end

function player:gety()
 return self.y
end

function fire_player_bullet(isright)
  local dir = 3
  if not isright then
    dir = -3
  end
  local bullet = {
    sprite_number=6,
    x=player1.x,
    y=player1.y,
    w=8,
    h=8,
    dx=dir,
    dy=0,
    box={x1=2,y1=0,x2=5,y2=4}
  }
  add(player_bullets,bullet)
end


function player:move()
 --storing start and end locations
 self.startx = self.x
 self.starty = self.y

 local holdjump=btn(4)
 if holdjump and not oholdjump then
   hitjump=true
 else
   hitjump=false
 end
 oholdjump=holdjump

 if hitjump then
   if self.standing or self.falltimer < 7 then
     self.dy = min(self.dy, -4)

   elseif self.hanging then
     if not btn(3) then
       self.dy=-3
     else
       self.dy=1
     end
     self.hanging=false
   end

 end

 if self.standing then
   if btn(0) then
     self.isfacingright=false
     if self.dx>0 then
       self.dx*=0.8
     end
     self.dx-=0.5*globals.dt
   end
   if btn(1) then
     self.isfacingright=true
     if self.dx<0 then
       self.dx*=0.8
     end
     self.dx+=0.5*globals.dt
   end

   if not btn(0) and not btn(1) then
     self.dx*=.88
   end
 else
   if btn(0) then
     self.dx-=.85*globals.dt
   end
   if btn(1) then
     self.dx+=.85*globals.dt
   end
 end

 if btnp(5) then
   fire_player_bullet(self.isfacingright)
 end

end

function player:draw()
 -- draw only non flash frame
 -- flash means skip this draw frame
 if self.flash == false then
  --draw the sprite either left or right
  if not self.standing then
   if self.isfacingright then
    spr(033,self.x, self.y, 1, 1, false)
   else
    spr(033,self.x, self.y, 1, 1, true)
   end
  elseif self.dx==0 then
   if self.isfacingright then
    spr(033,self.x, self.y, 1, 1, false)
   else
    spr(033,self.x, self.y, 1, 1, true)
   end
  elseif self.dx>0 then
    anim(self,033,5,10,false)
  else
    anim(self,033,5,10,true)
  end
 end

 if self.invuln == true then
   if self.flash==true then
     self.flash = false
   else
     self.flash=true
   end
 else
   self.flash=false
 end

 for player_bullet in all(player_bullets) do
  spr(player_bullet.sprite_number,player_bullet.x,player_bullet.y)
 end

end

function player:actorenemycollision(actor)
 if actorcollide(self, actor) and not self.invuln then
  player_lives-=1
  self.invuln=true
  self.invtimer=100
 end
end

function player:update()
 self.invtimer-=1
 if self.invtimer <= 0 then
  self.invuln = false
 end

 for player_bullet in all(player_bullets) do
   player_bullet.x += player_bullet.dx
   player_bullet.y += player_bullet.dy
   if collide(player_bullet, sgn(player_bullet.dx),0) then
     del(player_bullets,player_bullets)
   end
   for baddie in all(baddies) do
     if shooter_collision(baddie, player_bullet) then
       del(baddies, baddie)
       -- explode(enemy.x, enemy.y)
     end
   end
 end
end




