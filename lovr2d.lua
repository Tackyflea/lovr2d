--[[
    WIP STATE! Can change at will!
    By Lucky Dee
    https://www.linkedin.com/in/lucky-dee-7745b240/
]]


--using Classic OOO as a wrapper - https://github.com/rxi/classic/blob/master/classic.lua
local Object = {}
Object.__index = Object
function Object:extend()
    local cls = {}
    for k, v in pairs(self) do if k:find("__") == 1 then cls[k] = v end end
    cls.__index = cls
    cls.super = self
    setmetatable(cls, self)
    return cls
end

Lovr2d = Object:extend()

function Lovr2d:new()
    self.width, self.height = lovr.system.getWindowDimensions()
    self.info = {
        stageWidth = self.width,
        stageHeight = self.height

    }
    self.pass = nil                --to be filled later
    self.activelyDragging = nil
    self.firstSelectedButton = nil --Highlight for visuals

    self.leftClick = lovr.mouse.isDown(1)
    self.rightClick = lovr.mouse.isDown(2)

    --cache values to cancel events
    self.CACHELeftMousedown = -1
    self.CACHELeftMouseUp = -1
    self.CACHERightMousedown = -1

    self.mouseX, self.mouseY = 0, 0

    --max depth for parenting
    self.depthMax = 5


    --utility function to create cache system
    self.setupBackupValues = function(inData, values)
        local inData = inData or {}
        local outData = inData
        for index, value in pairs(values) do
            outData[index] = inData[index] or value
        end
        return outData
    end

    self.hitTest           = function(data)

        if self.activelyDragging then return nil end

        local dataX, dataY          = self:getX(data), self:getY(data)
        local dataWidth, dataHeight = self:getWidth(data), self:getHeight(data)

        local mx, my                = self.mouseX, self.mouseY
        local tempX                 = dataX - dataWidth / 2
        local tempY                 = dataY - dataHeight / 2
        local over                  = mx > tempX and mx < tempX + dataWidth and my > tempY and my < tempY + dataHeight

        return over
    end
    self.fonts             = {
        default = lovr.graphics.getDefaultFont()
    }
    self.font              = self.fonts.default

    --text
    self.fontDensity       = 1
    self.font:setPixelDensity(self.fontDensity)

    --table: url, size
    self.setFont = function(font)
        self.font = self.fonts[font.id] or self.fonts.default
    end
    --table: id, url, size
    self.addFont = function(font)
        local spread = font.spread or 1
        self.fonts[font.id] = lovr.graphics.newFont(font.url, font.size, spread)
        if self.fonts[font.id] then
            self.fonts[font.id]:setPixelDensity(self.fontDensity)
        else
            print("LOVR2d: " .. " Font not found: " .. font.id)
        end
    end
    self.liveReloadFont = function(dataFont)
        local font = dataFont or "default"
        local pickedFont = self.fonts[font]
        if self.font ~= self.fonts[font] then
            if not self.fonts[font] then
                print("LOVR2d Font not loaded! Use setFont first!  " .. font)
            else
                self.font = self.fonts[font]
                self.pass:setFont(self.font)
            end
        end
    end
    self.drawQueue = {}
    self.cachedDrawQueueL = #self.drawQueue
    self.clear = function()
        self.drawQueue = {}
        self.cachedDrawQueueL = #self.drawQueue
    end
    function CleanNils()
        local ans = {}
        for _, v in pairs(self.drawQueue) do
            ans[#ans + 1] = v
        end
        self.drawQueue = ans
    end

    self.zSort = function()
        --if something's changed in the draw queue lenght , ie we added something new
        --re sort the array based off z index
        self.cachedDrawQueueL = #self.drawQueue
        -- Populate the indexOf table
        for i, element in ipairs(self.drawQueue) do
            element.index = i
        end
        table.sort(self.drawQueue, function(a, b)
            if a.zIndex == b.zIndex then
                -- If the zIndex values are the same, compare the indices
                return a.index < b.index
            else
                -- Otherwise, compare the zIndex values directly
                return a.zIndex < b.zIndex
            end
        end)
    end
    self.__predraw = function()
        --before loop , do any deletion
        for _, data in pairs(self.drawQueue) do
            if data.deleteFun then
                local delete = data.deleteFun()
                if delete then
                    self:delete(data)
                end
            end
        end
    end
    self.draw = function(pass)
        self:CheckAndUpdateWindowSize()

        self.__predraw()

        self:setPass(pass)
        self.mouseX, self.mouseY = lovr.mouse.getPosition()
        self.leftClick = lovr.mouse.isDown(1)

        self.rightClick = lovr.mouse.isDown(2)


        if self.leftClick == false then
            self.activelyDragging = nil
            self.firstSelectedButton = nil
        end

        if self.cachedDrawQueueL ~= #self.drawQueue then
            self.zSort()
        end
        for _, data in pairs(self.drawQueue) do
            --for live updating data
            local dataX = type(data.x) == "function" and data.x() or data.x
            local dataY = type(data.y) == "function" and data.y() or data.y
            local rotation = type(data.rotation) == "function" and data.rotation() or data.rotation
            local scale = type(data.scale) == "function" and data.scale() or data.scale

            local color = self.hex2rgb(type(data.color) == "function" and data.color() or data.color)
            local opacity = type(data.opacity) == "function" and data.opacity() or data.opacity
            local strokeColor = nil
            if data.stroke then
                strokeColor = self.hex2rgb(type(data.strokeColor) == "function" and data.strokeColor() or
                    data.strokeColor)
            end
            local text = type(data.text) == "function" and data.text() or data.text
                if not text then
                    text="" 
                    print("LOVR2d Text missing ")
                end
            local dataWidth = type(data.width) == "function" and data.width() or data.width
            local dataHeight = type(data.height) == "function" and data.height() or data.height


            --window percent based data
            dataX = self:getX(data)
            dataY = self:getY(data)
            dataWidth = self:getWidth(data)
            dataHeight = self:getHeight(data)


            --pass:translate(scaleXOffset, scaleYOffset, 0)

            --start TRS
            --TODO implement Scale
            local pos3D = lovr.math.vec3(dataX, dataY, data.z)
            pass:transform(pos3D)
            pass:rotate(math.rad(rotation), 0, 0, 1)
            self.pass:scale(scale, scale, 1) --overall scale
            
            self.pass:setColor(color[1], color[2], color[3],opacity)
            if data.type == "image" then
                local cheatScaleX = -1
                if data.flipX == 1 then
                    self.pass:setCullMode("back")            --needed so that the images render in reverse
                    self.pass:scale(vec3(cheatScaleX, 1, 1)) --flip X for images
                end
                self.pass:push()
                local texture = type(data.texture) == "function" and data.texture() or data.texture
                --self.pass:setColor(1, 1, 1)
                --   self.pass:setMaterial(data.material)
                self.pass:setMaterial(texture)
                self.pass:rotate(math.pi, 0, 0, 1) --vertical flip
                if data.roundness then
                    self:roundedRect(self.pass, data)
                else
                    self.pass:plane(vec3(0), dataWidth, dataHeight)
                end
                self.pass:setMaterial()

                self.pass:pop()
                if data.flipX == 1 then
                    self.pass:setCullMode("front")
                    self.pass:scale(vec3(1 / cheatScaleX, 1, 1)) --undo flip X for images
                end
            elseif data.type == "rect" then
                if data.roundness then
                    self:roundedRect(self.pass, data)
                else
                    --todo Stroke is unused, use it
                    self.pass:plane(vec3(0), dataWidth, dataHeight)
                end
            elseif data.type == "circle" then 
                pass:circle(vec3(0), data.radius, 0, 0, 0, 0, "fill", data.angleStart * (math.pi / 180),
                    data.angleEnd * (math.pi / 180), data.segments) 
                    
            elseif data.type == "roundedRect" then
                --self.pass:scale(scaleX, scaleY, 1)
                self:roundedRect(self.pass, data)
                -- self.pass:scale(1 / scaleX, 1 / scaleY, 1)
            elseif data.type == "text" then
                --fail safe in case  you wanna do live updated text
                self.pass:setShader(self.fontShader)
                --range 0-1
                self.pass:send('strokeWidth', (data.thickness) * 16)
                self.liveReloadFont(data.font)
                --self.setFont(font)
                self.pass:text(text,
                    vec3(0),
                    scale, data.angle,
                    data.ax,
                    data.ay,
                    data.az,
                    data.wrap,
                    data.halign_text,
                    data.valign_text
                )
                self.pass:setShader()
            end

            -- self.pass:setShader()
            self.pass:scale(1 / scale, 1 / scale, 1) --overall scale
            pass:rotate(math.rad(-rotation), 0, 0, 1)
            pass:transform(-pos3D)


            --we use the invert of the array to check from nearest to mouse to end
            --this way it ray intersects cosest instead of lowest
            local reversedPosition = self.cachedDrawQueueL - _ + 1
            local interactable = self.drawQueue[reversedPosition]
            if interactable then
                self:updateHitTests(interactable)
            end
            --  end
            --end
        end


        -- self.pass:setColor(1, 1, 1, 0.2)
        -- self.pass:plane(button.x, button.y, button.z, button.width, button.height)
        --the dragging happens seperately , so we dont contantly hit check while dragging
        if self.activelyDragging then
            local dragObj = self.activelyDragging

            dragObj.x = (self.mouseX - dragObj._offsetX)
            dragObj.y = (self.mouseY - dragObj._offsetY)

            --clamp the dragging to roots limits
            local limit = dragObj.dragProps.limits
            if limit == nil then --failsafe
                limit = { left = 0, top = 0, right = lovr.system.getWindowWidth(), bottom = lovr.system.getWindowHeight() }
            end
            dragObj.x = self.clamp(dragObj.x, limit.left + dragObj.width / 2, limit.right - dragObj.width / 2)
          
            dragObj.y = self.clamp(dragObj.y, limit.top + dragObj.height / 2, limit.bottom - dragObj.height / 2)
            self:updateChildren(dragObj)
        end
    end

    -- utility function
    self.copy = function(obj, seen)
        local s = {}
        for k, v in pairs(obj) do
            s[k] = v
        end
        return s
    end
    self.clamp = function(value, min, max)
        return math.max(math.min(value, max), min)
    end
    self.hex2rgb = function(hex)
        --in case you want to use straight table
        if type(hex) == "table" then
            return hex
        end
        if type(hex) == "number" then
            return { hex, hex, hex }
        end
        hex = hex:gsub("#", "")
        return {
            tonumber("0x" .. hex:sub(1, 2)) / 255,
            tonumber("0x" .. hex:sub(3, 4)) / 255,
            tonumber("0x" .. hex:sub(5, 6)) / 255
        }
    end


    return self
end

function Lovr2d:CheckAndUpdateWindowSize()
    local newWidth, newHeight = lovr.system.getWindowDimensions()
    local widthChanged = self.width ~= newWidth
    local heightChanged = self.height ~= newHeight
    if widthChanged or heightChanged then
        self.width = newWidth
        self.height = newHeight
    end
end

function Lovr2d:DynamicResizeProperty(dataobject, inputStr, layout)
    if dataobject.flex then dataobject.static = false end 
    if dataobject.drag then dataobject.static = false end  
    if dataobject.parent then
        
    if dataobject.parent.drag then dataobject.static = false end 
    end 
    --if its static, skip the whole process
    if dataobject.static then
        if inputStr == "x" and dataobject.__cachedX then
            return dataobject.__cachedX
        elseif inputStr == "y" and dataobject.__cachedY then
            return dataobject.__cachedY
        elseif inputStr == "width" and dataobject.__cachedWidth then
            return dataobject.__cachedWidth
        elseif inputStr == "height" and dataobject.__cachedHeight then
            return dataobject.__cachedHeight
        else
        end
    end 
    --[[
        this takes in strings or numberes , if numbers deals with them straight
        otherwise figure out what type of string it needs
    ]]
    local input = dataobject[inputStr]
    if type(input) == "function" then input = input() end
    local typeIsVw                          = string.find(input, '%vw')
    local typeIsVh                          = string.find(input, '%vh')
    local typeIsPerecent                    = string.find(input, '%%')

    -- if dataobject.id=="person" then
    --     print('here')
    -- end
    local refferenceX, refferenceY          = 0, 0
    local refferenceWidth, refferenceHeight = self.width, self.height
    --use either the parents sizing or the world sizing
    if dataobject.parent then
        refferenceX = self:getX(dataobject.parent)
        refferenceY = self:getY(dataobject.parent)
        refferenceWidth = self:getWidth(dataobject.parent)
        refferenceHeight = self:getHeight(dataobject.parent)
    end
    --extract only number
    local result = tonumber(string.match(input, "^%-?%d+"))
    --if vw (or % and also youre scaling x or width )
    if typeIsVw or (typeIsPerecent and layout == "x") then
        result = (result / 100) * refferenceWidth
        --if vh (or % and youre scaling y or height )
    elseif typeIsVh or (typeIsPerecent and layout == "y") then
        result = (result / 100) * refferenceHeight
    end
    if inputStr == "width" then
        dataobject.__cachedWidth = result
    end
    if inputStr == "height" then
        dataobject.__cachedHeight = result
    end
    --if x or y, make it movve around the top left
    -- if theres a parent, also factor the parent position and scale
    if inputStr == "x" then
        local selfWidth = self:getWidth(dataobject)
        --bring it to left
        result = result + selfWidth / 2

        if dataobject.halign == "center" then
            --shift it to center (width/2)
            result = result - selfWidth / 2
        end
        if dataobject.halign == "right" then
            --shift it to right
            result = result - selfWidth
        end
        if dataobject.parent then
            result = result + refferenceX - refferenceWidth / 2
        end
        dataobject.__cachedX = result
    end
    if inputStr == "y" then
        local selfHeight = self:getHeight(dataobject)
        --bring it to top
        result = result + selfHeight / 2
        if dataobject.valign == "center" then
            --shift it to center (height/2)
            result = result - selfHeight / 2
        end
        if dataobject.valign == "bottom" then
            --shift it to bottom
            result = result - selfHeight
        end

        if dataobject.parent then
            result = result + refferenceY - refferenceHeight / 2
        end
        dataobject.__cachedY = result
    end
    return result
end

function Lovr2d:getX(data)
    return self:DynamicResizeProperty(data, "x", "x")
end

function Lovr2d:getY(data)
    return self:DynamicResizeProperty(data, "y", "y")
end

function Lovr2d:getWidth(data)
    return self:DynamicResizeProperty(data, "width", "x")
end

function Lovr2d:getHeight(data)
    return self:DynamicResizeProperty(data, "height", "y")
end

function Lovr2d:setupRotation(data)
    if data.parent then
        local rotationParent = data.parent.rotation
        local ScaleParent = data.parent.scale
        local selfRotation = data.rotation
        local selfScale = data.scale

        --edge case in case bboth parent and children are functions
        local combinedRotation = function()
            local parentR = type(rotationParent) == "function" and rotationParent() or rotationParent
            local selfR = type(selfRotation) == "function" and selfRotation() or selfRotation
            return selfR + parentR
        end
        local combinedScale = function()
            local parentS = type(ScaleParent) == "function" and ScaleParent() or ScaleParent
            local selfS = type(selfScale) == "function" and selfScale() or selfScale

            return parentS * selfS
        end
        data.rotation = combinedRotation
        data.scale = combinedScale
    end
    --in case you need it!
    data.cache = self.copy(data)
end

function Lovr2d:sendToFront(obj)
    --this works the same as delete with a dif rule at end
    local cleanedQueue = {}
    local moveToFrontArray = {}
    for index, element in ipairs(self.drawQueue) do
        if element.parent then
            if element.parent == obj then
                element.markForSendToFront = true
                table.insert(moveToFrontArray, element)
            end
        end
    end
    --if its not the marked children or the parent , make a clean array
    for index, element in ipairs(self.drawQueue) do
        if not element.markForSendToFront and element ~= obj then
            cleanedQueue[#cleanedQueue + 1] = element
        end
    end
    --first add the parent to the top of the list
    cleanedQueue[#cleanedQueue + 1] = obj
    -- then the children
    for index, element in ipairs(moveToFrontArray) do
        element.markForSendToFront      = false
        cleanedQueue[#cleanedQueue + 1] = element
    end

    self.drawQueue = cleanedQueue
end

function Lovr2d:updateHitTests(object)
    if object.onLeftClick or object.onMouseOver or object.onMouseOut or object.drag or object.onRightClick then
        if self.hitTest(object) then
            --Highlight for visuals assign
            if self.firstSelectedButton == nil then
                self.firstSelectedButton = object
            end

            if object.onMouseOver then
                if object._mouseOver == false then
                    object._mouseOver = true
                    object.onMouseOver(object)
                end
            end
            if self.leftClick then
                if object.dragProps.sendToFront then
                    self:sendToFront(object)
                end
                self.CACHELeftMouseUp = -1
                self.CACHELeftMousedown = self.CACHELeftMousedown + 1
                if self.CACHELeftMousedown == 0 then
                    if object.drag then
                        self.activelyDragging = object
                    end
                    if object.onLeftClick then
                        if type(object.onLeftClick) == "function" then
                            object.onLeftClick(object)
                        else
                            print("LOVR2d: " .. tostring(object.onLeftClick))
                        end
                    end
                    if object.drag then --setup innitial offset for drag
                        object._offsetX = self.mouseX - object.x
                        object._offsetY = self.mouseY - object.y
                    end
                end
            elseif self.rightClick then
                self.CACHERightMousedown = self.CACHERightMousedown + 1
                if object.onRightClick and object.CACHERightMousedown == 0 then
                    object.onRightClick()
                end
            else
                self.CACHELeftMouseUp = self.CACHELeftMouseUp + 1
                if self.CACHELeftMouseUp == 0 and self.CACHELeftMousedown ~= -1 then
                    if object.onLeftClickRelease then
                        object.onLeftClickRelease(object)
                    end
                end
                self.CACHELeftMousedown = -1
                object.CACHERightMousedown = -1
            end
        else
            --if youve had been highlighting the object , stop it
            if object._mouseOver then
                object._mouseOver = false
                if object.onMouseOut then
                    object.onMouseOut(object)
                end
            end
        end
    end
end

function Lovr2d:setProjection()
    self.projection = lovr.math.mat4():orthographic(0, self.width, 0, self.height, -20, 20)
    self.pass:setProjection(1, self.projection)
    self.pass:setViewPose(1, lovr.math.mat4():identity())
    self.pass:setDepthTest()
end

function Lovr2d:setPass(pass, zSorting)
    self.pass = pass
    self.pass:setFont(self.font or lovr.graphics.getDefaultFont())
    self.font:setPixelDensity(self.fontDensity)
    self:setProjection() --initialize camera
end

local function markForDeletionRecursive(element, targetParent, level)
    if element == targetParent then
        -- Mark the parent for deletion 
        return true
    elseif element.parent then
        -- Continue checking the parent's parent
        return markForDeletionRecursive(element.parent, targetParent, level + 1)
    end

    return false
end

function Lovr2d:util_delete(obj)
    local cleanedQueue = {}
    for index, element in ipairs(self.drawQueue) do
    
        if element == obj then --mark parent for deletion
            element.markedForDelete = true
        else 
            if markForDeletionRecursive(element, obj, 0) then
                -- Mark the current element for deletion
                element.markedForDelete = true
            end
        end
    end
    --make a new , cleaned queue , free of marked objects
    for index, element in ipairs(self.drawQueue) do
        if not element.markedForDelete then
            cleanedQueue[#cleanedQueue + 1] = element
        end
    end
    self.drawQueue = cleanedQueue
end

function Lovr2d:delete(obj)
    if type(obj) == "table" then
        if obj.uiElement ~= true then
            --array mode, it not having a ui element suggests it's not a class of ui
            --so loop trough it
            for index, value in ipairs(obj) do
                Lovr2d:util_delete(value)
            end
        else
            --straight delete mode
            Lovr2d:util_delete(obj)
        end
    end
end

function Lovr2d:text(data)
    if data.valign_text == "center" then data.valign_text = "middle" end
    data.width = data.width or 0
    data.height = data.height or 0
    local data = Lovr2d:_backupVariables(data)

    data.type = "text"
    Lovr2d:setupRotation(data)
    table.insert(self.drawQueue, data)
    return data
end

--get a list of child objects for any modification
--@parent object, include parent bool
function Lovr2d:getChildren(parent, andParent)
    local children = andParent and { parent } or {}

    for index, element in ipairs(self.drawQueue) do
        if element.parent then
            if element.parent == parent then
                table.insert(children, element)
            end
        end
    end
    return children
end

function Lovr2d:updateChildren(parent)
    for index, element in ipairs(self.drawQueue) do
        if element.parent then
            if element.parent == parent then 
                local difX = parent.cache.x - parent.x
                local difY = parent.cache.y - parent.y
                element.x = element.cache.x - difX
                element.y = element.cache.y + -difY
            end
        end
    end
end

function Lovr2d:_backupVariables(data)
    local variables = {
        text = "fillerText",
        x = 0,
        y = 0,
        scale = 1,
        scaleX = 1,
        scaleY = 1,
        flipX = 1,

        angle = 0,
        ax = 0,
        ay = 1,
        az = 0,
        wrap = 0,
        opacity = 1,
        width = 200,
        height = 200,
        zIndex = 1,
        radius = 20,
        angleStart = 0,
        angleEnd = 360,
        segments = 64,
        rotation = 0,
        static = true,
        stroke = 0,
        strokeColor = "#FF00FF",
        color = "#FFFFFF",
        halign = "left",
        valign = "top",
        halign_text = "left",
        font = "default",
        thickness = 0,
        valign_text = "top",
        drag = false,
        dragProps = {
            sendToFront = false,
            limits = { left = 0, top = 0, right = lovr.system.getWindowWidth(), bottom = lovr.system.getWindowHeight() }
        },
        z = 0,
        texture = nil,
        uiElement = true,
        _mouseOver = false

    }
    local dataUpdated = self.setupBackupValues(data, variables)

    --do a follow up check for string types for these variables
    data.str = {}
    if type(data.x) == "string" then data.str.x = data.x end
    if type(data.y) == "string" then data.str.y = data.y end
    if type(data.width) == "string" then data.str.width = data.width end
    if type(data.height) == "string" then data.str.height = data.height end

    -- if type(data.y)=="string" then
    --     print('')
    -- end


    return dataUpdated
end

function Lovr2d:box(data)
    --backup variables
    local data = Lovr2d:_backupVariables(data)

    --assignment

    Lovr2d:setupRotation(data)

    data.type = "rect"



    table.insert(self.drawQueue, data)

    --in case you need them!
    return data
end

function Lovr2d:circle(data)
    --backup variables
    local data = Lovr2d:_backupVariables(data)

    --assignment

    Lovr2d:setupRotation(data)
    data.type = "circle"


    table.insert(self.drawQueue, data)

    --in case you need them!
    return data
end

function Lovr2d:roundedBox(data)
    --backup variables
    local data = Lovr2d:_backupVariables(data)

    --assignment

    Lovr2d:setupRotation(data)
    data.type = "roundedRect"


    table.insert(self.drawQueue, data)

    --in case you need them!
    return data
end

function Lovr2d:button(data)
    local newBox = nil

    data.button = true
    local text = data.text --small cache
    if data.texture then
        newBox = self:image(data)
    else
        if data.roundness then
            newBox = self:roundedBox(data)
        else
            newBox = self:box(data)
        end
    end
    if text then
        Lovr2d:text({
            text = data.text,
            zIndex = data.zIndex,
            halign_text = "center",
            valign_text = "center",
            x = "50%",
            y = "50%",
            parent = newBox,
            color = data.textColor or "#FFFFFF",
        })
    end



    return newBox
end

function Lovr2d:image(data)
    --string check , so you can skip newTexture
    if type(data.texture) == "string" then
        data.texture = lovr.graphics.newTexture(data.texture, nil)
    end

    --failsafe, if texture doesnt exist, image doesnt exist or bad data is supplied
    if tostring(data.texture) == "Texture" then
        local textureWidth, textureHeight = data.texture:getDimensions()
        data.width = data.width or textureWidth
        data.height = data.height or textureHeight
    else
        print("LOVR2d: No texture type supplied!")
    end
    --convert to material
    --backup variables
    local data = Lovr2d:_backupVariables(data)

    -- data.material = lovr.graphics.newMaterial({uvScale= {-1, 1}, texture= data.texture})
    Lovr2d:setupRotation(data)


    data.type = "image"
    table.insert(self.drawQueue, data)
    return data
end

--creates a rounded rectangle based around roudness
function Lovr2d:roundedRect(pass, data)
    local dataX, dataY          = self:getX(data), self:getY(data)
    local dataWidth, dataHeight = self:getWidth(data), self:getHeight(data)
    local edgeSize              = dataWidth * (data.roundness or 0.2)
    local mainSize              = dataWidth - edgeSize * 2
    --[[
    TODO , at this point scalex and scaley only work for rounded rect
    should make it work for everything , also how do i make it not scale from center


]]
    local scaleX = type(data.scaleX) == "function" and data.scaleX() or data.scaleX
    local scaleY = type(data.scaleY) == "function" and data.scaleY() or data.scaleY

    --can work with these 2 v and also make it scale from center or right
    local scaleXOffset = -dataWidth * (1 - scaleX) / 2
    local scaleYOffset = -dataHeight * (1 - scaleY) / 2
    --main

    --pass:translate(scaleXOffset, scaleYOffset, 0)
    --self.pass:scale(scaleX, scaleY, 1)
    pass:roundrect(vec3(0), dataWidth, dataHeight, 0, 0, 0, 0, 0, data.roundness)

    -- self.pass:scale(1 / scaleX, 1 / scaleY, 1)
    --pass:translate(-scaleXOffset, -scaleYOffset, 0)
end

--Thanks Bjorn!

--https://gist.github.com/bjornbytes/9dff2fa0da06db18574a81535a2c0ee0
Lovr2d.fontShader = lovr.graphics.newShader('unlit', [[
    float screenPxRange() {
      vec2 screenTexSize = vec2(1.) / fwidth(UV);
      return max(.5 * dot(Material.sdfRange, screenTexSize), 1.);
    }

    float median(float r, float g, float b) {
      return max(min(r, g), min(max(r, g), b));
    }

    Constants {
      float strokeWidth;
    };

    vec4 lovrmain() {
      vec3 msdf = getPixel(ColorTexture, UV).rgb;
      float sdf = median(msdf.r, msdf.g, msdf.b);
      float screenPxDistance = screenPxRange() * (sdf - .5) + strokeWidth;
      float alpha = clamp(screenPxDistance + .5, 0., 1.);
      if (alpha <= 0.) discard;
      return vec4(Color.rgb, Color.a * alpha);
    }
  ]])
