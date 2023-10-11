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

lovr2d = Object:extend()

function lovr2d:new()
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

    --utility function to create cache system
    self.setupBackupValues = function(inData, values)
        local inData = inData or {}
        local outData = inData
        for index, value in pairs(values) do
            outData[index] = inData[index] or value
        end
        return outData
    end
    self.hitTest = function(data)
        if self.activelyDragging then return nil end

        local mx, my = self.mouseX, self.mouseY
        local tempX  = data.x - data.width / 2
        local tempY  = data.y - data.height / 2
        local over   = mx > tempX and mx < tempX + data.width and my > tempY and my < tempY + data.height
        return over
    end
    self.MouseDoesntOverlapUI = function()
        local notOverlapping = true
        for _, UIItem in ipairs(InfoTable.UI.overlappingItems) do
            if lovr2d.hitTest(UIItem) then
                notOverlapping = false
                break
            end
        end
        return notOverlapping
    end

    self.font = lovr.graphics.getDefaultFont()
    --self.westernFont = lovr.graphics.newFont("assets/fonts/Wellfleet-Regular.ttf", 18)
    --  self.FontInterBlack = lovr.graphics.newFont("assets/fonts/Inter/Inter-Black.ttf", 14)
    --self.font:setPixelDensity(1) -- set units to pixels instead of meters
    self.defaultFont = self.font
    self.defaultFont:setPixelDensity(1) --Sets scaling to pixel size

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
        -- CleanNils()
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
        -- -- Remove the 'index' property from each element
        -- for _, element in ipairs(self.drawQueue) do
        --     element.index = nil
        -- end
    end
    self.draw = function(pass)
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
            --scales object from data.scaleX , scaleY (only from top left atm )
            local scaleX = type(data.scaleX) == "function" and data.scaleX() or data.scaleX
            local scaleY = type(data.scaleY) == "function" and data.scaleY() or data.scaleY

            if data.type == "image" then
                self.pass:push()
                self.pass:setMaterial(data.texture)
                self.pass:transform(data.x, data.y, data.z)
                --self.pass:transform(data.width / 2, data.height / 2, 0)
                self.pass:rotate(math.pi, 0, 0, 1)
                local color = self.hex2rgb(data.color)
                self.pass:setColor(color[1], color[2], color[3], data.opacity)
                self.pass:plane(lovr.math.vec3(0), data.width, data.height)
                self.pass:setMaterial()
                --Top Space
                self.pass:pop()
            elseif data.type == "rect" then
                local pos3D = lovr.math.vec3(data.x, data.y, data.z)
                if data.id == "testbutton" then
                end
                local colorToShow = data.color

                if type(data.color) == "function" then colorToShow = data.color() end
                local color = self.hex2rgb(colorToShow)
                self.pass:setColor(color[1], color[2], color[3], data.opacity)


                self.pass:plane(pos3D, data.width, data.height)
            elseif data.type == "roundedRect" then
                local pos3D = lovr.math.vec3(data.x, data.y, data.z)
                if data.id == "testbutton" then
                end
                local colorToShow = data.color
                if type(data.color) == "function" then colorToShow = data.color() end
                local color = self.hex2rgb(colorToShow)
                self.pass:setColor(color[1], color[2], color[3], data.opacity)
                --self.pass:scale(scaleX, scaleY, 1)
                self:roundGeometry(self.pass, data)
                -- self.pass:scale(1 / scaleX, 1 / scaleY, 1)
            elseif data.type == "text" then
                --fail safe in case  you wanna do live updated text
                local textToShow = data.text
                if type(data.text) == "function" then textToShow = data.text() end
                local color = self.hex2rgb(data.color)
                self.pass:setColor(color[1], color[2], color[3], data.opacity)
                self.pass:text(textToShow,
                    data.x, data.y, data.z,
                    data.scale, data.angle,
                    data.ax,
                    data.ay,
                    data.az,
                    data.wrap,
                    data.halign_text,
                    data.valign_text
                )
            end



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
            if limit == nil then  --failsafe
                limit ={ left = 0, top = 0, right = lovr.system.getWindowWidth(), bottom = lovr.system.getWindowHeight() }

            end
            dragObj.x =  self.clamp(dragObj.x, limit.left + dragObj.width / 2, limit.right - dragObj.width / 2)
            dragObj.y =  self.clamp(dragObj.y, limit.top + dragObj.height / 2, limit.bottom - dragObj.height / 2)
            self:updateChildren(dragObj)
        end

        --Highlight for Buttons Visual
        if self.firstSelectedButton then
            self.pass:setColor(1, 1, 1, 0.2)
            if self.firstSelectedButton.roundness then
                local data = self.firstSelectedButton
                self:roundGeometry(self.pass, data)
            else
                self.pass:plane(self.firstSelectedButton.x, self.firstSelectedButton.y, self.firstSelectedButton.z,
                    self.firstSelectedButton.width, self.firstSelectedButton.height)
            end
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
        hex = hex:gsub("#", "")
        return {
            tonumber("0x" .. hex:sub(1, 2)) / 255,
            tonumber("0x" .. hex:sub(3, 4)) / 255,
            tonumber("0x" .. hex:sub(5, 6)) / 255
        }
    end


    return self
