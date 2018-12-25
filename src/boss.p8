--__lua__
-- create a baddie
function boss:new(x,y)
	local o={}
	setmetatable(o, self)
	self.__index = self
	o.x=x
	o.y=y
  o.w=8
  o.h=8
	o.sx = 64
	o.sy = 0
	o.start_frame = 64
	o.number_of_frames = 2
	o.dx=0
	o.dy=0
  o.hurtimer = 0
	o.isfaceright=false
	o.bounce=true --do we turn around at a wall?
	o.bad=true
  o.box={x1=0,y1=0,x2=7,y2=7}
	return o
end

function boss:draw()
  sspr(self.sx,
       self.sy,
       self.w,self.h,
       self.x,
       self.y,
       self.w*10,self.h*10,
       false)
end

function boss:move()
end

function boss:update()
end
