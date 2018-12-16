--__lua__
-- create a baddie
function baddie:new(x,y)
	local o={}
	setmetatable(o, self)
	self.__index = self
	o.x=x
	o.y=y
  o.w=8
  o.h=8
	o.sx = 0
	o.sy = 0
	o.dx=0
	o.dy=0
	o.spr=016
	o.frms=2
  o.standing=false
  o.hanging=false
  o.jumppressed = false
  o.falltimer = 0
  o.falltimer = 0
  o.landtimer = 0
  o.hurtimer = 0
  o.jumpvelocity = 4
	o.isfaceright=false
	o.bounce=true --do we turn around at a wall?
	o.bad=true
  o.box={x1=0,y1=0,x2=7,y2=7}
	return o

end

function baddie:draw()
	if self.isfaceright then
		anim(self,self.spr,self.frms,6,true)
	else
		anim(self,self.spr,self.frms,6,false)
	end
end

function baddie:move()
	self.startx=self.x
	if self.isfaceright then
		self.dx=1
	else
		self.dx=-1
	end
end

function baddie:update()
end

function spawn_baddies(plyrx)
    for y=50,63 do
     for x=(plyrx/8)-10,(plyrx/8)+10 do
      val = mget(x,y)
      if fget(val,2) then
       local bad = baddie:new(x*8,y*8)
   		  add(baddies,bad)
   		   mset(x,y,0)
      end
     end
    end
end

function checkwallcollisionenemy(actor)
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
      if actor.isfaceright then
        actor.isfaceright = false
      else
        actor.isfaceright = true
      end
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
    end
  end

  --standing on something code
  if collide(actor,0,1) and not actor.hanging then
    actor.standing=true
    actor.falltimer=0
  else
    actor.falltimer+=1
  end

  actor.dx*=.98

end