end

function lovr2d:_util_align(data)
    local parent_or_stage_width = self.info.stageWidth
    local parent_or_stage_height = self.info.stageHeight

    if data.parent then
        parent_or_stage_width = data.parent.width
        parent_or_stage_height = data.parent.height
        --   data.y= data.y + data.parent.y
    end
    --halignment
    if data.halign == "left" then
        data.x = data.x + data.width / 2
    end
    if data.halign == "right" then
        data.x = parent_or_stage_width - (data.width - data.width / 2 - data.x)
    end
    if data.halign == "center" then
        data.x = parent_or_stage_width / 2 + (data.x)
    end
    if data.valign == "top" then
        data.y = data.y + data.height / 2
    end
    if data.valign == "bottom" then
        data.y = parent_or_stage_height - (data.height - data.height / 2 - data.y)
    end
    if data.valign == "center" then
        data.y = parent_or_stage_height / 2 + (data.y)
    end

    --in case you need it!
    data.cache = self.copy(data)

    data._initX = data.x
    data._initY = data.y
end

function lovr2d:sendToFront(obj)
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

function lovr2d:updateHitTests(object)
    -- if object.onLeftClick then
    --     print("hi")
    -- end
    if object.onLeftClick or object.drag or object.onRightClick then
        if self.hitTest(object) then
            --Highlight for visuals assign
            if self.firstSelectedButton == nil then
                self.firstSelectedButton = object
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
                        object.onLeftClick(object)
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
        end
    end
end

function lovr2d:setProjection()
    self.projection = lovr.math.mat4():orthographic(0, self.width, 0, self.height, -20, 20)
    self.pass:setProjection(1, self.projection)
    self.pass:setViewPose(1, lovr.math.mat4():identity())
    self.pass:setDepthTest()
end

function lovr2d:setPass(pass, zSorting)
    self.pass = pass
    self.pass:setFont(self.defaultFont or lovr.graphics.getDefaultFont())
    self:setProjection() --initialize camera
end

function lovr2d:util_delete(obj)
    local cleanedQueue = {}
    for index, element in ipairs(self.drawQueue) do
        if element.parent then
            if element.parent == obj then --mark child for deletion
                element.markedForDelete = true
            end
        elseif element == obj then --mark parent for deletion
            element.markedForDelete = true
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

function lovr2d:delete(obj)
    if type(obj) == "table" then
        if obj.uiElement ~= true then
            --array mode, it not having a ui element suggests it's not a class of ui
            --so loop trough it
            for index, value in ipairs(obj) do
                lovr2d:util_delete(value)
            end
        else
            --straight delete mode
            lovr2d:util_delete(obj)
        end
    end
end

function lovr2d:text(data)
    if data.valign_text == "center" then data.valign_text = "middle" end
    data.width = data.width or 0
    data.height = data.height or 0
    local data = lovr2d:_backupVariables(data)

    data.type = "text"
    lovr2d:_util_align(data)
    table.insert(self.drawQueue, data)
    return data
end

--get a list of child objects for any modification
--@parent object, include parent bool
function lovr2d:getChildren(parent, andParent)
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

function lovr2d:updateChildren(parent)
    for index, element in ipairs(self.drawQueue) do
        if element.parent then
            if element.parent == parent then
                element.x = element.cache.x + parent.x - parent.width / 2
                element.y = element.cache.y + parent.y - parent.height / 2
            end
        end
    end
end

