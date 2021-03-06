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
