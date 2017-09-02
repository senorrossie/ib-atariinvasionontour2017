gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local json = require "json"

local logo = resource.load_image "logo-atariinvasion.png"

local default_interval = 5
local isUpdated = false

util.auto_loader(_G)

util.file_watch("config.json", function(raw)
    config = json.decode(raw)
    print( "[MAIN] (re-)Loaded config.json:")
    pp(config)
    isUpdated = true
end)

function make_switcher(childs, default_interval, config)
    local interval = default_interval
    if config ~= nil then
        if config.default == nil then
            interval = default_interval
        else
            interval = assert(config.default, default_interval)
        end
    end
    local next_switch = 0
    local child
    local function next_child()
        child = childs.next()
        if config[child] ~= nil then
            interval = config[child]
        end
        if interval == 0 then
            next_child()
        else
            next_switch = sys.now() + interval
        end
        print( "Item is", child)
        print( "Interval is", interval)
        print( "Next switch at ", next_switch)
    end
    local function draw()
        if sys.now() > next_switch then
            next_child()
        end
        util.draw_correct(resource.render_child(child), 0, 0, WIDTH, HEIGHT)
    end
    return {
        draw = draw;
    }
end

local switcher = make_switcher(util.generator(function()
    local cycle = {}
    for child, updated in pairs(CHILDS) do
        table.insert(cycle, child)
    end
    return cycle
end), default_interval, config)

function node.render()
    if isUpdated then
        switcher = make_switcher(util.generator(function()
            local cycle = {}
            for child, updated in pairs(CHILDS) do
                table.insert(cycle, child)
            end
            return cycle
        end), default_interval, config)
        isUpdated = false
    end

    switcher.draw()

    -- *** Logo
    util.draw_correct(logo, 1810, 10, 1910, 140, 0.75)
end
