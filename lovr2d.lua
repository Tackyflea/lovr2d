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

Lovr2d = { Object:extend() }

local font, fonts, fontShader = nil, {}, nil

--optimization, making things local
local l_type = type
local l_print = function(v) print("Lovr2d: " .. v) end
local mathRad = math.rad
local pi = math.pi
local mathMax = math.max
local mathMin = math.min
local worldWidth, worldHeight
local updateX, updateY, updateWidth, updateHeight, DynamicResizeProperty

--Shader
--Thanks Bjorn!

--https://gist.github.com/bjornbytes/9dff2fa0da06db18574a81535a2c0ee0
fontShader = lovr.graphics.newShader('unlit', [[
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

--Start
function Lovr2d.new(instance)
    instance = {} -- create object if user does not provide one


    worldWidth, worldHeight          = lovr.system.getWindowDimensions()

    instance.pass                    = nil --to be filled later
    instance.activelyDragging        = nil
    instance.firstSelectedButton     = nil --Highlight for visuals

    instance.leftClick               = lovr.mouse.isDown(1)
    instance.rightClick              = lovr.mouse.isDown(2)

    instance.mouseChangeOnRollOver   = true -- physical lovr mouse change

    --cache values to cancel events
    instance.CACHELeftMousedown      = -1
    instance.CACHELeftMouseUp        = -1
    instance.CACHERightMousedown     = -1

    instance.mouseX, instance.mouseY = 0, 0

    --max depth for parenting
    instance.depthMax                = 5

    instance.drawQueue               = {}
    instance.cachedDrawQueueL        = 0
    instance.font                    = nil
    instance.fonts                   = {}
    instance.masks                   = {}

    --for masking and position tweaks
    instance.maxParentsCheck         = 4

    --Overwrite the default wheel behaviour to allow a local hook
    instance.wheelMoved              = function(dx, dy)
        --activate scroll action if mouse is over the object
        for k, object in pairs(instance.drawQueue) do
            if object.onScroll then
                if instance.hitTest(object) then
                    object.onScroll(dx, dy)
                end
            end
        end
    end

    --utility function to create cache system
    instance.setupBackupValues       = function(inData, values)
        local inData = inData or {}
        local outData = inData
        for index, value in pairs(values) do
            outData[index] = inData[index] or value
        end
        return outData
    end

    --Backup for all objects
    instance._backupVariables        = function(data)
        data = data or {}
        local variables = {
            text = "fillerText",
            x = 0,
            y = 0,
            adjust = { x = 0, y = 0, masked = false }, --for manual adjustment if necesary
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
            color = "#FFFFFF",
            halign = "left",
            valign = "top",
            halign_text = "left",
            font = "default",
            thickness = 0,
            valign_text = "top",
            masked = false,
            mask = false,
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
        local dataUpdated = instance.setupBackupValues(data, variables)

        --do a follow up check for string types for these variables
        data.str = {}
        if l_type(data.x) == "string" then data.str.x = data.x end
        if l_type(data.y) == "string" then data.str.y = data.y end
        if l_type(data.width) == "string" then data.str.width = data.width end
        if l_type(data.height) == "string" then data.str.height = data.height end

        --update masks from parents, if they havent manually been enabled
        if not data.masked then
            data.masked = data.parent and data.parent.masked or false
        end
        --this is to cache the innitial mask for use for children (could be improved )
        data.adjust.masked = data.masked

        --hide masks by default
        if data.mask then
            data.opacity = 0
            --assign mask to relative object,  for multiple mask support
            instance.masks[data.mask] = data
        end

        return dataUpdated
    end

    instance.blockedFromClicking     = false
    --Utility to block all button events
    instance.blockInteraction        = function()
        instance.blockedFromClicking = true
    end

    instance.allowInteraction        = function()
        instance.blockedFromClicking = false
    end
    instance.__isBlocked             = function()
        return instance.blockedFromClicking
    end

    instance.hitTest                 = function(data)
        if instance.activelyDragging then return nil end
        if not data.cached then return end

        local dataX, dataY          = data.cached.x, data.cached.y
        local dataWidth, dataHeight = data.cached.width, data.cached.height
        local mx, my                = instance.mouseX, instance.mouseY
        local tempX                 = dataX - dataWidth / 2
        local tempY                 = dataY - dataHeight / 2
        local over                  = mx > tempX and mx < tempX + dataWidth and my > tempY and my < tempY + dataHeight

        return over
    end
    instance.fonts                   = {
        default = lovr.graphics.getDefaultFont()
    }
    instance.font                    = instance.fonts.default

    --text
    instance.fontDensity             = 1
    instance.font:setPixelDensity(instance.fontDensity)

    --table: url, size
    instance.setFont = function(font)
        instance.font = instance.fonts[font.id] or instance.fonts.default
    end
    --table: id, url, size
    instance.addFont = function(font)
        local spread = font.spread or 1
        instance.fonts[font.id] = lovr.graphics.newFont(font.url, font.size, spread)
        if instance.fonts[font.id] then
            instance.fonts[font.id]:setPixelDensity(instance.fontDensity)
        else
            l_print(" Font not found: " .. font.id)
        end
    end
    instance.liveReloadFont = function(dataFont)
        local font = dataFont or "default"
        local pickedFont = instance.fonts[font]
        if font ~= instance.fonts[font] then
            if not instance.fonts[font] then
                l_print("Font not loaded! Use setFont first!  " .. font)
            else
                font = instance.fonts[font]
                instance.pass:setFont(font)
            end
        end
    end
    instance.drawQueue = {}
    instance.cachedDrawQueueL = #instance.drawQueue
    instance.clear = function()
        instance.drawQueue = {}
        instance.cachedDrawQueueL = #instance.drawQueue
    end

    instance.zSort = function()
        --if something's changed in the draw queue lenght , ie we added something new
        --re sort the array based off z index
        instance.cachedDrawQueueL = #instance.drawQueue
        -- Populate the indexOf table
        for i, element in ipairs(instance.drawQueue) do
            element.index = i
        end
        table.sort(instance.drawQueue, function(a, b)
            if a.zIndex == b.zIndex then
                -- If the zIndex values are the same, compare the indices
                return a.index < b.index
            else
                -- Otherwise, compare the zIndex values directly
                return a.zIndex < b.zIndex
            end
        end)
    end

    --cap fps for ui
    instance.fps = 30 -- frames a second
    instance.tickPeriod = 1 / instance.fps
    instance.accumulator = 0.0

    instance.draw = function(pass)
        instance.accumulator = instance.accumulator + lovr.timer.getDelta()

        instance.inCappedFPS = false

        if instance.accumulator >= instance.tickPeriod then
            instance.inCappedFPS = true
            -- Here be your fixed timestep.
            -- print("hi")
            instance.accumulator = instance.accumulator - instance.tickPeriod
        end


        instance.drawBody(pass)
    end


    instance.drawBody = function(pass)
        prof.push("l2d_predraw")
        instance.CheckAndUpdateWindowSize()

        instance.setPass(pass)
        if not instance.__isBlocked() then
            instance.mouseX, instance.mouseY = lovr.mouse.getPosition()
            instance.leftClick = lovr.mouse.isDown(1)

            instance.rightClick = lovr.mouse.isDown(2)
            if instance.leftClick == false then
                instance.activelyDragging = nil
                instance.firstSelectedButton = nil
            end
            instance.scroll = false
        end

        if instance.cachedDrawQueueL ~= #instance.drawQueue then
            instance.zSort()
        end

        prof.pop("l2d_predraw")
        prof.push("l2d_drawOjects")


        local dataX, dataY, rotation, scale, color, opacity, text, dataWidth, dataHeight
        local processObject = true
        for _, data in pairs(instance.drawQueue) do
            --MASK RESET/SETUP
            -- setStencilTest:none indicates draw everything, which should be the default
            instance.pass:setStencilTest('none', 1)



            if not instance.inCappedFPS and data.cached then
                dataX = data.cached.x
                dataY = data.cached.y
                rotation = data.cached.rotation
                scale = data.cached.scale
                color = data.cached.color
                opacity = data.cached.opacity
                text = data.cached.text
                dataWidth = data.cached.width
                dataHeight = data.cached.height
            else
                --for live updating data

                rotation = l_type(data.rotation) == "function" and data.rotation() or data.rotation
                scale = l_type(data.scale) == "function" and data.scale() or data.scale

                color = instance.hex2rgb(l_type(data.color) == "function" and data.color() or data.color)
                opacity = l_type(data.opacity) == "function" and data.opacity() or data.opacity

                text = l_type(data.text) == "function" and data.text() or data.text
                if not text then
                    text = ""
                    l_print("Text missing ")
                end

                --window percent based data
                dataX      = updateX(data)
                dataY      = updateY(data)
                dataWidth  = updateWidth(data)
                dataHeight = updateHeight(data)

                --final adjustment if necesary by user so we dont need to use flex

                dataX      = dataX + instance.tweak(data, "x")
                dataY      = dataY + instance.tweak(data, "y")

                --[[
                    maybe update the cached less often
                ]]

                data.cached = {
                    x = dataX,
                    y = dataY,
                    rotation = rotation,
                    scale = scale,
                    color = color,
                    opacity = opacity,
                    text = text,
                    width = dataWidth,
                    height = dataHeight
                }
            end
            -- --[[

            -- for masked objects, if they're outside of bounds, dont process them
            -- ]]
            -- --b
            -- local relativeMask = instance.masks[data.masked]
            -- if data.masked and relativeMask then
            --     if data.cached and relativeMask.cached then
            --         local overLimitX = data.cached.width / 2 + data.cached.x > relativeMask.cached.width*1.5 + (relativeMask.cached.x)
            --         local underLimitX = data.cached.x + data.cached.width / 2 < relativeMask.cached.x
            --         local underLimitY = data.cached.y + data.cached.height / 2 < relativeMask.cached.y-relativeMask.cached.height/2
            --         local overLimitY = data.cached.height / 2 + data.cached.y > relativeMask.cached.height*1.5+ (relativeMask.cached.y)

            --         if overLimitX or underLimitX or underLimitY or  overLimitY then
            --             processObject = false
            --         end
            --     end
            -- end
            if processObject then
                -- data.opacity =0
                --start TRS
                --TODO implement Scale
                local pos3D = lovr.math.vec3(dataX, dataY, data.z)
                pass:transform(pos3D)
                pass:rotate(mathRad(rotation), 0, 0, 1)
                instance.pass:scale(scale, scale, 1) --overall scale
                instance.pass:setColor(color[1], color[2], color[3], opacity)

                --[[TODO
                        right now, masked, and mask is an experimental feature
                        allowed only in rect, look into improving it at some point
                ]]
                if data.mask then
                    -- overwrite any previous mask with this one
                    instance.pass:setStencilWrite('replace', 1)
                elseif data.masked then
                    --only show the overlapped with mask parts of the color
                     instance.pass:setStencilTest('==', 1)
                end


                if data.type == "image" then
                    local cheatScaleX = data.cheatScaleX or -1
                    local cheatScaleY = data.cheatScaleY or 1
                    if data.flipX == 1 then
                        instance.pass:setCullMode("back")            --needed so that the images render in reverse
                        instance.pass:scale(vec3(cheatScaleX, cheatScaleY, 1)) --flip X for images
                    end
                    instance.pass:push()
                    local texture = l_type(data.texture) == "function" and data.texture() or data.texture
                    --instance.pass:setColor(1, 1, 1)
                    --   instance.pass:setMaterial(data.material)
                    instance.pass:setMaterial(texture)
                    instance.pass:rotate(pi, 0, 0, 1) --vertical flip
                    
                    instance.pass:scale(data.scaleX, data.scaleY, 1)
                    if data.roundness then
                        pass:roundrect(vec3(0), dataWidth, dataHeight, 0, 0, 0, 0, 0, data.roundness)
                    else
                        instance.pass:plane(vec3(0), dataWidth, dataHeight)
                    end
                   instance.pass:scale(1 / data.scaleX, 1 / data.scaleY, 1)
                    instance.pass:setMaterial()

                    instance.pass:pop()
                    if data.flipX == 1 then
                        instance.pass:setCullMode("front")
                        instance.pass:scale(vec3(1 / cheatScaleX, 1/cheatScaleY, 1)) --undo flip X for images
                    end
                elseif data.type == "rect" then
                    if data.roundness then
                        pass:roundrect(vec3(0), dataWidth, dataHeight, 0, 0, 0, 0, 0, data.roundness)
                    else
                        --todo Stroke is unused, use it
                        instance.pass:plane(vec3(0), dataWidth, dataHeight)
                    end
                elseif data.type == "circle" then
                    pass:circle(vec3(0), data.radius, 0, 0, 0, 0, "fill", data.angleStart * (pi / 180),
                        data.angleEnd * (pi / 180), data.segments)
                elseif data.type == "roundedRect" then
                    --instance.pass:scale(scaleX, scaleY, 1)
                    pass:roundrect(vec3(0), dataWidth, dataHeight, 0, 0, 0, 0, 0, data.roundness)
                    -- instance.pass:scale(1 / scaleX, 1 / scaleY, 1)
                elseif data.type == "text" then
                    --fail safe in case  you wanna do live updated text
                    instance.pass:setShader(fontShader)
                    --range 0-1
                    instance.pass:send('strokeWidth', (data.thickness) * 16)
                    instance.liveReloadFont(data.font)
                    --instance.setFont(font)
                    instance.pass:text(text,
                        vec3(0),
                        scale, data.angle,
                        data.ax,
                        data.ay,
                        data.az,
                        data.wrap,
                        data.halign_text,
                        data.valign_text
                    )
                    instance.pass:setShader()
                end

                -- instance.pass:setShader()
                instance.pass:scale(1 / scale, 1 / scale, 1) --overall scale
                pass:rotate(mathRad(-rotation), 0, 0, 1)
                pass:transform(-pos3D)


                --we use the invert of the array to check from nearest to mouse to end
                --this way it ray intersects cosest instead of lowest
                local reversedPosition = instance.cachedDrawQueueL - _ + 1
                local interactable = instance.drawQueue[reversedPosition]
                if interactable then
                    instance.updateHitTests(interactable)
                end
            end
            --reset counter
            processObject = true
        end

        prof.pop("l2d_drawOjects")
        prof.push("l2d_postdraw")
        -- The stencil state will reset at the end of this lovr.draw, but let's clear it anyway.
        instance.pass:setStencilWrite()
        instance.pass:setStencilTest()

        -- instance.pass:setColor(1, 1, 1, 0.2)
        -- instance.pass:plane(button.x, button.y, button.z, button.width, button.height)
        --the dragging happens seperately , so we dont contantly hit check while dragging
        if instance.activelyDragging then
            local dragObj = instance.activelyDragging
            if dragObj.onDrag then
                dragObj.onDrag(dragObj)
            end

            dragObj.x = (instance.mouseX - dragObj._offsetX)
            dragObj.y = (instance.mouseY - dragObj._offsetY)

            --clamp the dragging to roots limits
            local limit = dragObj.dragProps.limits
            if limit == nil then --failsafe
                limit = { left = 0, top = 0, right = lovr.system.getWindowWidth(), bottom = lovr.system.getWindowHeight() }
            end
            dragObj.x = instance.clamp(dragObj.x, limit.left + dragObj.width / 2, limit.right - dragObj.width / 2)

            dragObj.y = instance.clamp(dragObj.y, limit.top + dragObj.height / 2, limit.bottom - dragObj.height / 2)
            instance.updateChildren(dragObj)
        end
        prof.pop("l2d_postdraw")
    end

    instance.updateChildren = function(parent)
        for index, element in ipairs(instance.drawQueue) do
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

    -- utility function
    instance.copy = function(obj, seen)
        local s = {}
        for k, v in pairs(obj) do
            s[k] = v
        end
        return s
    end
    instance.clamp = function(value, min, max)
        return mathMax(mathMin(value, max), min)
    end
    instance.hex2rgb = function(hex)
        --in case you want to use straight table
        if l_type(hex) == "table" then
            return hex
        end
        if l_type(hex) == "number" then
            return { hex, hex, hex }
        end
        hex = hex:gsub("#", "")
        return {
            tonumber("0x" .. hex:sub(1, 2)) / 255,
            tonumber("0x" .. hex:sub(3, 4)) / 255,
            tonumber("0x" .. hex:sub(5, 6)) / 255
        }
    end

    instance.CheckAndUpdateWindowSize = function()
        local newWidth, newHeight = lovr.system.getWindowDimensions()
        local widthChanged = worldWidth ~= newWidth
        local heightChanged = worldHeight ~= newHeight
        if widthChanged or heightChanged then
            worldWidth = newWidth
            worldHeight = newHeight
        end
    end

    instance.setupRotation = function(data)
        if data.parent then
            local rotationParent = data.parent.rotation
            local ScaleParent = data.parent.scale
            local selfRotation = data.rotation
            local selfScale = data.scale

            --edge case in case bboth parent and children are functions
            local combinedRotation = function()
                local parentR = l_type(rotationParent) == "function" and rotationParent() or rotationParent
                local selfR = l_type(selfRotation) == "function" and selfRotation() or selfRotation
                return selfR + parentR
            end
            local combinedScale = function()
                local parentS = l_type(ScaleParent) == "function" and ScaleParent() or ScaleParent
                local selfS = l_type(selfScale) == "function" and selfScale() or selfScale

                return parentS * selfS
            end
            data.rotation = combinedRotation
            data.scale = combinedScale
        end
        --in case you need it!
        data.cache = instance.copy(data)
    end

    --get a list of child objects for any modification
    --@parent object, include parent bool
    instance.getChildren = function(parent, andParent)
        local children = andParent and { parent } or {}


        for index, element in ipairs(instance.drawQueue) do
            if element.parent then
                if element.parent == parent then
                    table.insert(children, element)
                end
            end
        end
        return children
    end

    --Deletion
    instance.markForDeletionRecursive = function(element, targetParent, level)
        if element == targetParent then
            -- Mark the parent for deletion
            return true
        elseif element.parent then
            -- Continue checking the parent's parent
            return instance.markForDeletionRecursive(element.parent, targetParent, level + 1)
        end

        return false
    end
    instance.util_delete = function(obj)
        local cleanedQueue = {}
        for index, element in ipairs(instance.drawQueue) do
            if element == obj then --mark parent for deletion
                element.markedForDelete = true
            else
                if instance.markForDeletionRecursive(element, obj, 0) then
                    -- Mark the current element for deletion
                    element.markedForDelete = true
                end
            end
        end
        --make a new , cleaned queue , free of marked objects
        for index, element in ipairs(instance.drawQueue) do
            if not element.markedForDelete then
                cleanedQueue[#cleanedQueue + 1] = element
            end
        end
        instance.drawQueue = cleanedQueue
    end

    instance.delete = function(obj)
        if l_type(obj) == "table" then
            if obj.uiElement ~= true then
                --array mode, it not having a ui element suggests it's not a class of ui
                --so loop trough it
                for index, value in ipairs(obj) do
                    instance.util_delete(value)
                end
            else
                --straight delete mode
                instance.util_delete(obj)
            end
        end
    end

    instance.sendToFront = function(obj)
        --this works the same as delete with a dif rule at end
        local cleanedQueue = {}
        local moveToFrontArray = {}
        for index, element in ipairs(instance.drawQueue) do
            if element.parent then
                if element.parent == obj then
                    element.markForSendToFront = true
                    table.insert(moveToFrontArray, element)
                end
            end
        end
        --if its not the marked children or the parent , make a clean array
        for index, element in ipairs(instance.drawQueue) do
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

        instance.drawQueue = cleanedQueue
    end

    instance.updateHitTests = function(object)
        if object.onLeftClick or object.onMouseOver or object.onMouseOut or object.drag or object.onRightClick then
            if instance.hitTest(object) then
                if object.masked then
                    local maskObject = instance.masks[object.masked]
                    if maskObject then
                        if maskObject.cached then
                            --only hit test a masked object if within the area of maskign
                            local overLimit = object.cached.y >
                                maskObject.cached.height + (maskObject.cached.y - maskObject.cached.height / 2)
                            local underLimit = object.cached.y < (maskObject.cached.y - maskObject.cached.height / 2)
                            if overLimit or underLimit then
                                return
                            end
                        end
                    end
                end
                --Highlight for visuals assign
                if instance.firstSelectedButton == nil then
                    instance.firstSelectedButton = object
                end
                if object.onMouseOver then
                    -- lovr.mouse.setCursor(lovr.mouse.getSystemCursor("hand"))
                    if object._mouseOver == false then
                        object._mouseOver = true
                        object.onMouseOver(object)

                        if instance.mouseChangeOnRollOver then
                            lovr.mouse.setCursor(lovr.mouse.getSystemCursor("hand"))
                        end
                    end
                end
                if instance.leftClick then
                    if object.dragProps.sendToFront then
                        instance.sendToFront(object)
                    end
                    instance.CACHELeftMouseUp = -1
                    instance.CACHELeftMousedown = instance.CACHELeftMousedown + 1
                    if instance.CACHELeftMousedown == 0 then
                        if object.drag then
                            instance.activelyDragging = object
                        end
                        if object.onLeftClick then
                            if l_type(object.onLeftClick) == "function" then
                                object.onLeftClick(object)
                            else
                                l_print(tostring(object.onLeftClick))
                            end
                        end
                        if object.drag then --setup innitial offset for drag
                            object._offsetX = instance.mouseX - object.x
                            object._offsetY = instance.mouseY - object.y
                        end
                    end
                elseif instance.rightClick then
                    instance.CACHERightMousedown = instance.CACHERightMousedown + 1
                    if object.onRightClick and object.CACHERightMousedown == 0 then
                        object.onRightClick()
                    end
                else
                    instance.CACHELeftMouseUp = instance.CACHELeftMouseUp + 1
                    if instance.CACHELeftMouseUp == 0 and instance.CACHELeftMousedown ~= -1 then
                        if object.onLeftClickRelease then
                            object.onLeftClickRelease(object)
                        end
                    end
                    instance.CACHELeftMousedown = -1
                    object.CACHERightMousedown = -1
                end
            else
                --if youve had been highlighting the object , stop it
                if object._mouseOver then
                    object._mouseOver = false
                    if object.onMouseOut then
                        object.onMouseOut(object)
                    end
                    if instance.mouseChangeOnRollOver then
                        lovr.mouse.setCursor(lovr.mouse.getSystemCursor("arrow"))
                    end
                end
            end
        end
    end

    instance.setProjection = function()
        instance.projection = lovr.math.mat4():orthographic(0, worldWidth, 0, worldHeight, -20, 20)
        instance.pass:setProjection(1, instance.projection)
        instance.pass:setViewPose(1, lovr.math.mat4():identity())
        instance.pass:setDepthTest()
    end

    instance.setPass = function(pass, zSorting)
        instance.pass = pass
        instance.pass:setFont(font or lovr.graphics.getDefaultFont())
        instance.font:setPixelDensity(instance.fontDensity)
        instance.setProjection() --initialize camera
    end


    -- instance.resize = function()
    --   print('ui resiz')
    --   for _, data in pairs(instance.drawQueue) do
    --     data.cached = nil
    --   end
    -- end


    DynamicResizeProperty = function(dataobject, inputStr, layout)
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
            end
        end
        --[[
        this takes in strings or numberes , if numbers deals with them straight
        otherwise figure out what type of string it needs
    ]]
        local input = dataobject[inputStr]
        if l_type(input) == "function" then input = input() end
        local typeIsVw                          = string.find(input, '%vw')
        local typeIsVh                          = string.find(input, '%vh')
        local typeIsPerecent                    = string.find(input, '%%')

        -- if dataobject.id=="person" then
        --     print('here')
        -- end
        local refferenceX, refferenceY          = 0, 0

        local refferenceWidth, refferenceHeight = worldWidth, worldHeight
        --use either the parents sizing or the world sizing
        if dataobject.parent then
            refferenceX = updateX(dataobject.parent)
            refferenceY = updateY(dataobject.parent)
            refferenceWidth = updateWidth(dataobject.parent)
            refferenceHeight = updateHeight(dataobject.parent)
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
            local selfWidth = updateWidth(dataobject)
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
            local selfHeight = updateHeight(dataobject)
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

    updateX = function(data) return DynamicResizeProperty(data, "x", "x") end
    updateY = function(data) return DynamicResizeProperty(data, "y", "y") end
    updateWidth = function(data) return DynamicResizeProperty(data, "width", "x") end
    updateHeight = function(data) return DynamicResizeProperty(data, "height", "y") end
    instance.updateX = function(x) return updateX(x) end
    instance.updateY = function(x) return updateY(x) end

    instance.tweak = function(object, prop)
        local ancestors = {}

        local startValue = object.adjust[prop]

        if object.parent then
            local i = 0;
            ancestors[0] = object.parent
            while ancestors[i].parent do
                if i >= instance.maxParentsCheck then
                    break
                end

                startValue = startValue + ancestors[i].parent.adjust[prop]
                -- end
                ancestors[i + 1] = ancestors[i].parent
                i = i + 1
            end
        end
        return startValue
    end
    --Types

    instance.text = function(data)
        if data.valign_text == "center" then data.valign_text = "middle" end
        data.width = data.width or 0
        data.height = data.height or 0
        local data = instance._backupVariables(data)

        data.type = "text"
        instance.setupRotation(data)
        table.insert(instance.drawQueue, data)
        return data
    end

    instance.box = function(data)
        --backup variables
        local data = instance._backupVariables(data)

        --assignment

        instance.setupRotation(data)
        data.type = "rect"
        table.insert(instance.drawQueue, data)

        --in case you need them!
        return data
    end
    instance.circle = function(data)
        --backup variables
        local data = instance._backupVariables(data)

        --assignment
        instance.setupRotation(data)
        data.type = "circle"


        table.insert(instance.drawQueue, data)

        --in case you need them!
        return data
    end

    instance.roundedBox = function(data)
        --backup variables
        local data = instance._backupVariables(data)

        --assignment

        instance.setupRotation(data)
        data.type = "roundedRect"


        table.insert(instance.drawQueue, data)

        --in case you need them!
        return data
    end


    instance.button = function(data)
        local newBox = nil

        data.button = true
        local text = data.text --small cache
        if data.texture then
            newBox = instance.image(data)
        else
            if data.roundness then
                newBox = instance.roundedBox(data)
            else
                newBox = instance.box(data)
            end
        end
        if text then
            instance.text({
                text = data.text,
                zIndex = data.zIndex,
                font = data.font or nil,
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

    instance.image = function(data)
        --string check , so you can skip newTexture
        if l_type(data.texture) == "string" then
            data.texture = lovr.graphics.newTexture(data.texture, nil)
        end

        --failsafe, if texture doesnt exist, image doesnt exist or bad data is supplied
        if tostring(data.texture) == "Texture" then
            local textureWidth, textureHeight = data.texture:getDimensions()
            data.width = data.width or textureWidth
            data.height = data.height or textureHeight
        else
            l_print("No texture type supplied!")
        end
        --convert to material
        --backup variables
        local data = instance._backupVariables(data)

        -- data.material = lovr.graphics.newMaterial({uvScale= {-1, 1}, texture= data.texture})
        instance.setupRotation(data)


        data.type = "image"
        table.insert(instance.drawQueue, data)
        return data
    end


    -- instance.__index = self
    return instance
end
