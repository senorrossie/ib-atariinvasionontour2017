-----------------------------------------------------------
--- Images ------------------------------------------------
-----------------------------------------------------------
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local INTERVAL = 10     -- Interval between switching images
local DELAY = 1         -- Time to load next image
local FADE = 5          -- Amount of seconds to spend on the fade

local trans = { "blend1", "blend2", "blend3", "blend4", "blend5", "blend6", "crossfade", "flip", "move", "move_shrink" }

pictures = util.generator(function()
    local out = {}
    for name, _ in pairs(CONTENTS) do
        if name:match(".*jpg") then
            out[#out + 1] = name
        end
    end
    return out
end)
node.event("content_remove", function(filename)
    pictures:remove(filename)
end)

-- Helper function to create shader based transitions
local function make_blender(blend_src)
    local function create_shader(main_src)
        local src = [[
            uniform sampler2D Texture;
            varying vec2 TexCoord;
            uniform vec4 Color;
            uniform float progress;
            float blend(float x) {
                ]] .. blend_src .. [[
            }
            void main() {
                ]] .. main_src .. [[
            }
        ]]
        return resource.create_shader(src)
    end
    local s1 = create_shader[[
        gl_FragColor = texture2D(Texture, TexCoord) * vec4(1.0 - blend(progress));
    ]]
    local s2 = create_shader[[
        gl_FragColor = texture2D(Texture, TexCoord) * vec4(blend(progress));
    ]]
    return function(c, n, progress, x1, y1, x2, y2)
        s1:use{ progress = progress }
        util.draw_correct(c, x1, y1, x2, y2)
        s2:use{ progress = progress }
        util.draw_correct(n, x1, y1, x2, y2)
        s2:deactivate()
    end
end

----------------------------------------------------------------
-- Available Transitions
----------------------------------------------------------------
local transitions = {
    crossfade = function(c, n, progress, x1, y1, x2, y2)
        util.draw_correct(c, x1, y1, x2, y2, 1.0 - progress)
        util.draw_correct(n, x1, y1, x2, y2, progress)
    end;

    move = function(c, n, progress, x1, y1, x2, y2)
        local xx = WIDTH * progress
        util.draw_correct(c, x1 + xx, y1, x2 + xx, y2, 1.0 - progress)
        util.draw_correct(n, x1 - WIDTH + xx, y1, x2 - WIDTH + xx, y2, progress)
    end;

    move_shrink = function(c, n, progress, x1, y1, x2, y2)
        local xx = WIDTH * progress
        util.draw_correct(c, x1 + xx, y1, x2, y2, 1.0 - progress)
        util.draw_correct(n, x1 - WIDTH + xx, y1, x2 - WIDTH + xx, y2, progress)
    end;

    flip = function(c, n, progress, x1, y1, x2, y2)
        local xx = WIDTH * progress
        gl.pushMatrix()
            gl.translate(WIDTH/2, HEIGHT/2)
            gl.rotate(progress * 90, 0, 1, 0)
            gl.translate(-WIDTH/2, -HEIGHT/2)
            util.draw_correct(c, x1 + xx, y1, x2, y2, 1.0 - progress)
        gl.popMatrix()

        gl.pushMatrix()
            gl.translate(WIDTH/2, HEIGHT/2)
            gl.rotate(90 - progress * 90, 0, 1, 0)
            gl.translate(-WIDTH/2, -HEIGHT/2)
            util.draw_correct(n, x1 - WIDTH + xx, y1, x2 - WIDTH + xx, y2, progress)
        gl.popMatrix()
    end;

    blend1 = make_blender[[
        x = 1.0 - clamp(TexCoord.x - 1.0 + x * 3.0, 0.0, 1.0);
        return 2.0 * x * x * x - 3.0 * x * x + 1.0;
    ]],

    blend2 = make_blender[[
        x = 1.0 - clamp(TexCoord.y - 1.0 + x * 3.0, 0.0, 1.0);
        return 2.0 * x * x * x - 3.0 * x * x + 1.0;
    ]],

    blend3 = make_blender[[
        vec2 center = vec2(0.5, 0.5);
        vec2 c = TexCoord - center;
        float angle = atan(c.x, c.y) / 3.1415926536;
        float dist = length(c);
        x = abs(mod(angle + dist * 5.0 + x, 2.0) - 1.0) + dist - 2.0 + x * 4.0;
        x = 1.0 - clamp(x, 0.0, 1.0);
        return 2.0 * x * x * x - 3.0 * x * x + 1.0;
    ]],

    blend4 = make_blender[[
        float y = sin( (TexCoord.x - 0.5) * x * 4.0) * sin( (TexCoord.y - 0.5) * x * 4.0);
        return clamp(y - 1.0 + x * 4.0, 0.0, 1.0);  
    ]],

    blend5 = make_blender[[
        return clamp(distance(TexCoord, vec2(0.5, 0.5)) - 1.0 + x * 3.0, 0.0, 1.0);
    ]],

    blend6 = make_blender[[
        return 1.0 - (2.0 * x * x * x - 3.0 * x * x + 1.0);
    ]],
}

local current_image = resource.create_colored_texture(0,0,0,0)
local fade_start = 0
local switch

local function next_image()
    local next_image_name = pictures.next()
    previous_image = current_image
    current_image = resource.load_image(next_image_name)

    fade_start = sys.now()

    -- Random transition
    local next_transition = trans[math.random(#trans)]
    switch = {
            transition = transitions[next_transition];
            duration = FADE;
            image = current_image;
            start = fade_start;
    }
    if switch.transition == nil then
        switch.transition = transitions["blend1"]
    end
end

function node.render()
	gl.clear(0,0,0,1)		-- black

    local delta = sys.now() - fade_start - DELAY
    if previous_image and delta < 0 then
        util.draw_correct(previous_image, 0, 0, WIDTH, HEIGHT)
    elseif previous_image and delta < FADE then
        local progress = delta / FADE
        switch.transition(previous_image, current_image, math.min(progress, 1.0), 0, 0, WIDTH, HEIGHT)
    else
        if previous_image then
            -- print(" *DEBUG* Disposing of previous ad.")
            previous_image:dispose()
            previous_image = nil
            switch = nil
        end
        util.draw_correct(current_image, 0, 0, WIDTH, HEIGHT)
    end
end

util.set_interval(INTERVAL, next_image)