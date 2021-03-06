pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
globals = {
 gravity = 0.2,
 dt = 0.5,
 level=1,
 enemykills=0,
}
player = {}
baddie={}
baddies = {}
player_bullets={}
cam = {}
boss ={}
bosshurtexplosions={}
bossbullets = {}
bullet={}
pool={}
  ship = {
    sprite_number=4,
    x=35*8,
    y=62*8,
    p=0,
    t=0,
    imm=false,
    flash=false,
    isfaceright=true,
    box = {x1=0,y1=0,x2=7,y2=7}
  }
table = {}
table.pack = function (...) return {...} end
table.unpack = unpack

function table.insert (list, pos, value)
  assert(type(list) == 'table', "bad argument #1 to 'insert' "
    .."(table expected, got "..type(list)..")")
  if pos and not value then
    value = pos
    pos = #list + 1
  else
    assert(type(pos) == 'number', "bad argument #2 to 'insert' "
      .."(number expected, got "..type(pos)..")")
  end
  if pos <= #list then
    for i = #list, pos, -1 do
      list[i + 1] = list[i]
    end
  end
  list[pos] = value
end

function table.remove(list, pos)
  assert(type(list) == 'table', "bad argument #1 to 'remove' "
    .."(table expected, got "..type(list)..")")
  if not pos then
    pos = #list
  else
    assert(type(pos) == 'number', "bad argument #2 to 'remove' "
      .."(number expected, got "..type(tbl)..")")
  end
  for i = pos, #list do
    list[i] = list[i + 1]
  end
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
  self.x = mid(0,playerx-64,1024-128)
  self.y = mid(0,((playery)-64),512-128)

 camera(self.x,self.y)
end

function cam:getx()
 return self.x
end

function cam:reset()
 camera()
end

--__lua__

function updateplayerlives()
  if player_lives <= 0 then
    game_over()
  end
end

function initial_splash_screen()
    print("starting soon", mycam.x, mycam.y,4)
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

 o.sx = 10
 o.sy = 17
 o.start_frame = 10
 o.number_of_frames = 5

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
      y1=agent.y + agent.h
      x1=agent.x + agent.w
      y2=agent.y + agent.h
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
     sspr(10,
          17,
          self.w,self.h,
          self.x,
          self.y,
          self.w,self.h,
          false)
   else
     sspr(10,
          17,
          self.w,self.h,
          self.x,
          self.y,
          self.w,self.h,
          true)
   end
  elseif self.dx==0 then
   if self.isfacingright then
     sspr(10,
          17,
          self.w,self.h,
          self.x,
          self.y,
          self.w,self.h,
          false)
   else
     sspr(10,
          17,
          self.w,self.h,
          self.x,
          self.y,
          self.w,self.h,
          true)
   end
  elseif self.dx>0 then
    anim(self,10,false)
  else
    anim(self,10,true)
  end
 end

 -- sspr(player.sx,
 --      player.sy,
 --      3,5,
 --      player.x-1,
 --      player.y-2,
 --      3,5,
 --      player.flipx)

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
   -- if collide(player_bullet, sgn(player_bullet.dx),0) then
   --   del(player_bullets,player_bullet)
   -- end
   for baddie in all(baddies) do
     if shooter_collision(baddie, player_bullet) then
       del(baddies, baddie)
       del(player_bullets,player_bullet)
     end
   end
 end
end

--__lua__
function initialize_shooter()
  bound_area = {}
  bound_area.x_max = (80*8)+(64)
  bound_area.x_min = (80*8)-(64)
  bound_area.y_min = (40*8)-(128)
  bound_area.y_max = (40*8)

  enemies={}
  explosions={}
  stars = {}
  initialize_stars()
  transitionspeed = 3
  shootershipbulletpool = pool:new(30)
  shootershipbulletpool:init("bullet")
end

function initialize_stars()
  for i=1,1024 do
   add(stars,{
    x=rnd(1024-128),
    y=rnd(512-128),
    s=rnd(2)+1
   })
  end
end


function draw_shooter()
  drawstars()
  drawship()
  drawenemy()
  shootershipbulletpool:animate()
  drawexplosion()
end

