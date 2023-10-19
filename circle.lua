lovr.mouse = require("lovr-mouse")
require('lovr2d')
local UI
local mainCircle
function lovr.load()
    UI                   = lovr2d:new()

    local radius         = lovr.system.getWindowWidth() / 3
    local circleSegments = 64 

    mainCircle           = UI:circle({
        rotation = function() return lovr.timer.getTime() * 120 end,
        radius = radius,
        halign = "center",
        valign = "center",
        angleStart = 0,
        angleEnd = 360,
        segments = circleSegments,
        color = "#ffffff"
    })
    local pointerCircle  = UI:circle({
        x = mainCircle.radius + 30,
        radius = 15,
        halign = "center",
        valign = "center",
        rotation = 180,
        segments = 3,
        color = "#ffffff"
    })

    --Zones
    local segment1       = UI:circle({
        parent = mainCircle,
        radius = mainCircle.radius,
        rotation = -90,
        angleStart = 0,
        angleEnd = 120,
        segments = circleSegments,
        color = "#ff00ff"
    })
    local segment2       = UI:circle({
        parent = mainCircle,
        radius = mainCircle.radius,
        rotation = 30,
        angleStart = 0,
        angleEnd = 120,
        segments = circleSegments,
        color = "#00ff00"
    })

    local segment3       = UI:circle({
        parent = mainCircle,
        radius = mainCircle.radius,
        rotation = 150,
        angleStart = 0,
        angleEnd = 120,
        segments = circleSegments,
        color = "#ffffff"
    })
    local text           = UI:text({
        parent = segment1,
        text = "myCoolText",
        halign = 'center', valign = 'center',
        color = "#fffff",
        scale = function() return math.sin(lovr.timer.getTime()*3+1)+2 end,
    })
    local text           = UI:text({
        parent = segment2,
        text = "myCoolText2!",
        scale = function() return math.sin(lovr.timer.getTime()*3+2)+2 end,
        color = "#ff0000", halign = 'center',  valign = 'center'
    })
    local text           = UI:text({
        parent = segment3,
        text = "myCoolText3!",
        scale = function() return math.sin(lovr.timer.getTime()*3+3)+2 end,
        color = "#ff0000",
        halign = 'center',
        valign = 'center'
    })
end

function lovr.update(dt)
end

function lovr.draw(pass)
    UI.draw(pass) 
end
