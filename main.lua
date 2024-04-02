lovr.mouse = require("lovr-mouse") 
require('lovr2d')  
local UI  
function LoadUI()

    
    UI = Lovr2d:new()

    local box1 = UI.box({
        x = 100,
        y = 100,
        height = 80,
        width = 80,
        color = "#ffffff"
    })
    local roundedBox = UI.box({
        x = 200,
        y = 100,
        height = 80,
        width = 80,
        roundness = 30,
        color = "#ff00ff"
    })
    local text = UI.text({
        text= "myCoolText", 
        x = 300,
        y = 100, 
        height = 80,
        width = 80,
        color = "#ff0000"
    })
    local textChanging = UI.text({
        text= function() return "testing "..math.floor(lovr.timer.getTime()*10)/10 end, 
        x = 550,
        y = 100,
        height = 80,
        width = 80,
        color = "#ff0000"
    })

    local parentBox = UI.box({ 
        width="30vw",height=150,
        x="30vw",y=700,
        color = "#ff0000", 
        flex = true,
    })
    local rotatedBox = UI.box({ 
        rotation=function() return lovr.timer.getTime()*8 end,
        width=150,height=150,
        color = "#f9f9f9", parent = parentBox,
    })
    local Button = UI.button({ 
        text="Button ",
        width = 200,height =  50,color = {0,0.2,0}
        
    })
    Button.onLeftClick = function()
        print('click')
    end
end
function lovr.load() 
 
 
    LoadUI()

end

function lovr.update(dt)
    
end
function lovr.draw(pass)

    --3d 
    pass:setViewCull(true)
    pass:setCullMode('back')
    local x, y, z = 0,0, -8
    pass:setColor(.3, .82, 1)
    pass:sphere(x, y, z, 1.33,math.pi+lovr.timer.getTime(),0,1,0,4,4)


    local lovrTimer = lovr.timer.getTime()
    pass:setColor(1,1,1)
    pass:cube(0,0,0, 333.4, lovrTimer, 0, 1, 0)

    --2d 
    pass:setColor(0,0,0)
    pass:setCullMode()
    UI.draw(pass)
end
