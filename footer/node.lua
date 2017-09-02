gl.setup(1920, 160)

local font = resource.load_font("font.ttf")

function feeder()
    return { line }
end

-- File source
function trim(s)
    return s:match "^%s*(.-)%s*$"
end

util.file_watch("scrolldata.txt", function(data)
    line = trim(data)
end)

-- Scroller
text = util.running_text{
    font = font;
    size = 96;
    speed = 150;
    color = {0.98, 0.98, 1, 1};
    generator = util.generator(feeder)
}

function node.render()
	-- gl.clear(0.36, 0.82, 0.36, 0.6) -- Transparent
	gl.clear(0,0,0, 0.6) -- Transparent
	text:draw(HEIGHT-110)
end