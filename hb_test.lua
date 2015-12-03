local M = {}
print(package.cpath)

local hb = require "luaharfbuzz"

local function shape(text)
  local f = font.fonts[font.current()]
  local x = io.open(f.filename,"r")
  local data  = x:read("*all")
  x:close()
  return {hb._shape(text, data, 0)}, f
end

local function convert_glyph(f, glyph)
  local char =  f.backmap[glyph]
  return char
end

local function create(char)
  local g1 = node.new("glyph")
  g1.font = font.current()
  g1.lang = tex.language
  g1.char = char
  return g1
end



local make_nodes = function(f,glyphs)
  local t = {}
  print("#", #glyphs)
  for _, v in ipairs(glyphs) do
    for x,y in pairs(v) do
      print("",x,y)
    end
    local char = convert_glyph(f, v.gid)
    local n = create(char)
    -- print("dx", v.dx * 10 / f.units_per_em)
    -- print("ax", v.ax / f.units_per_em * f.size)
    -- print(v.gid, char, n.char, f.units_per_em, n.width)
    local function calc_dim(field)
      return v[field] / f.units_per_em * f.size
    end
    -- n.width = calc_dim "ax"
    -- n.height = calc_dim "ay"
    n.xoffset = calc_dim "dx"
    n.yoffset = calc_dim "dy"
    t[#t + 1] = n
  end
  return t
end

local function make_box(t)
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
  local texttoshape = "یہ"
  -- texttoshape = "ahoj"
  local text, f = shape(texttoshape)
  local t = make_nodes(f, text)
  -- local text = {80, 97, 99, 107}

  -- for _, char in ipairs(text) do
  --   t[#t+1] = create(char)
  -- end

  local g1 = make_box(t)

  local hbox = node.hpack(g1)
  local vbox = node.vpack(hbox)

  node.write(vbox)
end

return M