function update_shooter()
  update_stars()
  if updateshiptransition() then
    updateshipinvulnerability()
    updateshooterexplosions()
    updaterespawnenemystatus()
    transitionlevel()
    updateshooterenemies()
    updatebulletforshooterenemies()
    updateshipbuttonstate()
  end
end

function drawexplosion()
  for explosion in all(explosions) do
    circ(explosion.x,explosion.y,explosion.t/2,8+explosion.t%3)
  end
end

function drawstars()
  for st in all(stars) do
   pset(st.x,st.y,6)
  end
end

function drawship()
  if not ship.flash then
   spr(ship.sprite_number,ship.x,ship.y)
  end

  if ship.imm == true then
    if ship.flash==true then
      ship.flash = false
    else
      ship.flash=true
    end
  else
    ship.flash=false
  end
end

function drawenemy()
  for enemy in all(enemies) do
    spr(enemy.sprite_number, enemy.x, enemy.y)
  end
end

function drawbullet()
  shootershipbulletpool:animate()
end

function update_stars()
  for st in all(stars) do
   st.y += st.s
   if st.y >= (512-128) then
    st.y = 0
    st.x=rnd((1024-128))
   end
  end
end

function game_over()
  _update = update_over
  _draw = draw_over
end

function update_over()
end

function draw_over()
  cls()
  print("game over", ship.x,ship.y,4)
end

function respawn()
  local number_of_enemies = flr(rnd(9)) + 2
  for i=1,number_of_enemies do
    local d = -1
    local e = {
     sprite_number=5,
     mx=(ship.x-10)-(i*8),
     my=ship.y-i*8-100,
     d=d,
     x=-32,
     y=-32,
     r=12,
     box = {x1=0,y1=0,x2=7,y2=7}
    }
    add(enemies,e)
  end
end

function transitionlevel()
  if globals.enemykills > 5 then
    globals.level=3
  end
end



function updateshiptransition()
  if ship.y > (40*8 - 40) then
     ship.y -= transitionspeed
     return false
   else
     return true
  end
end

function explode(x,y)
  add(explosions,{x=x,y=y,t=0})
end

function fire(x,y)
  shootershipbulletpool:getone(x,y)
end

function updateshooterexplosions()
  for ex in all(explosions) do
    ex.t+=1
    if ex.t == 13
      then
      del(explosions, ex)
    end
  end
end

function updateshipinvulnerability ()
  if ship.imm then
    ship.t += 1
    if ship.t > 60 then
      ship.imm = false
      ship.t = 0
    end
  end
end

function updateshooterenemies ()
  for enemy in all(enemies) do
    -- go down
    enemy.my += 1.3
    enemy.x = enemy.r*sin(enemy.d*numberofticks/50) + enemy.mx
    enemy.y = enemy.r*cos(numberofticks/50) + enemy.my
    if shooter_collision(ship, enemy) and not ship.imm then
      ship.imm = true
      player_lives -= 1
    end

    if enemy.y > 320 then
      del(enemies,enemy)
    end
  end
end

function updateshipbuttonstate()
  if btn(0) then
    ship.x-=1
    ship.isfaceright=false
  end
  if btn(1)
    then
      ship.x+=1
      ship.isfaceright=true
  end
  if btn(2)
   then
     ship.y-=1

   end
  if btn(3) and globals.level != 3
   then
     ship.y+=1
   end
  if btnp(5) then fire(ship.x,ship.y) end
end

function updaterespawnenemystatus ()
  local number_of_enemies = tablelength(enemies)
  if number_of_enemies <= 0 then
    respawn()
  end
end

function tablelength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

--__lua__
function pool:new(max)
  local o={}
  setmetatable(o, self)
 self.__index = self
  o.maxsize=max
  o.bulletpool = {}
  return o
end

function pool:init(object)
  if object == "bullet" then
    for i=1,self.maxsize,1
    do
      self.bulletpool[i] = bullet:new()
    end
  end
end

function pool:getone(x,y)
  if not self.bulletpool[self.maxsize].in_use then
    self.bulletpool[self.maxsize]:spawn(x,y)

    table.insert(self.bulletpool,1,self.bulletpool[self.maxsize])
    table.remove(self.bulletpool)
  end
end

