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
	o.isfaceright=true
	o.bounce=true --do we turn around at a wall?
	o.bad=true
  o.box={x1=0,y1=0,x2=7,y2=7}
	o.spawn = false
	o.lives = 5
	return o
end

function boss:draw()
  sspr(self.sx,
       self.sy,
       self.w,self.h,
       self.x,
       self.y,
       self.w*2,self.h*2,
       false)
end

function boss:spawnInit()
	if not self.spawn then
		self.x = ship.x
		self.y =  ship.y - 50
		self.spawn = true
	end
end

function boss:move()
	if self.x >= ship.x+50 then
		self.isfaceright = false
	elseif self.x <= ship.x-50 then
		self.isfaceright = true
	end

	if self.isfaceright and not ship.isfaceright then
		self.x += 1
		self.y = 10 * sin(self.x/50 * 0.5 * 3.14) + (ship.y - 80)
	elseif not self.isfaceright and ship.isfaceright then
		self.x -= 1
		self.y = 10 * sin(self.x/50 * 0.5 * 3.14) + (ship.y - 80)
	elseif self.isfaceright and ship.isfaceright then
		self.x += 2
		self.y = 10 * sin(self.x/50 * 0.5 * 3.14) + (ship.y - 80)
	elseif not self.isfaceright and not ship.isfaceright then
		self.x -= 2
		self.y = 10 * sin(self.x/50 * 0.5 * 3.14) + (ship.y - 80)
	end

end

function boss:update()
end

function drawBoss()
  boss1:draw()
end

function updateCameraPositionOfBossBattle (args)
    mycam:followplayer(ship.x, ship.y-50)
end
