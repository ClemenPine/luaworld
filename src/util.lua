local lfs = require "lfs"

function match_files(dir, match)
    local function recurTree(dir)
        for entry in lfs.dir(dir) do
            if entry ~= "." and entry ~=".." then
                local path = dir .. "/" .. entry
                local attrs = lfs.attributes(path)
                
                if attrs.mode == "directory" then
                    recurTree(path)
                elseif path:match(match or "") then
                    coroutine.yield(path)
                end
            end
        end
    end

    return coroutine.wrap(function() recurTree(dir) end)
end