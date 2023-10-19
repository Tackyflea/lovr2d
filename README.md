
# lovr2d
a 2d gui tool for use with [LOVR](https://lovr.org)

  

made by [Lucky Dee](https://www.linkedin.com/in/lucky-dee-7745b240/) when i have time, fixes/ changes/ minmax PRs welcome!

# Requirements:
Lovr-mouse

# Example

![Example](https://github.com/Tackyflea/lovr2d/blob/25db94484ee05d4e9b6ebc5e38a6987bb4331ed9/images/lovr_Z4t2upoL2Y.png)

![Example Dragging](https://github.com/Tackyflea/lovr2d/blob/25db94484ee05d4e9b6ebc5e38a6987bb4331ed9/images/lovr_E41TS5VcJB.gif)
# How to use
Coming soon, apologies, run main.lua and see some example shapes!
The short version is , just do this 

    lovr.mouse  =  require("lovr-mouse")
    require('lovr2d')
    local  UI
    function  lovr.load()
	    UI  =  lovr2d:new()
	    
	    --example shape
	    local  box1  =  UI:box({x = 100, y = 100, height  =  80, width = 80, color = "#ffffff"})
    end 
    
    function  lovr.draw(pass)
	    UI.draw(pass)
    end
### WIP , should work  

ui:circle())
circle specs 
radius - number  - how large it is 
rotation - 0-360 (deg )(OR FUNCTION!) (applies to all objects)
angleStart = 0-360 (deg )
angleEnd = 0-360 (deg )
segments - control how many subdivisions a circle has 


### List of all object types 
|name| description  |
|--|--|
| ui:box({props}) |   generic rectangle, multi purpose|
| ui:button({props}) |   looks like a rectangle but with property: onLeftClick|
| ui:roundedBox({props}) |   rectangle  special properties: roundness|
| ui:image({props}) |   creates an image with a texture property (which you should ideally preload)|
| ui:text({props}) |  make text, has special properties: text, halign_text, valign_text |

### Other functions

    :delete(object)

... will delete the object! And it's kids!

    :getChildren(parent(object), andParent(boolean))

Will get you the children, and optionally with the parent as well if you want to modify all of them at once


### General properties for all items/ text
|Property| description |
|--|--|
| **x** |[number]  x position |
| **y** |[number]  y position |
| **z** |[number]  z index, **not** z position, optional, be mindful on stacking when using it  |
| **width** | [number] width |
| **height**| [number] height |
| **color**| [string] hex color , IE "#FF00FF"|
| **parent**| [object] link to a parent of lovr2d type, when parent moves, this moves|
| **halign**| [string] horizontal align , "left" "center" "right"|
| **valign**| [string] vertical align , "top" "center" "bottom"|
| **scale**| [number] scales object, supports function passing |
| **opacity**| [number] opacity, 0-1|
| **drag**| [bool]dragging  on and off, **warning**: experimental. Ideally use on shapes, not text|
| **dragProps**| [object] explained below { sendToFront: boolean, limits: {left=x,top=x, right=x, bottom=x} 

#### When using drag, ideally , specify the range and wether to send the object to front ,IE 

    dragBox  =  UI:box({
    dragProps  = {
    sendToFront  =  true,
    limits  = { left  =  0, top  =  0, right  =  500, bottom  =  500 }
    },
    drag  =  true,
    width=150,height=150,
    })
    
### Special Properties 
|  UI:buttton|  |
|--|--|
| onLeftClick | [function] returns a left click action |
| roundness| [number] determines how round its going to be **warning:** experimental   |

|  UI:roundedBox|  |
|--|--|
| roundness| [number] determines how round its going to be **warning:** experimental  |

|  UI:text|  |
|--|--|
| text| [text OR function]prints text OR auto updates it live |
| halign_text| [text] Same as halign , BUT for text specific alignment (you can stack both) |
| valign_text| [text]  Same as valign, BUT for text specific alignment  (you can stack both)|

|  UI:text|  |
|--|--|
| text| [text OR function]prints text OR auto updates it live |
| halign_text| [text] Same as halign , BUT for text specific alignment (you can stack both) |
| valign_text| [text]  Same as valign, BUT for text specific alignment  (you can stack both)|


### box and rounded box example 

    local  box1  =  UI:box({ 
	    x  =  100, y  =  100,
	    height  =  80, width  =  80,
	    color  =  "#ffffff"
    })
    
    local  roundedBox  =  UI:roundedBox({ 
	    roundness  =  0.15, 
	    x  =  200, y  =  100, 
	    height  =  80, width  =  80,
	    color  =  "#ff00ff"
    })
### dragging example

    UI:box({
	    dragProps  = {
		    sendToFront  =  true,
		    limits  = { 
			    left  =  0, top  =  0, 
			    right  =  lovr.system.getWindowWidth(), bottom  =  lovr.system.getWindowHeight() 
		    }
	    },
	    drag  =  true,
	    width=150,height=150,
	    x=500,y=300,
	    color  =  "#f9f9f9"
    })
### Parenting example 

    local  botttomLeftBox  =  UI:box({
	    valign="bottom", halign="left", 
	    height  =  200,  width  =  200, 
	    color  =  "#ff4f2f"
    })
    
    local  botttomLeftboxChild  =  UI:text({
	    text=  "bottom left\n aligned and \n im a child! ",
	    halign_text  =  "left", valign_text  =  "top",
	    parent=botttomLeftBox,
	    color  =  "#ffffff"
    })

### image example 
load texture

    self.cursor  =  lovr.graphics.newTexture("cursor.png")

use texture
    
    self.mouseCursor  =  self.UI:image({  
	    texture  =  self.cursor, 
	    width  =  32, 
	    height  =  32 
    })

