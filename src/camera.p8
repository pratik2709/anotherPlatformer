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
--right-most bound for x
-- from jelpi game
--128*64 map size
-- cx=mid(cx,64,128*8-64)
-- cy=mid(cy,64,64*8-64)
--64 viewport size to keep centered
--128 may be the resolutions
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