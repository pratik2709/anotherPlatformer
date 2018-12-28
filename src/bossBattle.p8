__lua__

function battleDraw()
  drawStars()
  drawShip()
  drawBullet()
  drawBoss()
  drawExplosionForBoss()
  drawBossBullet()
end

function updateBossBattle()
  update_stars()
  updateShipInvulnerability()
  updateShooterExplosions()
  updateShipTransition()
  updateCameraPositionOfBossBattle()
  updateBulletForShooterEnemies()
  updateShipButtonState()
  boss1:spawnInit()
  boss1:move()
  if numberOfTicks%4==0 then
    fireBossBullet(boss1.x+((boss1.w*5)/2) - 2*5,boss1.y+(boss1.h*5)/2)
    fireBossBullet(boss1.x+((boss1.w*5)/2) + 2*5,boss1.y+(boss1.h*5)/2)
  end
  updateBulletForBoss()
end
