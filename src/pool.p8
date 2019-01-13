--__lua__
function pool:new(max)
  local o={}
  setmetatable(o, self)
	self.__index = self
  o.maxSize=max
  o.bulletPool = {}
  return o
end

function pool:init(object)
  if object == "bullet" then
    for i=1,self.maxSize,1
    do
      self.bulletPool[i] = bullet:new()
    end
  end
end

function pool:getOne(x,y)
  if not self.bulletPool[self.maxSize].in_use then
    self.bulletPool[self.maxSize]:spawn(x,y)

    table.insert(self.bulletPool,1,self.bulletPool[self.maxSize])
    table.remove(self.bulletPool)
  end
end

function pool:getTwo(x1,y1,x2,y2)
  if not self.bulletPool[self.maxSize].in_use and not self.bulletPool[self.maxSize-1].in_use then
    self:getOne(x1,y1)
    self:getOne(x2,y2)
  end
end

function pool:getPool()
  local allObjects = {}
  for i=1,self.maxSize,1
    do
      if not self.bulletPool[i].in_use then
          table.insert(allObjects ,self.bulletPool[i])
      end
  end
  return allObjects
end

function pool:animate()
  for i=1,self.maxSize,1
  do
    if self.bulletPool[i].in_use then
      spr(self.bulletPool[i].sprite_number, self.bulletPool[i].x, self.bulletPool[i].y)
    end
  end
end

function bullet:new()
  local o={}
  setmetatable(o, self)
	self.__index = self
  o.dx=0
  o.dy=-3
  o.in_use=false
  o.box={x1=2,y1=0,x2=5,y2=4}
  o.sprite_number=6
  return o
end

function bullet:spawn(x,y)
  self.x=x
  self.y=y
  self.in_use = true
end

function bullet:clear()
  self.x = 0
  self.y = 0
  self.in_use = false
end

function clearAndUse (i)
  shooterShipBulletPool.bulletPool[i]:clear()
  local temp = shooterShipBulletPool.bulletPool[i]
  table.remove(shooterShipBulletPool.bulletPool, i)
  -- printh("clear")
  -- printh(temp.x)
  table.insert(shooterShipBulletPool.bulletPool, temp)
end

function updateBulletForShooterEnemies()

  for i=shooterShipBulletPool.maxSize,1,-1
  do
    if shooterShipBulletPool.bulletPool[i].in_use then
      shooterShipBulletPool.bulletPool[i].x += shooterShipBulletPool.bulletPool[i].dx
      shooterShipBulletPool.bulletPool[i].y += shooterShipBulletPool.bulletPool[i].dy
      if shooterShipBulletPool.bulletPool[i].y < (320-128) or shooterShipBulletPool.bulletPool[i].y > 320 then
          clearAndUse(i)
      elseif shooter_collision(boss1, shooterShipBulletPool.bulletPool[i]) then
          boss1.lives -= 1
          explode(shooterShipBulletPool.bulletPool[i].x, shooterShipBulletPool.bulletPool[i].y)
          clearAndUse(i)
      else
        for enemy in all(enemies) do
          -- printh("ubs")
          -- printh(shooterShipBulletPool.bulletPool[i].x)
          if shooter_collision(shooterShipBulletPool.bulletPool[i], enemy) then
            globals.enemyKills += 1
            del(enemies, enemy)
            explode(enemy.x, enemy.y)
            clearAndUse(i)
            break
          end
        end
      end
    end
  end
end
