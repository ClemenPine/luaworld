require "src/util"

function load_layouts()
    local layouts = {}
    for file in match_files("layouts", ".lua$") do
        local layout = require(file:sub(1, #file - 4))
        layouts[string.lower(layout.name)] = layout
    end

    return layouts
end

function print_layout(layout)
    print(layout.name)
    for _, row in ipairs(layout.main) do
        print("  " .. row)
    end
end