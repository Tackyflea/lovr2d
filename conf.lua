function lovr.conf(t)
    t.headset.drivers = { 'desktop' } 
    t.window.width = 1000   
    t.window.height = 1000  
    t.modules.headset = false 
    t.window.borderless = false		-- Remove all border visuals from the window (boolean)
    t.window.resizable = true		-- Let the window be user-resizable (boolean)
    t.graphics.stencil = true -- request a stencil format for the default window
    conf = t.window
  end
  