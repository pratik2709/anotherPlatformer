__lua__

function battleDraw()
  drawStars()
  drawShip()
  drawBullet()
  drawBoss()
  drawExplosionForBoss()
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
end
