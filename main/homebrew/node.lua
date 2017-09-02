-----------------------------------------------------------
--- Remote Controlled Homebrew display --------------------
-----------------------------------------------------------
gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

-- Image fader settings
local INTERVAL = 5
local SWITCH_DELAY = 1
local SWITCH_TIME = 1.0

local background = resource.load_image "background.jpg"
local font = resource.load_font "font.ttf"
local json = require "json"

local grey = resource.create_colored_texture(0,0,0,0.6)

local default_lang = "en"
local item = '{"time":"0","name":"No item loaded","platform":"-","released":"N/A","author":"-","players":"-","controller":"-","extras":"-","description":{"nl": "Geen beschrijving beschikbaar","en": "No description available."}}'
local item = json.decode(item)
local pictures = {}

local current_picture = 1   -- ID
local current_image = resource.create_colored_texture(1, 1, 1, 1)
local fade_start = 0

local function cycled(items, offset)
    offset = offset % #items + 1
    return items[offset], offset 
end

local function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function next_image()
    local next_image_name, next_picture = cycled(pictures, current_picture)
    if next_image_name ~= nil then
        print("now loading ", next_image_name, next_picture)
        last_image = current_image
        current_picture = next_picture
        current_image = resource.load_image(next_image_name)

        fade_start = sys.now()
    end
end

function wrap(str, limit, indent, indent1)
    indent = indent or ""
    indent1 = indent1 or indent
    limit = limit or 72
    function wrap_parargraph(str)
        local here = 1-#indent1
        return indent1..str:gsub("(%s+)()(%S+)()", function(sp, st, word, fi)
            if fi-here > limit then
                here = st - #indent
                return "\n"..indent..word
            end
        end)
    end
    local splitted = {}
    for par in string.gmatch(str, "[^\n]+") do
        local wrapped = wrap_parargraph(par)
        for line in string.gmatch(wrapped, "[^\n]+") do
            splitted[#splitted + 1] = line
        end
    end
    return splitted
end

local hb = (function(data)
    local function draw()
        local size = 50
        local ypos = 5
        --  Headlines
        --font: write( 5, ypos, "Atari Homebrew.", size, 1,1,1,1 )

        -- Text Area: WRAP@60 characters
        size = 80
        font: write( 800, 5, item.name, size, 1,1,0,1 )

        -- Game Info Area: WRAP@30 characters
        size = 60
        ypos = 580
        font: write( 50, ypos, "Information:", size, 1,1,0,1 )

        ypos = ypos + size + 10
        size = 40

        for k,v in spairs(item) do
            if k ~= "description" and k ~= "name" and k ~= "time" then
                font: write( 50, ypos, string.gsub(" "..k, "%W%l", string.upper):sub(2) .. ":", size, 1,1,1,1 )
                font: write( 250, ypos, v, size, 1,1,1,1 )
                ypos = ypos + size + 5
            end
        end

        local desclines = { "No description" }
        if #item.description == 1 then
            desclines = wrap(item.description, 62, "", "  ")
        else
            for id, idesc in pairs(item.description) do
                if id == default_lang then
                    desclines = wrap(idesc, 62, "", "  ")
                end
            end
        end

        y = 100
        for i, line in ipairs(desclines) do
            local size = 40
            font: write( 800, y, line, size, 1,1,1,1 )
            y = y + size + 2
        end
    end;

    local function homebrew(data)
        --pp(data)
        item = json.decode(data)
        if last_image then
            last_image:dispose()
            last_image = nil
        end
        if current_image then
            current_image:dispose()
            current_image = nil
        end
        current_picture = 1   -- ID
        current_image = resource.create_colored_texture(0, 0, 0, 1)
        fade_start = 0
    end;

    local function image(data)
        pictures = json.decode(data)
        if last_image then
            last_image:dispose()
            last_image = nil
        end
        if current_image then
            current_image:dispose()
            current_image = nil
        end
        current_picture = 1   -- ID
        current_image = resource.create_colored_texture(0, 0, 0, 1)
        fade_start = 0
    end

    return {
        homebrew = homebrew;
        image = image;
        draw = draw;
    }
end)()

--- Prepare for Network control
--[[
    NOTE: UDP packet size is limited, so too much data in a json file
            can result in an error!
    For example:
    runtime error: development/main/homebrew/node.lua:122: Expected
    value but found unexpected end of string at character 1489
    stack traceback:
        [C]: in function 'decode'
        development/main/homebrew/node.lua:122: in function 'callback'
]]--
node.alias("hb")

-- Remote commands
util.data_mapper{
    ["homebrew"] = hb.homebrew;
    ["image"] = hb.image;
}

function node.render()
    gl.clear(0,0,0,1)

    util.draw_correct(background, 0, 0, WIDTH, HEIGHT)
    grey:draw(5,5, 1915,1020)

    local img_x1 = 50
    local img_y1 = 60
    local img_x2 = 690
    local img_y2 = 540
    util.draw_correct(current_image, img_x1,img_y1, img_x2,img_y2)

    local delta = sys.now() - fade_start - SWITCH_DELAY
    if last_image and delta < 0 then
        util.draw_correct(last_image, img_x1,img_y1, img_x2,img_y2)
    elseif last_image and delta < SWITCH_TIME then
        local progress = delta / SWITCH_TIME
        util.draw_correct(last_image, img_x1,img_y1, img_x2,img_y2, 1 - progress)
        util.draw_correct(current_image, img_x1,img_y1, img_x2,img_y2, progress)
    else
        if last_image then
            last_image:dispose()
            last_image = nil
        end
        util.draw_correct(current_image, img_x1,img_y1, img_x2,img_y2)
    end

    hb.draw()
end

util.set_interval(INTERVAL, next_image)