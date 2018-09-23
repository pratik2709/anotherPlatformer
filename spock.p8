x=64 y=64
function _update()
    if(btn(0)) then x=x-1 end
end

function _draw()
 -- draw code
 rectfill(0,0,127,127,5)
 circfill(x,y,7,8)
end

