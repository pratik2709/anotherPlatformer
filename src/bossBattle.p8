__lua__

function battleDraw (args)
  update_stars()
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