function pool:gettwo(x1,y1,x2,y2)
  if not self.bulletpool[self.maxsize].in_use and not self.bulletpool[self.maxsize-1].in_use then
    self:getone(x1,y1)
    self:getone(x2,y2)
  end
end

function pool:getpool()
  local allobjects = {}
  for i=1,self.maxsize,1
    do
      if not self.bulletpool[i].in_use then
          table.insert(allobjects ,self.bulletpool[i])
      end
  end
  return allobjects
end

function pool:animate()
  for i=1,self.maxsize,1
  do
    if self.bulletpool[i].in_use then
      spr(self.bulletpool[i].sprite_number, self.bulletpool[i].x, self.bulletpool[i].y)
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

function clearanduse (i)
  shootershipbulletpool.bulletpool[i]:clear()
  local temp = shootershipbulletpool.bulletpool[i]
  table.remove(shootershipbulletpool.bulletpool, i)
  table.insert(shootershipbulletpool.bulletpool, temp)
end

function updatebulletforshooterenemies()

  for i=shootershipbulletpool.maxsize,1,-1
  do
    if shootershipbulletpool.bulletpool[i].in_use then
      shootershipbulletpool.bulletpool[i].x += shootershipbulletpool.bulletpool[i].dx
      shootershipbulletpool.bulletpool[i].y += shootershipbulletpool.bulletpool[i].dy
      if shootershipbulletpool.bulletpool[i].y < (320-128) or shootershipbulletpool.bulletpool[i].y > 320 then
          clearanduse(i)
      elseif shooter_collision(boss1, shootershipbulletpool.bulletpool[i]) then
          boss1.lives -= 1
          explode(shootershipbulletpool.bulletpool[i].x, shootershipbulletpool.bulletpool[i].y)
          clearanduse(i)
      else
        for enemy in all(enemies) do
          -- printh("ubs")
          -- printh(shootershipbulletpool.bulletpool[i].x)
          if shooter_collision(shootershipbulletpool.bulletpool[i], enemy) then
            globals.enemykills += 1
            del(enemies, enemy)
            explode(enemy.x, enemy.y)
            clearanduse(i)
            break
          end
        end
      end
    end
  end
end

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
 o.lives = 10
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

function boss:spawninit()
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

function drawboss()
  boss1:draw()
end

function updatecamerapositionofbossbattle()
    mycam:followplayer(ship.x, ship.y - 50)
end

function boss:bosshurt()
 sspr(self.sx + 8,
       self.sy,
       self.w,self.h,
       self.x,
       self.y,
       self.w*5,self.h*5,
       false)
end

function drawexplosionforboss()
  for explosion in all(explosions) do
    circ(explosion.x,explosion.y,explosion.t/2,8+explosion.t%3)
  boss1:bosshurt()
  end
end

function firebossbullet(x,y)
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

function updatebulletforboss()
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

function drawbossbullet()
  for boss_bullet in all(bossbullets) do
   spr(boss_bullet.sprite_number,boss_bullet.x,boss_bullet.y)
  end
end


function battledraw()
  drawstars()
  drawship()
  drawbullet()
  drawboss()
  drawexplosionforboss()
  drawbossbullet()
end

function updatebossbattle()
  update_stars()
  updateshipinvulnerability()
  updateshooterexplosions()
  --updatecamerapositionofbossbattle()
  updatebulletforshooterenemies()
  updateshipbuttonstate()
  boss1:spawninit()
  boss1:move()
  if numberofticks%4==0 then
    firebossbullet(boss1.x+((boss1.w*5)/2) - 2*5,boss1.y+(boss1.h*5)/2)
    firebossbullet(boss1.x+((boss1.w*5)/2) + 2*5,boss1.y+(boss1.h*5)/2)
  end
  updatebulletforboss()
end

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
 o.sy = 8
 o.start_frame = 0
 o.number_of_frames = 2
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
  anim(self,2,true)
 else
  anim(self,2,false)
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

--__lua__
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

function abs_box(s)
  --finding actual location of the characters on the maps
  -- and the bounding box
  local box = {}
  box.x1 = s.box.x1 + s.x
  box.y1 = s.box.y1 + s.y
  box.x2 = s.box.x2 + s.x
  box.y2 = s.box.y2 + s.y
  return box
end

