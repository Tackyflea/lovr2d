lovr.mouse = require("lovr-mouse") 
require('lovr2d')  
local UI  
function lovr.load() 
 
    UI = Lovr2d:new()
 
    local box1 = UI:box({
        x = 100,
        y = 100,
        height = 80,
        width = 80,
        color = "#ffffff"
    })
    local roundedBox = UI:roundedBox({
        roundness = 0.15,
        x = 200,
        y = 100,
        height = 80,
        width = 80,
        color = "#ff00ff"
    })
    local text = UI:text({
        text= "myCoolText", 
        x = 300,
        y = 100, 
        height = 80,
        width = 80,
        color = "#ff0000"
    })
    local textChanging = UI:text({
        text= function() return "testing "..math.floor(lovr.timer.getTime()*10)/10 end, 
        x = 550,
        y = 100,
        height = 80,
        width = 80,
        color = "#ff0000"
    })
    local bottomRightText = UI:text({
        text= "myRightAlignedext", 
        halign_text = "right",
        valign_text = "bottom",
        valign="bottom",
        halign="right",
        color = "#ff0000"
    })

    local botttomLeftBox = UI:box({ 
        valign="bottom",
        halign="left",
        height = 200,
        width = 200,
        color = "#ff4f2f"
    })
    local botttomLeftboxChild = UI:text({ 
        text= "bottom left\n  aligned and \n im a child! ", 
        halign_text = "left",
        valign_text = "top",
        parent=botttomLeftBox,  
        color = "#ffffff"
    })

    parentBox = UI:box({ 
        width="30vw",height=150,
        x="30vw",y=300,
        color = "#ff0000", 
        flex = true,
    })
    rotatedBox = UI:box({ 
        rotation=function() return lovr.timer.getTime()*8 end,
        width=150,height=150,
        x=500,y=300,
        color = "#f9f9f9"
    })
    local dragBox1Text = UI:text({ 
        text="Percent Box ", parent =parentBox,
        
    })

end

function lovr.update(dt)
end

function lovr.draw(pass)
   UI.draw(pass)
    UI:updateChildren(dragBox)
end
