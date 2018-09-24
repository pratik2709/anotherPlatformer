globals = {
 gravity = 0.2
}
player = {}

function draw_debug()
 -- do something
  print(player1:getx(),0,40,11)
  print(player1:gety(),0,45,11)
end

function _init()
 player1 = player:new(32,72)
end

function _update()
 player1:move()

end

function _draw()
 -- draw code
 cls()
 player1:draw()
 draw_debug()

end

function player:new(x, y)
 local o={}
 setmetatable(o,self)
 self.__index = self
 o.x =x
 o.y = y
 o.dx = 0
 o.dy = 0

 o.isgrounded = false
 o.isfacingright = true
 o.jumppressed = false
 o.jumpvelocity = 2
 o.jumptimer = 0

 o.score = 0
 o.lives = 3

 o.bounce = false
 o.flash = false

 o.bad = false
 o.invuln = false
 o.invtimer = false

 return o
end

function player:getx()
 return self.x
end

function player:gety()
 return self.y
end

function updatelocation(actor)
 -- do something
 actor.x += actor.dx

 -- actor.dy += globals.gravity

 --fall
 actor.y += actor.dy

end

function player:moveleft()
 self.isfacingright = false
 self.dx = -2
end

function player:moveright()
 self.isfacingright = true
 self.dx = 2
end

function player:jump()
 self.dy=-self.jumpvelocity
 self.jumptimer+=1
end

function player:extendjump()
 self.dy=-self.jumpvelocity
 self.jumptimer+=1
end

function player:move()
 --storing start and end locations
 self.startx = self.x
 self.starty = self.y

 --jump code
 if btn(4) and self.isgrounded 
 and self.jumptimer == 0 then
  self:jump()
  self.jumppressed = true
 elseif btn(4)
 and self.jumptimer<10
 and self.jumppressed
 and self.dy < 0 then
  -- elseif code
  self:extendjump()
 
 elseif not btn(4) then
  -- elseif code
  self.jumppressed = false
 end

 --left/right movement set it 0 ?
 self.dx = 0
 --left
 if btn(0) then
  self:moveleft()
 end
--right
 if btn(1) then
  self:moveright()
 end
 updatelocation(self)

end

function player:draw()
 -- draw only non flash frame
 if self.flash == false then
  --draw the sprite either left or right
  if not self.isgrounded then
   if self.isfacingright then
    --http://pico-8.wikia.com/wiki/spr
    spr(1,self.x, self.y, 1, 1, false)
   else
    spr(1,self.x, self.y, 1, 1, true)
   end 
  end
 end     

end


