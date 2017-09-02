gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local video

local videos = util.generator(function()
    local out = {}
    for name, _ in pairs(CONTENTS) do
        if name:match(".*mp4") then
            out[#out + 1] = name
        end
    end
    return out
end)
node.event("content_remove", function(filename)
    videos:remove(filename)
end)

local function next_video()
    local next_video_name = videos.next()
    -- print("[VIDEOS] now loading " .. next_video_name)

    if video then
        video:dispose()
        video = nil
    end
    video = util.videoplayer(next_video_name, {loop=false})
end

function node.render()
    if not video or not video:next() then
        next_video()
    end
    util.draw_correct(video, 0,0, WIDTH,HEIGHT, 1)
end