function lovr2d:_backupVariables(data)
    local variables = {
        text = "fillerText",
        x = 0,
        y = 0,
        scale = 1,
        scaleX = 1,
        scaleY = 1,
        angle = 0,
        ax = 0,
        ay = 1,
        az = 0,
        wrap = 0,
        opacity = 1,
        width = 200,
        height = 200,
        zIndex = 1,
        color = "#FFFFFF",
        halign = "left",
        valign = "top",
        halign_text = "left",
        valign_text = "top",
        drag = false,
        dragProps = {
            sendToFront = false,
            limits = { left = 0, top = 0, right = lovr.system.getWindowWidth(), bottom = lovr.system.getWindowHeight() }
        },
        z = 0,
        texture = nil,
        uiElement = true

    }
    local dataUpdated = self.setupBackupValues(data, variables)

    if dataUpdated.parent then
        dataUpdated.x = dataUpdated.x + dataUpdated.parent.x - dataUpdated.parent.width / 2
        dataUpdated.y = dataUpdated.y + dataUpdated.parent.y - dataUpdated.parent.height / 2
    end


    return dataUpdated
end

function lovr2d:box(data)
    --backup variables
    local data = lovr2d:_backupVariables(data)

    --assignment

    lovr2d:_util_align(data)
    data.type = "rect"
    data.z = data.z



    table.insert(self.drawQueue, data)

    --in case you need them!
    return data
end

function lovr2d:roundedBox(data)
    --backup variables
    local data = lovr2d:_backupVariables(data)

    --assignment

    lovr2d:_util_align(data)
    data.type = "roundedRect"
    data.z = data.z


    table.insert(self.drawQueue, data)

    --in case you need them!
    return data
end

function lovr2d:button(data)
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
        lovr2d:text({
            text = data.text,
            zIndex = data.zIndex,
            halign_text = "center",
            valign_text = "center",
            halign = "center",
            valign = "center",
            parent = newBox,
            color = data.textColor or "#FFFFFF",
        })
    end



    return newBox
end

function lovr2d:image(data)
    --backup variables
    local data = lovr2d:_backupVariables(data)
    lovr2d:_util_align(data)

    data.z = data.z

    data.type = "image"
    table.insert(self.drawQueue, data)
    return data
end

--creates a rounded rectangle based around roudness
function lovr2d:roundGeometry(pass, data)
    local edgeSize = data.width * (data.roundness or 0.2)
    local mainSize = data.width - edgeSize * 2
    --[[
    TODO , at this point scalex and scaley only work for rounded rect
    should make it work for everything , also how do i make it not scale from center


]]
    local scaleX = type(data.scaleX) == "function" and data.scaleX() or data.scaleX
    local scaleY = type(data.scaleY) == "function" and data.scaleY() or data.scaleY

    --can work with these 2 v and also make it scale from center or right
    local scaleXOffset = -data.width * (1 - scaleX) / 2
    local scaleYOffset = -data.height * (1 - scaleY) / 2
    --main

    pass:translate(data.x + scaleXOffset, data.y + scaleYOffset, data.z)
    self.pass:scale(scaleX, scaleY, 1)
    pass:plane(vec3(0), mainSize, data.height)
    --righht
    pass:circle(data.width / 2 - edgeSize, -data.height / 2 + edgeSize, 0, edgeSize, 0, 0, 0,
        0, "fill", -math.pi / 2, 0, 4)
    pass:plane(data.width / 2 - edgeSize / 2, 0, 0, edgeSize, data.height - edgeSize * 2, 0, 0, 0,
        0, "fill")
    pass:circle(data.width / 2 - edgeSize, data.height / 2 - edgeSize, 0, edgeSize, 0, 0, 0,
        0, "fill", 0, math.pi / 2, 4)
    --left
    pass:circle(-mainSize / 2, -data.height / 2 + edgeSize, 0, edgeSize, 0, 0, 0, 0, "fill",
        -math.pi, -math.pi / 2, 4)
    pass:plane(-mainSize / 2 - edgeSize / 2, 0, 0, edgeSize, data.height - edgeSize * 2, 0, 0, 0,
        0, "fill")

    pass:circle(-mainSize / 2, data.height / 2 - edgeSize, 0, edgeSize, 0, 0, 0, 0, "fill"
    , math.pi / 2, math.pi, 4)
    self.pass:scale(1 / scaleX, 1 / scaleY, 1)
    pass:translate(-data.x - scaleXOffset, -data.y - scaleYOffset, -data.z)
end
