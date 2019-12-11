local g = golly()

math.randomseed(os.time() + tonumber(g.getpop()) + tonumber(g.getgen()))

local side_length = 128
local bounding_rect = {side_length/2 - side_length, side_length/2 - side_length, side_length, side_length}
local toroidal_params = ":T" .. side_length .. "," .. side_length
local last_rule = 262143
function ruleint_to_rulestring(rule_integer)
  local birth_rules = rule_integer & 511 --(2^10)-1
  local survive_rules = rule_integer >> 9
  local birth_string = "B"
  local survive_string = "S"
  for string_bit = 0, 8 do
    local bit_mask = 2 ^ string_bit
    if bit_mask & birth_rules ~= 0 then
      birth_string = birth_string .. string_bit
    end
    if bit_mask & survive_rules ~= 0 then
      survive_string = survive_string .. string_bit
    end
  end
  local rule_string = birth_string .. "/" .. survive_string
  return rule_string
end

g.setrule(ruleint_to_rulestring(math.random(0, last_rule)) .. toroidal_params)
g.select(bounding_rect)
g.randfill(math.random(10, 90))
