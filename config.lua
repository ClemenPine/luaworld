return {
  auto_clear = true,
  corpus = "eng/monkeyracer",
  lines_per_page = 40,
  macros = {
    ["autoclear off"] = "config auto_clear false",
    ["autoclear on"] = "config auto_clear true",
    bigrams = "corpus match ..",
    ["bigrams %a"] = "corpus set %a && corpus match ..",
    ["bigrams with %a"] = "corpus match [%a]. .[%a]",
    ["load %a"] = "corpus set %a",
    ["lsb %a %b %c %d"] = "corpus match [%a][%b] [%b][%a] [%c][%d] [%d][%c]",
    monograms = "corpus match .",
    ["monograms %a"] = "corpus set %a && corpus match .",
    ["page lines %a"] = "config lines_per_page %a",
    trigrams = "corpus match ...",
    ["trigrams %a"] = "corpus set %a && corpus match ...",
    ["trigrams with %a"] = "corpus match [%a].. .[%a]. ..[%a]"
  }
}