function shooter_collision(a,b)
  local box_a = abs_box(a)
  local box_b = abs_box(b)

  if box_a.x1 > box_b.x2 or
     box_a.y1 > box_b.y2 or
     box_b.x1 > box_a.x2 or
     box_b.y1 > box_a.y2 then
     return false
  end

  return true

end

-- object, starting frame, number of frames,
-- animation speed, flip
function anim(actor, anim_speed, flipper)
 if(not actor.current_tile) actor.current_tile = 0

 if(actor.current_tile%(30/anim_speed)==0) then
  actor.sx = actor.sx + 8
  if(actor.sx==(actor.start_frame+(8*(actor.number_of_frames)))) then
   actor.sx = actor.start_frame
  end
 end
 sspr(actor.sx,
      actor.sy,
      actor.w,actor.h,
      actor.x,
      actor.y,
      actor.w,actor.h,
      flipper)
 -- spr(actor.frame,actor.x,actor.y,1,1,flipper)

 actor.current_tile+=8

end




function _init()
  t=0
  numberofticks=0
  splashscreentimer = 0
  player_lives = 5
  mapwidth = 128
  mapheight = 64
  mycam = cam:new(mapwidth, mapheight)
  player1 = player:new(10.0,0.0)
  initialize_shooter()
  boss1 = boss:new(0, 0)
end


function _update()
  numberofticks += 1
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
    updatebossbattle()
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
   mycam:followplayer(ship.x, ship.y-50)
   draw_shooter()
   map(0,0,0,0,128,128)
 elseif globals.level==3 then
   mycam:followplayer(ship.x, ship.y - 50)
   battledraw()
   map(0,0,0,0,128,128)
 end
 player1:drawlives()
 draw_debug()
end

function draw_debug()
    --print(ship.x,mycam.x,mycam.y,11)
    --print(ship.y,mycam.x + 20,mycam.y,11)
end



