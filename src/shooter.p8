--__lua__
function initialize_shooter()
  ship = {
    sprite_number=4,
    x=35*8,
    y=62*8,
    p=0,
    t=0,
    imm=false,
    box = {x1=0,y1=0,x2=7,y2=7}
  }
  bound_area = {}
  bound_area.x_max = (80*8)+(64)
  bound_area.x_min = (80*8)-(64)
  bound_area.y_min = (40*8)-(128)
  bound_area.y_max = (40*8)
  bullets={}
  enemies={}
  explosions={}
  stars = {}
  initialize_stars()
  transitionspeed = 3
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
  drawStars()
  drawShip()
  drawEnemy()
  drawBullet()
  drawExplosion()
end

function update_shooter()
  update_stars()
  updateShipInvulnerability()
  updateShooterExplosions()
  updateShipTransition()
  updateCameraPositionForShooter()
  updateRespawnEnemyStatus()
  transitionLevel()
  updateShooterEnemies()
  updateBulletForShooterEnemies()
  updateShipButtonState()
end

function drawBoss()
  if globals.level == 3 then
    boss1:draw()
  end
end

function drawExplosion()
  for explosion in all(explosions) do
    circ(explosion.x,explosion.y,explosion.t/2,8+explosion.t%3)
  end
end

function drawStars()
  for st in all(stars) do
   pset(st.x,st.y,6)
  end
end

function drawShip()
  if not ship.imm or t%8 < 4 then
   spr(ship.sprite_number,ship.x,ship.y)
  end
end

function drawEnemy (args)
  for enemy in all(enemies) do
    spr(enemy.sprite_number, enemy.x, enemy.y)
  end
end

function drawBullet()
  for bullet in all(bullets) do
   spr(bullet.sprite_number,bullet.x,bullet.y)
  end
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
    globals.enemies += 1
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

function transitionLevel()
  if globals.enemies > 50 then
    globals.level=3
  end
end

function updateCameraPositionForShooter()
  if globals.level == 3 then
    mycam:followplayer(ship.x, ship.y-60)
    boss1.x = ship.x
    boss1.y = ship.y - 100
  else
    mycam:followplayer(ship.x, ship.y)
  end
end

function updateShipTransition()
  if ship.y > (40*8 - 40) then
     ship.y -= transitionspeed
   end
end

function explode(x,y)
  add(explosions,{x=x,y=y,t=0})
end

function fire()
  local bullet = {
    sprite_number=6,
    x=ship.x,
    y=ship.y,
    dx=0,
    dy=-3,
    box={x1=2,y1=0,x2=5,y2=4}
  }
  add(bullets,bullet)
end

function updateShooterExplosions()
  for ex in all(explosions) do
    ex.t+=1
    if ex.t == 13
      then
      del(explosions, ex)
    end
  end
end

function updateShipInvulnerability ()
  if ship.imm then
    ship.t += 1
    if ship.t > 30 then
      ship.imm = false
      ship.t = 0
    end
  end
end

function updateShooterEnemies ()
  for enemy in all(enemies) do
    -- go down
    enemy.my += 1.3
    enemy.x = enemy.r*sin(enemy.d*t/50) + enemy.mx
    enemy.y = enemy.r*cos(t/50) + enemy.my
    if shooter_collision(ship, enemy) and not ship.imm then
      ship.imm = true
      player_lives -= 1
    end

    if enemy.y > 320 then
      del(enemies,enemy)
    end
  end
end

function updateBulletForShooterEnemies()
  for bullet in all(bullets) do
    bullet.x += bullet.dx
    bullet.y += bullet.dy
    if bullet.y < (320-128) or bullet.y > 320 then
      del(bullets,b)
    end
    for enemy in all(enemies) do
      if shooter_collision(bullet, enemy) then
        del(enemies, enemy)
        -- ship.p += 1
        explode(enemy.x, enemy.y)
      end
    end
  end
end

function updateShipButtonState()
  if btn(0) then ship.x-=1 end
  if btn(1)
    then
      ship.x+=1
  end
  if btn(2)
   then
     ship.y-=1
   end
  if btn(3) and globals.level != 3
   then
     ship.y+=1
   end
  if btnp(5) then fire() end
end

function updateRespawnEnemyStatus ()
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
