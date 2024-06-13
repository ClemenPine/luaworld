require "src/util"

local json = require "lib/json"
local utf8 = require "lua-utf8"
local lfs = require "lfs"

function get_ngrams(str, spaces)
    local counts = {
        monograms = {},
        bigrams = {},
        trigrams = {},
        skipgrams = {},
    }

    local monograms, bigrams, trigrams, skipgrams =
        counts.monograms, counts.bigrams, counts.trigrams, counts.skipgrams
        
    local total = 0
    local c1, c2, c3, c4
    for pos, _ in utf8.codes(str) do
        c1, c2, c3, c4 = c2, c3, c4, pos

        if c3 then
            local monogram = str:sub(c3, c4 - 1)
            monograms[monogram] = (monograms[monogram] or 0) + 1
        end

        if c2 then
            local bigram = str:sub(c2, c4 - 1)
            bigrams[bigram] = (bigrams[bigram] or 0) + 1
        end

        if c1 then
            local trigram = str:sub(c1, c4 - 1)
            local skipgram = str:sub(c1, c2 - 1) .. str:sub(c3, c4 - 1)
            trigrams[trigram] = (trigrams[trigram] or 0) + 1
            skipgrams[skipgram] = (skipgrams[skipgram] or 0) + 1
        end

        total = total + 1
    end

    if not (spaces or false) then
        for _, grams in pairs(counts) do
            for k in pairs(grams) do
                if k:match("%s") then
                    grams[k] = nil
                end
            end
        end
    end

    counts.total = total
    return counts
end

function read_text(filename)
    local file = io.open(filename, "r")
    
    if file then
        local text = file:read("*a")
        file:close()
        return text
    end
end

function read_json(filename)
    local text = read_text(filename)

    if text then
        local data = json.decode(text)
        return data
    end
end

function write_json(table, filename)
    local data = json.encode(table)
    local file = io.open(filename, "w")

    if file then
        file:write(data)
        file:close()
    end
end

function get_corpus(corpus, debug)
    lfs.mkdir(".cache")
    
    local cache_filename = ".cache/" .. corpus:gsub("/", "-") .. ".json"
    local corpus_filename = "corpora/" .. corpus .. ".txt"

    local file = io.open(cache_filename, "r")

    local grams
    if file and (
        lfs.attributes(cache_filename).modification > 
        lfs.attributes(corpus_filename).modification
    ) then
        if (debug or false) then
            print("Reading from cache...")
        end
        
        grams = json.decode(file:read("*a"))
        file:close()
    else
        if (debug or false) then
            print("Reading text file...")
        end
        
        local text = read_text(corpus_filename) 
        
        if (debug or false) then
            print("Calculating ngrams...")
        end
        
        grams = get_ngrams(text)

        if (debug or false) then
            print("Writing to json...")
        end
        
        write_json(grams, cache_filename)
    end

    return grams
end

function add_corpus(file, language, name)
    lfs.mkdir("corpora/" .. language)
    
    local corpus_file = io.open("corpora/" .. language .. "/" .. name .. ".txt", "w")  
    if corpus_file then
        corpus_file:write(file:read("*a"))
        corpus_file:close()
    end
end

function match_corpus(corpus, patterns)
    return coroutine.wrap(function ()    
        local tables = {
            corpus.monograms,
            corpus.bigrams,
            corpus.trigrams,
        }
    
        for _, table in ipairs(tables) do
            for gram, count in pairs(table) do
                for i = 1, #patterns do
                    if #gram == #(gram:match(patterns[i]) or "") then
                        coroutine.yield(gram, count)
                        break
                    end
                end
            end
        end
    end)
end

function list_corpora()
    local paths = {}
    for path in match_files("corpora", ".txt$") do
        table.insert(paths, path:sub(9, #path - 4))
    end

    table.sort(paths)
    return paths
end

function clear_cache()
    local total = 0
    for file in match_files(".cache") do
        os.remove(file)
        total = total + 1
    end

    return total
end

-- local text = read_text("corpora/eng/monkeytype.txt")
-- local res = get_ngrams(text)
-- local res2 = get_ngrams2(text)

-- res.total = nil

-- for name, grams in pairs(res) do
--     for k, v in pairs(grams) do
--         if v ~= res2[name][k] then
--             print(k, math.abs((v or 0) - (res2[name][k] or 0)))
--         end
--     end
-- end