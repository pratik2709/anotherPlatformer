pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
globals = {
 gravity = 0.2,
 dt = 0.5
}
player = {}
cam = {}
function draw_debug()
 -- do something
 -- print(player1.hanging,player1:getx(),(player1.y-mapheight)-10,11)
end

function cam:new(mapwidth, mapheight)
 local o = {}
 setmetatable(o,self)
 self.__index=self
 o.x = 0
 o.mapwidth=mapwidth
 o.y = 0
 o.mapheight=mapheight
 return o
end

function cam:followplayer(playerx, playery)
--https://gamedev.stackexchange.com/questions/44256/how-to-add-a-scrolling-camera-to-a-2d-java-game
--https://stackoverflow.com/questions/9997006/slick2d-and-jbox2d-how-to-draw?answertab=votes#tab-top
--offsetmaxx = world_size_x - viewport_size_x
--offsetminx = 0
-- no idea why subtract from world width
 self.x=playerx-self.mapwidth
 self.y=playery-(self.mapheight)
 -- these sonditions are so that camera doesnt go out
 --of bounds. 16 is length of map u are currently viewing
 --in the viewport
 -- leftmost bound for x
 if self.x<0 then
  self.x=0
 end

 if self.y<0 then
  self.y=0
 end

--right-most bound for x
 if self.x>(self.mapwidth-16)*16 then
   self.x = (self.mapwidth-16)*16
 end

 if self.y>(self.mapheight+19) then
  --19 is the lowest point
   self.y = self.mapheight+19
 end

 camera(self.x,self.y)
end

function cam:getx()
 return self.x
end

function cam:reset()
 camera()
end

function _init()
 mapwidth = 100
 mapheight = 16
 mycam = cam:new(mapwidth, mapheight)
 player1 = player:new(32,72)
end

function _update()
 player1:move()
 player1:update()
 checkwallcollision(player1)

end

function _draw()
 -- draw code
 cls()
 mycam:followplayer(player1:getx(), player1.y)
 player1:draw()

 --draw in layers
 map(0,0,0,0,128,128)
 draw_debug()

end

function iswall(tile)
  if(tile==1) then
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
          if not collide(actor, j, -1, true) then
            if collide(actor,j,0, true) then
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
  if collide(actor,0,1) and not actor.hanging then
    actor.standing=true
    actor.falltimer=0
  else
    actor.falltimer+=1
  end

  -- actor.sliding = false
  -- if collide(actor,1,0) then
  --   local tile=mget(actor.x/8+1, actor.y/8)
  --   if(iswall(tile)) then
  --     actor.sliding=true
  --     -- actor.slidedir=-1
  --     if(actor.dy>0) actor.dy*=0.97
  --   end
  -- elseif collide(actor,-1,0) then
  --   local tile=mget(actor.x/8-1,actor.y/8)
  --   if(iswall(tile)) then
  --     actor.sliding=true
  --     -- actor.slidedir=-1
  --     if(actor.dy>0) actor.dy*=0.97
  --   end
  -- end

  actor.dx*=.98

end

function player:new(x, y)
 local o={}
 setmetatable(o,self)
 self.__index = self
 o.x =x
 o.y = y
 o.dx = 0
 o.dy = 0
 o.w=6
 o.h=6

 o.isgrounded = false
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
 o.invtimer = false

 return o
end

function collide(agent,vx,vy,toponly)
	local x1,x2,y1,y2

	-- we'll test two points:
  --  P--.--P (depending on the vs sign?)
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


		-- check two corners
    if toponly then
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



--  if player.sliding then
--   -- walljump
--   --todo: no idea
--   self.dy-=3
--   self.dy=mid(self.dy,-1,-3)
--   self.dx=self.slidedir*2
--   -- self.flipx=(self.slidedir==-1)
-- end


end

function player:draw()
 -- draw only non flash frame
 if self.flash == false then
  --draw the sprite either left or right
  if not self.isgrounded then
   if self.isfacingright then
    spr(0,self.x, self.y, 1, 1, false)
   else
    spr(0,self.x, self.y, 1, 1, true)
   end
  elseif self.dx>=0 then
   if self.isfacingright then
    spr(0,self.x, self.y, 1, 1, false)
   else
    spr(0,self.x, self.y, 1, 1, true)
   end
  else
    spr(0,self.x, self.y, 1, 1, true)
  end
 end

end

function player:collide(actor)
 if actorcollide(self, actor)
  and not self.invuln then
  self.lives-=1
  self.invuln=true
  self.invtimer=100
 end
end

function player:update()
 self.invtimer=-1
 if self.invtimer <= 0 then
  self.invuln = false
 end
end