__gfx__
000000000cccccc000000000999999990000000000000000000000000aaaaaa00000000000000000000000000000000000000000000000000000000000000000
00000000cdddddd1000000009bbbbbb900c00c000000000000000000c99999910bbbbbb008888880000000000000000000000000000000000000000000000000
0aaaaa00cdddddd1000000009bbbbbb900c00c0000bbbb0000000000cdddddd10b8bb8b008a88a80000000000000000000000000000000000000000000000000
0a1a1a00cdddddd1000000009bb88bb9cccccccc00b8cb0000090000cdddddd10bbbbbb008888880000000000000000000000000000000000000000000000000
0aaaaa00cdddddd1000000009bb88bb9c999999c00bc8b0000000000cdddddd10bbbbbb008888880000000000000000000000000000000000000000000000000
0aaaaa00cdddddd1000000009bbbbbb9cccccccc00bbbb0000000000cdddddd10b0000b008000080000000000000000000000000000000000000000000000000
00000000cdddddd1000000009bbbbbb90c0cc0c00000000000000000cdddddd10000000000000000000000000000000000000000000000000000000000000000
00000000011111100000000099999999000000000000000000000000011111100000000000000000000000000000000000000000000000000000000000000000
000009900000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999990000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0090990000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
099999900cc0ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999999000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009090000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009000ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a1a10000a1a10000a1a10000a1a10000a1a10000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a00000000a000000a00000000a000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa000000aa000000aa000000aa000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000a000000a00000000a000000a00000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000020000000000000000000000000000020200000000000000000000000000000002020202020000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002020000000000000000000000000000020200000000000000000000000000020202020202020200000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002020000000000000000000002020000020200000000000000000000000000000000000000000202020200000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002000000000000000000000002020200020202000002020200000000000000000000000000000000020202020000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002000000000000000000000000020200020202020200000002020202000200000000000000000000000002020000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000000002000000000000000000000202020202020202020202020200020002000200000202000202000202020200020202020200000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000020202000000000000000002020202020202020202020202020202020202020202020202020202020002020200000202020202020200000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020202000000000000000202020002020202020202020202000000000000000000000000000200000000000000000000000202020202020000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020002000000000002020202020202000000000202020202000000000000000000000000020202000000000000000000000000000002020200000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020000000000000002020202020202000200020202020202000000000000000000000000020202020000000000000000000000000000000202000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020000000000000000000202020000020000020202020202020000000000000000000000020202020000000000000000000000000000000202020202000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20002000000000000000000020202020000000002000202020202020000000000000000000000020202020000000000000000000000000000000002020202020
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20002000000000000000202020202000000020000000202020202020200000000000000000000020202020000000000000000000000000000000000000202020
20200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20002000200000000000002020200000000000002000202020202020200000000000000000000020202020000000000000000000000000000000000000000000
20202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20002020200000000000202020000000000000000000202020202020200000000000000000000020202000000000000000000000000000000000000000000000
00002020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20002020200000000000202000000000002000002000202020202020000000000000000000000020202000000000000000000000000000000000000000000000
00000000002020202020002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20002020202000000020200000000000000000000000202020202020200000000000000000101010101010000000000000000000000000000000000000000000
00000000002020202020202020202020200000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000
20002020202000002020200000000000002000002000202020202020000000000000000000101010101010000000000000000000000000000000000000000000
00000020202020202020202020202020202000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101000202000002020200000000000000000012020202020202020000000000000000000101020102010000000000000000000000000000000000000000000
00002020202020002020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101000002020202020000000000000210000000020202020202020000000000000000000101010101010000000000000000000000000000000000000000000
00000000000000002020002020202020002020202020002020000000000000000000000000000000000000000000000000000000000000000000000000000000
10101000002020202000000000000020202020000020202020202000000000000000000000101010101010000000000000000000000000000000000000000000
00000000000000000000202020200000002020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010002020202000000000000020202000000020202020202020000000000000000000101010101010000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000202020202020200000000000000000000000000000000000000000000000000000000000000000000000
10101010100020202000000000000020202000000020202020202020000000000000000000101010101010000000000000000000000000000000000000000000
00000000000000000000000000000000000000002020200020202020200020200000000000000000000000000000000000000000000000000000000000000000
10101010100020200020200000000000200000000020202020202020000020000000000000000010000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000002020202020202020202000000000000000000000000000000000000000000000000000000000000000
10101010102020202020000000000000200000000020202020202020000000000000000000000010000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000202020002020202000000000000000000000000000000000000000000000000000000000000000
10101010101020202020200000000000200000000020202020202020000000000000000000000010000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000020202020202020200000000000000000000000000000000000000000000000000000000000
10101010101020002000000000000000200000000020202020207070707070700000000000000010100000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000020202020202020200000000000000000000000000000000000000000000000000000000000
10101010101010000000000000000000200000000020202020202020000010100000000000000020100000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000202020200000000000202020000000000000000000000000000000000000000000000000000000
10101010101010100000000020200000200000002020101020202020200110100000000000000020100000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000020202000000000000000000000000000000000000000000000000000
10101010101010100000202020200020202020200020101020202020202010100000000000000020100000000000000000002020000000000000000000000000
00000000000000000000000000002000002020202020202000000000000000000000000020202020000000000000000000000000000000000000000000000000
10101010101010101020202020000020202020202020101020202020200010102000002020000020100000000000000000000000202020200020202020202020
20202020202020202020202020202020202020202020202020202000000000000000000000001010100000000000000000000000000000000000000000101010
10101010101010101010101010101010101010101010101010101010101010101010301010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
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
0001000300000001000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000000101010100000000000000010101
0202000000000000000000000000000000000202000000000200020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000000020202000202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020002000200020202020200000002020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000200000202020002020202020000020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000020000020200020200020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000020200020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020200020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000020002020202020202020202020000020002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000002020002020002020202020202020002020002020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000020200000202020202020202020002020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000
0200000002000200020000020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202000202020202020002020200020002000202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000
0202020202020202020202000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000
0202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000
0202020202020202020202020000000000000000000000000202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020200020202020200000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020002020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020000000202020202020200020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020000000202020202020202000000000202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000002020202020202020202020202000202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202000000000000000002020202020002020202000000020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000020202020200020200000000000000000002020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000002020202020202020000000000000000000002020002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000202020202020202020202020200000000000000020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000202020202020202020202020202020202020200000000000000000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000202020000000000000000000000020200000000000000000000000000000202000000000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000200020000000000000000000000000202000000000000000000000000000002020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000


