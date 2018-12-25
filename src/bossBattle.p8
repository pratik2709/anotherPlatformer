__lua__

function battleDraw()
  drawStars()
  drawShip()
  drawBullet()
  drawBoss()
  drawExplosion()
end

function updateBossBattle()
  update_stars()
  updateShipInvulnerability()
  updateShooterExplosions()
  updateShipTransition()
  updateCameraPositionForShooter()
  updateBulletForShooterEnemies()
  updateShipButtonState()
end