--collision related
function intersect(min1, max1, min2, max2)
 return max(min1, max1) > min(min2, max2) and
        min(min1, max1) < max(min2,max2)
end

function actorcollide(actor1, actor2)
 return intersect(actor1.x, actor1.x+8,
  actor2.x, actor2.x+8) and
 intersect(actor1.y, actor1.y+8,
  actor2.y, actor2.y+8)
end

-- object, starting frame, number of frames,
-- animation speed, flip
function anim(actor, start_frame, number_of_frames,
 anim_speed, flipper)
 if(not actor.current_tile) actor.current_tile = 0
 if(not actor.starting_tile) actor.starting_tile = 0
 actor.current_tile+=1
 if(actor.current_tile%(30/anim_speed)==0) then
  actor.starting_tile+=1
  if(actor.starting_tile==number_of_frames) then
   actor.starting_tile = 0
  end
 end
 actor.frame = start_frame + actor.
 spr(actor.frame,actor.x,actor.y,1,1,flipper)

end


__gfx__
00000000888888880000000099999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000009bbbbbb9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070088888888000000009bbbbbb9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700088888888000000009bb88bb9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700088888888000000009bb88bb9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070088888888000000009bbbbbb9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000009bbbbbb9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888880000000099999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777070707770077077707770000007707770077007707070000077707770000000000000000000000000000000000000000000000000000000000000
07000000700070707070707070700700000070007070707070007070000070707070000000000000000000000000000000000000000000000000000000000000
00700000770007007770707077000700000077707770707070007700000077707770000000000000000000000000000000000000000000000000000000000000
07000000700070707000707070700700000000707000707070007070000070007070000000000000000000000000000000000000000000000000000000000000
70000000777070707000770070700700000077007000770007707070070070007770000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606060666006606660666066606660600066600000666006606660666066606660066000000000000000000000000000000000000000000000000000000000
60006060606060606060060060606060600060000000600060606060666060600600600006000000000000000000000000000000000000000000000000000000
66000600666060606600060066606600600066000000660060606600606066600600666000000000000000000000000000000000000000000000000000000000
60006060600060606060060060606060600060000000600060606060606060600600006006000000000000000000000000000000000000000000000000000000
66606060600066006060060060606660666066600000600066006060606060600600660000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666066000660000000000660666066606660666066600660606066606660666000000000000000000000000000000000000000000000000000000000
00000000606060606000000000006000606060600600060060006000606060006000060000000000000000000000000000000000000000000000000000000000
00000000666060606000000000006660666066000600060066006660666066006600060000000000000000000000000000000000000000000000000000000000
00000000600060606060000000000060600060600600060060000060606060006000060000000000000000000000000000000000000000000000000000000000
00000600600060606660000000006600600060606660060066606600606066606660060000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000606066606060000000000660666060600000006000006660606006606660066000000000000000000000000000000000000000000000000000000000
00000000606060606060000000006000600060600000060000006660606060000600600000000000000000000000000000000000000000000000000000000000
00000000606066606060000000006660660006000000060000006060606066600600600000000000000000000000000000000000000000000000000000000000
00000000666060606660000000000060600060600000060000006060606000600600600000000000000000000000000000000000000000000000000000000000
00000600666060600600000000006600600060600000600000006060066066006660066000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000606066606660600000006060666066600000666060006660606066606660000000000000000000000000000000000000000000000000000000000000
00000000606006006660600000006060600060600000606060006060606060006060000000000000000000000000000000000000000000000000000000000000
00000000666006006060600000006060660066000000666060006660666066006600000000000000000000000000000000000000000000000000000000000000
00000000606006006060600000006660600060600000600060006060006060006060000000000000000000000000000000000000000000000000000000000000
00000600606006006060666000006660666066600000600066606060666066606060000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666066606600000000006600666066606660606066600000666060006660606066606660000000000000000000000000000000000000000000000000
00000000606006006060000000006060606006000600606060000000606060006060606060006060000000000000000000000000000000000000000000000000
00000000660006006060000000006060666006000600606066000000666060006660666066006600000000000000000000000000000000000000000000000000
00000000606006006060000000006060606006000600666060000000600060006060006060006060000000000000000000000000000000000000000000000000
00000600666066606060000000006060606006006660060066600000600066606060666066606060000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777070707770077077707770000007707770077007707070000077707700077000000000000000000000000000000000000000000000000000000000
07000000700070707070707070700700000070007070707070007070000070707070700000000000000000000000000000000000000000000000000000000000
00700000770007007770707077000700000077707770707070007700000077707070700000000000000000000000000000000000000000000000000000000000
07000000700070707000707070700700000000707000707070007070000070007070707000000000000000000000000000000000000000000000000000000000
70000000777070707000770070700700000077007000770007707070070070007070777000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606060666006606660666066606600000006606660666066606660666006606060666066606660000000000000000000000000000000000000000000000000
60006060606060606060060060006060000060006060606006000600600060006060600060000600000000000000000000000000000000000000000000000000
66000600666060606600060066006060000066606660660006000600660066606660660066000600000000000000000000000000000000000000000000000000
60006060600060606060060060006060000000606000606006000600600000606060600060000600000000000000000000000000000000000000000000000000
66606060600066006060060066606660000066006000606066600600666066006060666066600600000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777007707000770077707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000700070707000707070007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000770070707000707077007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000700070707000707070007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000700077007770777077707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000077077707070777000000700077070007770777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000700070707070700000007070700070000700707000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000777077707070770000007070700070000700777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000007070707770700000007000700070000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000770070700700777000000770077077707770700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90909990999099009990990009900000000090009990999099909000000099900990000099909000999099009090000000000000000000000000000000000000
90909090909090900900909090000900000090009090909090009000000009009000000090909000909090909090000000000000000000000000000000000000
90909990990090900900909090000000000090009990990099009000000009009990000099009000999090909900000000000000000000000000000000000000
99909090909090900900909090900900000090009090909090009000000009000090000090909000909090909090000000000000000000000000000000000000
99909090909090909990909099900000000099909090999099909990000099909900000099909990909090909090000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaa0a0a0aa0000000aa0aaa0aaa0aaa00000aaa0aa00aa000000a0a00aa0aaa00000aaa0aaa00000aaa00aa000000aa0aaa0aaa0aaa0a0a0aaa0aaa000000000
a0a0a0a0a0a00000a000a0a0a0a00a000000a0a0a0a0a0a00000a0a0a000a0000000a00000a000000a00a0a00000a000a0a0a0a00a00a0a0a0a0a00000000000
aa00a0a0a0a00000a000aaa0aa000a000000aaa0a0a0a0a00000a0a0aaa0aa000000aa0000a000000a00a0a00000a000aaa0aaa00a00a0a0aa00aa0000000000
a0a0a0a0a0a00000a000a0a0a0a00a000000a0a0a0a0a0a00000a0a000a0a0000000a00000a000000a00a0a00000a000a0a0a0000a00a0a0a0a0a00000000000
a0a00aa0a0a000000aa0a0a0a0a00a000000a0a0a0a0aaa000000aa0aa00aaa00000a00000a000000a00aa0000000aa0a0a0a0000a000aa0a0a0aaa000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606660606066606600000066600660000006606000666066606660066066606660660000000000000000000000000000000000000000000000000000000000
60006060606060006060000006006060000060006000060060606060606060606060606000000000000000000000000000000000000000000000000000000000
66606660606066006060000006006060000060006000060066606600606066606600606000000000000000000000000000000000000000000000000000000000
00606060666060006060000006006060000060006000060060006060606060606060606000000000000000000000000000000000000000000000000000000000
66006060060066606660000006006600000006606660666060006660660060606060666000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000077077707070777000000700077070007770777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000700070707070700000007070700070000700707000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000777077707070770000007070700070000700777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000007070707770700000007000700070000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000770070700700777000000770077077707770700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606660606066606600000066600660000006606000666066606660066066606660660000000000000000000000000000000000000000000000000000000000
60006060606060006060000006006060000060006000060060606060606060606060606000000000000000000000000000000000000000000000000000000000
66606660606066006060000006006060000060006000060066606600606066606600606000000000000000000000000000000000000000000000000000000000
00606060666060006060000006006060000060006000060060006060606060606060606000000000000000000000000000000000000000000000000000000000
66006060060066606660000006006600000006606660666060006660660060606060666000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000077077707070777000000700077070007770777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000700070707070700000007070700070000700707000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000777077707070770000007070700070000700777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000007070707770700000007000700070000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000770070700700777000000770077077707770700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606660606066606600000066600660000006606000666066606660066066606660660000000000000000000000000000000000000000000000000000000000
60006060606060006060000006006060000060006000060060606060606060606060606000000000000000000000000000000000000000000000000000000000
66606660606066006060000006006060000060006000060066606600606066606600606000000000000000000000000000000000000000000000000000000000
00606060666060006060000006006060000060006000060060006060606060606060606000000000000000000000000000000000000000000000000000000000
66006060060066606660000006006600000006606660666060006660660060606060666000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000030000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000010000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000020202010201000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000020202020202010101010000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020202020202020202020000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000202030202020202020000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000010101010100000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000010101010100000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000010101010100000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020202020201010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
