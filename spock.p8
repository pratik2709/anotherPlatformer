x=64 y=64
function _update()
    if(btn(0)) then x=x-1 end
end

function _draw()
 -- draw code
 rectfill(0,0,127,127,5)
 circfill(x,y,7,8)
end

function player: new(x, y )
 local o = {}
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

function updatelocation(actor)
 -- do something
 actor.x += actor.dx

 actor.dy += globals.gravity

 --fall
 actor.y += actor.dy

end

function player:moveleft(var)
 self.isfacingright = false
 self.dx = -2
end

function player:moveright(var)
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
  self.jump()
  self.jumppressed = true
 elseif btn(4)
 and self.jumptimer<10
 and self.jumppressed
 and self.dy < 0 then
  -- elseif code
  self.extendjump()
 end
 elseif not btn(4) then
  -- elseif code
  self.jumppressed = false
 end

 --left/right movement set it 0 ?
 self.dx = 0
 --left
 if btn(0) then
  self.moveleft()
 end
--right
 if btn(1) then
  self.moveright()
 end
 updatelocation(self)

end



