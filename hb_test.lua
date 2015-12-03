local M = {}

-- see M.run() function first
--
print(package.cpath)

local hb = require "luaharfbuzz"

local function shape(text)
  -- just load the current font data
  local f = font.fonts[font.current()]
  local x = io.open(f.filename,"r")
  local data  = x:read("*all")
  x:close()
  return {hb._shape(text, data, 0)}, f
end

local function convert_glyph(f, glyph)
  -- return glyph!s character
  local char =  f.backmap[glyph]
  return char
end

local function create(char)
  -- create glyph node with basic properties
  local g1 = node.new("glyph")
  g1.font = font.current()
  g1.lang = tex.language
  g1.char = char
  g1.left = tex.lefthyphenmin
  g1.right = tex.righthyphenmin
  return g1
end



local make_nodes = function(f,glyphs)
  -- process shaped glyph table 
  -- f is current font properties
  local t = {}
  print("#", #glyphs)
  for _, v in ipairs(glyphs) do
    -- print properties saved in Luaharfbuzz
    for x,y in pairs(v) do
      print("",x,y)
    end
    -- create new glyph node with character data
    local char = convert_glyph(f, v.gid)
    local n = create(char)
    -- calculate correct dimensions in TeX sp units
    -- it seems that Harfbuzz returns dimensions relative to font em value
    local function calc_dim(field)
      return v[field] / f.units_per_em * f.size
    end
    -- we have width and height for characters already, so this probably isn't needed
    -- or maybe it is? anyway, leave it for the future now
    n.width = calc_dim "ax"
    n.height = calc_dim "ay"
    n.xoffset = calc_dim "dx"
    n.yoffset = calc_dim "dy"
    t[#t + 1] = n
  end
  return t
end

local function make_box(t)
  -- process table with noded into node list
  local head = t[1]
  local last
  for _, v in ipairs(t) do
    if last then
      last.next = v
    end
    last = v
  end
  return head --node.slide(head)
end

function M.run()
  -- test string
  local texttoshape = "یہ"
  texttoshape = "پراگ"
  texttoshape = "تاریخ"
  -- texttoshape = "ahoj"
  -- make table with characters to be typesset
  local text, f = shape(texttoshape)
  -- make table with nodes
  local t = make_nodes(f, text)
  -- local text = {80, 97, 99, 107}

  -- for _, char in ipairs(text) do
  --   t[#t+1] = create(char)
  -- end
  -- convert node table to node list
  local g1 = make_box(t)
  -- prepare node list to be written
  local hbox = node.hpack(g1)
  -- text direction must be handled latter, it doesn't seem to work properly yet
  -- hbox.dir = "TRT"
  local vbox = node.vpack(hbox)
  node.write(vbox)
end

return M
