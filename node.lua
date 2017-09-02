gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

function node.render()
	--gl.clear(1,1,1,1)		-- white
	gl.clear(0,0,0,1)		-- black

 	-- *** MAIN [1920x1080] ***
	local center = resource.render_child("main")
	center:draw(0,0, 1920,1080)

	-- *** FOOTER [1920x55] ***
	local footer = resource.render_child("footer")
	footer:draw(0,1035, 1920,1080)
end
