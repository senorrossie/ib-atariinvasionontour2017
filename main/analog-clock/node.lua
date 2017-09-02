-----------------------------------------------------------
--- Analog Clock ------------------------------------------
-----------------------------------------------------------
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

node.alias "time"

local INTERVAL = 15     -- Interval between switching images
local DELAY = 1         -- Time to load next image
local FADE = 5          -- Amount of seconds to spend on the fade

local dot = resource.load_image "dot.png"
local white = resource.create_colored_texture(1,1,1,1)
local black = resource.create_colored_texture(0,0,0,1)

local campaigns = util.generator(function()
    local out = {}
    for name, _ in pairs(CONTENTS) do
        if name:match("campaign_.*jpg") then
            out[#out + 1] = name
        end
    end
    return out
end)
node.event("content_remove", function(filename)
    campaigns:remove(filename)
end)

local current_campaign = white
local fade_start = 0

local function next_campaign()
    local next_image_name = campaigns.next()
    -- print("[ANALOG-CLOCK] now loading " .. next_image_name)
    previous_campaign = current_campaign
    current_campaign = resource.load_image(next_image_name)
    fade_start = sys.now()
end

--- Clock Logic
local base_time = N.base_time or 0

util.data_mapper{
    ["clock/set"] = function(time)
        base_time = tonumber(time) - sys.now()
        N.base_time = base_time
    end;
}

function hand(size, strength, angle, r,g,b,a)
    gl.pushMatrix()
    gl.translate(WIDTH/2, HEIGHT/2) 
    gl.rotate(angle, 0, 0, 1)
    black:draw(0, -strength, size, strength)
    gl.popMatrix()
end

local bg

function node.render()
    gl.clear(1,1,1,1)

    local delta = sys.now() - fade_start - DELAY
    if previous_campaign and delta < 0 then
        util.draw_correct(previous_campaign, 0, 0, WIDTH, HEIGHT )
    elseif previous_campaign and delta < FADE then
        local progress = delta / FADE
        util.draw_correct(previous_campaign, 0, 0, WIDTH, HEIGHT, 1 - progress)
        util.draw_correct(current_campaign, 0, 0, WIDTH, HEIGHT, progress)
    else
        if previous_campaign then
            -- print("[ANALOG-CLOCK] Disposing of previous campaign.")
            previous_campaign:dispose()
            previous_campaign = nil
        end
        util.draw_correct(current_campaign, 0, 0, WIDTH, HEIGHT, 1)
    end

    if not bg then
        gl.pushMatrix()
        gl.translate(WIDTH/2, HEIGHT/2) 
        for i = 0, 59 do
            gl.pushMatrix()
            gl.rotate(360/60*i, 0, 0, 1)
            if i % 15 == 0 then
                black:draw(WIDTH/2.1-80, -10, WIDTH/2.1, 10, 0.4)
            elseif i % 5 == 0 then
                black:draw(WIDTH/2.1-50, -10, WIDTH/2.1, 10, 0.4)
            else
                black:draw(WIDTH/2.1-5, -5, WIDTH/2.1, 5, 0.4)
            end
            gl.popMatrix()
        end
        gl.popMatrix()
        bg = resource.create_snapshot()
    else
        bg:draw(0,0,WIDTH,HEIGHT, 0.2)
    end

    local time = base_time + sys.now()

    local hour = (time / 3600) % 12
    local minute = time % 3600 / 60
    local second = time % 60

    local fake_second = second * 1.05
    if fake_second >= 60 then
        fake_second = 60
    end

    hand(WIDTH/4,   10, 360/12 * hour - 90)
    hand(WIDTH/2.5, 5, 360/60 * minute - 90)
    hand(WIDTH/2.1,  2, 360/60 * (((math.sin((fake_second-0.4) * math.pi*2)+1)/8) + fake_second) - 90)
    dot:draw(WIDTH/2-30, HEIGHT/2-30, WIDTH/2+30, HEIGHT/2+30, 1)
end

util.set_interval(INTERVAL, next_campaign)