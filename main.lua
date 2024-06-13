require "src/corpus"
require "src/layout"

local serpent = require "lib/serpent"

local config = require "config"
local layouts = load_layouts()
local shell_last

local function save_config(filename)
    local data = "return " .. serpent.block(config, {comment=false})
    local file = io.open(filename or "config.lua", "w")

    if file then
        file:write(data)
        file:close()
    end
end

function map_macro(str, header, body)
    local placeholders = {}
    for placeholder in header:gmatch("%%(%a+)") do
        table.insert(placeholders, placeholder)
    end
    
    local luaPattern = header:gsub("%%(%a+)", "(%.+)")
    local matches = {str:match(luaPattern)}

    if (
        #placeholders ~= 0 and #matches == #placeholders or
        #placeholders == 0 and str == header
    ) then
        local mapping = {}
        for i, placeholder in ipairs(placeholders) do
            mapping[placeholder] = matches[i]
        end
    
        return body:gsub("%%(%a+)", function(x) return mapping[x] or "" end)
    end
end

local function clear_screen()
    if not os.execute("clear") then
        os.execute("cls")
    end
end

local function get_table_len(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end

    return count
end

local function comma_value(amount)
    local formatted = amount
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return formatted
  end

local function parse_layout(tokens)
    if #tokens == 1 then
        local total = 0
        for _, _ in pairs(layouts) do
            total = total + 1
        end

        print("Total layouts: " .. total)

    elseif tokens[2] == "view" then
        if tokens[3] then
            local layout_name = tokens[3]

            if layouts[layout_name] then
                print_layout(layouts[layout_name])
            else
                print("Unknown layout '" .. layout_name .. "'")
            end
        else
            print("Usage: layout view <layout_name>")
        end
    else
        print("Unrecognized command '" .. tokens[2] .. "'.")
    end
end

local function parse_corpus(tokens)
    if #tokens == 1 then
        local corpus = get_corpus(config.corpus)
        local padding = #comma_value(corpus.total)
        print(config.corpus)
        print("Character Count:  " .. string.format("%" .. padding .. "s", comma_value(corpus.total)))
        print("  Monograms:      " .. string.format("%" .. padding .. "s", comma_value(get_table_len(corpus.monograms))))
        print("  Bigrams:        " .. string.format("%" .. padding .. "s", comma_value(get_table_len(corpus.bigrams))))
        print("  Skipgrams:      " .. string.format("%" .. padding .. "s", comma_value(get_table_len(corpus.skipgrams))))
        print("  Trigrams:       " .. string.format("%" .. padding .. "s", comma_value(get_table_len(corpus.trigrams))))
        
    
    elseif tokens[2] == "list" then
        print("List of Corpora:")
        for _, item in ipairs(list_corpora()) do
            print("  " .. item)
        end

    elseif tokens[2] == "set" then
        if tokens[3] then
            local corpus_file = tokens[3]
            local file = io.open("corpora/" .. corpus_file .. ".txt")

            if file then
                local start_time = os.clock()

                get_corpus(corpus_file, true)
                config.corpus = corpus_file
                save_config()
                
                local diff = os.clock() - start_time

                if diff < 1 then
                    print("Done! Took " .. string.format("%.0f", diff * 1000) .. "ms.")
                elseif diff < 10 then
                    print("Done! Took " .. string.format("%.1f", diff) .. "s")
                else
                    print("Done! Took " .. string.format("%.0f", diff) .. "s")
                end
            else
                print("Error: corpus '" .. corpus_file .. "' not found.")
            end
        else
            print("Usage: corpus set <corpus_name>")
            print("  Type 'corpus list' to see a list of available corpora.")
            print("  Or do 'corpus add <file>' to add a new corpus")
        end

    elseif tokens[2] == "add" then
        if tokens[3] then
            local file = io.open(tokens[3], "r")

            if file then  
                local language
                local name

                repeat
                    io.write("Corpus language [eng]: ")
                    language = io.read()
                    language = language ~= "" and language or "eng"
    
                    repeat
                        io.write("Corpus name: ")
                        name = io.read()
                    until name ~= ""
    
                    print()
                    
                    local path = "corpora/" .. language .. "/" .. name .. ".txt"
                    local ok
    
                    repeat
                        io.write("Save to " .. path .. " ok? [Y/n]: ")
                        ok = io.read()
                        ok = ok ~= "" and ok or "y"
                    until ok == "y" or ok == "n"
                     
                    print()
                until ok == "" or ok == "y"

                add_corpus(file, language, name)
                print("Corpus successfully saved!")
                file:close()
            else
                print("Error: file '" .. tokens[3] .. "' not found")
            end
        else
            print("Usage: corpus add <file>")
        end

    elseif tokens[2] == "match" then
        if tokens[3] then
            local corpus = get_corpus(config.corpus)

            local patterns = {}
            for i = 3, #tokens do
                table.insert(patterns, tokens[i])
            end

            local count_set = {}
            local count_arr = {}
            local matches = {}
            local total = 0
            
            for k, v in match_corpus(corpus, patterns) do
                matches[v] = matches[v] or {}
                table.insert(matches[v], k)

                if not count_set[v] then
                    table.insert(count_arr, v)
                    count_set[v] = true
                end

                total = total + 1
            end

            table.sort(count_arr, function(a, b) return a > b end)

            if #count_arr > 0 then
                local count_pad = #comma_value(count_arr[1])
                local index_pad = #comma_value(total)

                local page = 1
                local last_command = "quit"

                repeat
                    local index = 1
                    for _, v in ipairs(count_arr) do
                        for _, k in ipairs(matches[v]) do
                            if (
                                index <= page * config.lines_per_page and 
                                index > (page - 1) * config.lines_per_page 
                            ) then
                                print(string.format(
                                    "%" .. index_pad .. "s  %3s %6.3f%%  %" .. count_pad .. "s",
                                    comma_value(index),
                                    k, v / corpus.total * 100,
                                    comma_value(v)
                                ))
                            end
                            
                            index = index + 1
                        end
                    end
                    
                    local output
                    if last_command == "prev" then
                        output = "goto [Prev/next/quit]:"
                    elseif last_command == "next" then
                        output = "goto [prev/Next/quit]:"
                    else
                        output = "goto [prev/next/Quit]:"
                    end

                    while true do
                        io.write("\n" .. output .. " ")
                        nav = io.read()
                        nav = nav ~= "" and nav or last_command

                        if nav == "prev" or nav == "next" or nav == "quit" then
                            break
                        else
                            print("\nCommand not recognized.")
                        end
                    end
    
                    if nav == "prev" then
                        print()
                        last_command = nav
                        page = math.max(page - 1, 1)
                    elseif nav == "next" then
                        print()
                        last_command = nav
                        if total > page * config.lines_per_page then
                            page = page + 1
                        end
                    end

                    if config.auto_clear then
                        clear_screen()

                        if nav ~= "quit" then
                            print("goto [prev/next/Quit]: " .. nav .. "\n")
                        end
                    end
                until nav == "quit"
            else
                print("No matches found.")
            end
        else
            print("Usage: corpus match <pattern 1> <pattern 2> ...")
        end

    elseif tokens[2] == "pairs" then
        if #tokens > 2 then
            local corpus = get_corpus(config.corpus)
            
            for i = 3, #tokens do
                local ngram = tokens[i]
    
                local grams
                if #ngram == 1 then
                    grams = corpus.monograms
                end
                if #ngram == 2 then
                    grams = corpus.bigrams
                elseif #ngram == 3 then
                    grams = corpus.trigrams
                end
    
                if grams then
                    local reversed = string.reverse(ngram)
    
                    local count = (grams[ngram] or 0)
                    if reversed == ngram then
                        local perc = count / corpus.total * 100
                        print(string.format("%-9s  %6.3f%%  (%8d)", ngram, perc, count))
                    else
                        count = count + (grams[reversed] or 0)
                        local perc = count / corpus.total * 100
                        print(string.format("%-9s  %6.3f%%  (%8d)", ngram .. " + " .. reversed, perc, count))
                    end
                    
                else
                    print("Error: ngram size must be 1, 2, or 3.")
                    break
                end
            end
        else
            print("Usage: corpus pair <ngram 1> <ngram 2> ...")
        end

    elseif #tokens ~= 0 then
        print("Unrecognized command '" .. tokens[2] .. "'.")
    end
end

local function parse_input(tokens)
    if tokens[1] == "!!" then
        

    elseif tokens[1] == "clear" then
        clear_screen()

    elseif tokens[1] == "help" then
        print(
            "LuaWorld - Alpha 1.0.0\n" ..
            "  layout\n" ..
            "    view\n" ..
            "  corpus\n" ..
            "    list\n"..
            "    set\n"..
            "    add\n" ..
            "    pairs\n" ..
            "    match\n" ..
            "  cache clear\n" ..
            "  config\n" ..
            "  help\n" ..
            "  quit"
        )

    elseif tokens[1] == "layout" then
        parse_layout(tokens)

    elseif tokens[1] == "corpus" then
        parse_corpus(tokens)

    elseif tokens[1] == "config" then
        if tokens[2] then
            local key = tokens[2]
            
            if tokens[3] then
                local value = tokens[3]
                local num_value = tonumber(tokens[3])

                if value == "false" then
                    config[key] = false
                elseif value == "true" then
                    config[key] = true
                elseif num_value then
                    config[key] = num_value
                else
                    config[key] = value
                end
                
                save_config()
            else
                if config[key] then
                    print(key, config[key])
                else
                    print("Error: config item '" .. key .. "' not found.")
                end
            end
        else
            local padding = 0
            for k, _ in pairs(config) do
                if #k > padding then
                    padding = #k
                end
            end

            for k, v in pairs(config) do
                print(string.format("%" .. padding .. "s ", k), v)
            end
        end

    elseif #tokens > 1 and tokens[1] .. " " .. tokens[2] == "cache clear" then
        local removed = clear_cache()

        if removed == 0 then
            print("cache already empty.")
        else
            print(removed .. " files successfully purged.")
        end

    elseif tokens[1] == "debug" then

    elseif #tokens ~= 0 then
        print("Unrecognized command '" .. tokens[1] .. "'.")
    end
end

local function parse_command(input)
    local commands = {}
    for match in (input .. " && "):gmatch("(.-) && ") do
        table.insert(commands, match)
    end

    local processed = {}
    for _, command in ipairs(commands) do
        local tokens = {}
        for item in command:gmatch("([^ ]+)") do
            table.insert(tokens, item)
        end

        if tokens[1] then
            if tokens[1] == "!!" and shell_last then
                table.insert(processed, parse_command(shell_last))
            else
                print()
                parse_input(tokens)
                table.insert(processed, command)
            end
        end
    end

    return table.concat(processed, " && ")
end

while true do
    io.write("> ")
    local input = io.read()

    if input == "quit" then
        print("Exiting Luaworld...")
        break
    end

    if config.auto_clear then
        clear_screen()
        print("> " .. input)
    end

    for header, body in pairs(config.macros) do
        local result = map_macro(input, header, body)
        
        if result then
            input = result
            break
        end
    end

    local processed = parse_command(input)
    if processed ~= "!!" then
        shell_last = processed
    end
    
    print()
end