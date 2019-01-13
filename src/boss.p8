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
  o.box={x1=0,y1=0,x2=7*5,y2=7*5}
	o.spawn = false
	o.lives = 20
	return o
end

function boss:draw()
  sspr(self.sx,
       self.sy,
       self.w,self.h,
       self.x,
       self.y,
       self.w*5,self.h*5,
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

function updateCameraPositionOfBossBattle()
    mycam:followplayer(ship.x, ship.y-50)
end

function boss:bossHurt()
	sspr(self.sx + 8,
       self.sy,
       self.w,self.h,
       self.x,
       self.y,
       self.w*5,self.h*5,
       false)
end

function drawExplosionForBoss()
  for explosion in all(explosions) do
    circ(explosion.x,explosion.y,explosion.t/2,8+explosion.t%3)
		boss1:bossHurt()
  end
end

function fireBossBullet(x,y)
  local boss_bullet = {
    sprite_number=6,
    x=x,
    y=y,
    dx=0,
    dy=10,
    box={x1=2,y1=0,x2=5,y2=4}
  }
  add(bossbullets,boss_bullet)
end

function updateBulletForBoss()
  for boss_bullet in all(bossbullets) do
    -- bullet.x += bullet.dx
    boss_bullet.y += 4
    -- if bullet.y < (ship.y - 64) or bullet.y > (ship.y + 10) then
    --   del(bossbullet,bullet)
    -- end

    if shooter_collision(ship, boss_bullet) and not ship.imm then
        player_lives -= 1
        del(bossbullet,boss_bullet)
				ship.imm = true
    end
  end
end

function drawBossBullet()
  for boss_bullet in all(bossbullets) do
   spr(boss_bullet.sprite_number,boss_bullet.x,boss_bullet.y)
  end
end

function updatebosslives()
  if boss1.lives <= 0 then
    game_won()
  end
end

function game_won()
  _update = update_over
  _draw = draw_over_won
end

function draw_over_won()
    cls()
    print("You Won!", ship.x,ship.y - 40,4)
end
