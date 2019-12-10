local g = golly()

local ruleints_filename = "ruleints.txt"
local rulestrings_filename = "rulestrings.txt"
local side_length = 8
local toroidal_params = ":T" .. side_length .. "," .. side_length
local bounding_rect = {side_length/2 - side_length, side_length/2 - side_length, side_length, side_length}
local max_pop = side_length * side_length
local trivial_end_pop_cutoff = 0.1
local trivial_end_pop_thresholds = {max_pop * trivial_end_pop_cutoff, (1 - trivial_end_pop_cutoff) * max_pop}
local total_steps = 1000
local num_tests = 1

-- debug
g.autoupdate(false)
local show_successes = true
local save_trivial_ending = false
local save = true

function round(n)
  return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

-- see if the file exists
function file_exists(file)
local f = io.open(file, "rb")
if f then f:close() end
return f ~= nil
end

function reverse_bits(bits, size)
  local i = 0
  local reversed = 0
  local last
  while i < size do
    last = bits & 1
    bits = bits >> 1
    reversed = reversed + last
    reversed = reversed << 1
    i = i + 1
  end
  return reversed >> 1
end

function rule_integer_black_white_reversal(rule_integer)
  local birth_rules = rule_integer & 511 --(2^10)-1
  local survive_rules = rule_integer >> 9
  birth_rules = reverse_bits(birth_rules ~ 511, 9) --(2^9)-1
  survive_rules = reverse_bits(survive_rules ~ 511, 9) --(2^9)-1
  return (birth_rules << 9) + survive_rules
end

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

local last = 0
if save and file_exists(ruleints_filename) then
  for line in io.lines(ruleints_filename) do last = tonumber(line) end
end

local last_rule = 262143
local is_mirror = {}
for rule_integer = 0, last_rule do
  if is_mirror[rule_integer] == nil then
    local black_white_reversal_rule_integer = rule_integer_black_white_reversal(rule_integer)
    if black_white_reversal_rule_integer ~= rule_integer then
      is_mirror[rule_integer] = true
    end
  end
end
for rule_integer = last + 1, last_rule do
  if is_mirror[rule_integer] ~= nil then
    local percent_done = round(10000 * rule_integer / last_rule) / 100
    local percent_status = percent_done .. "%"
    local ruleint_status = "ruleint: " .. rule_integer
    local rule_string = ruleint_to_rulestring(rule_integer)
    local rulestring_status = "rulestring: " .. rule_string
    local fail = false
    local hash_collision = false
    g.reset()
    g.setrule(rule_string .. toroidal_params)
    g.select(bounding_rect)
    g.show(percent_status .. " " .. ruleint_status .. " " .. rulestring_status)
    for test_num = 0, num_tests - 1 do
      local hashed_states = {}
      --local test_num_status = "test_num: " .. test_num
      g.randfill(50)
      local last_hash = g.hash(bounding_rect)
      for step_num = 0, total_steps - 1 do
        g.step()
        local this_hash = g.hash(bounding_rect)
        if this_hash == last_hash then
          break
        end
        if hashed_states[last_hash] ~= nil then
          fail = true -- cycle of period > 1 detected
          break
        end
        hashed_states[last_hash] = true
        last_hash = this_hash
      end
      g.step()
      if last_hash ~= g.hash(bounding_rect) then
        fail = true
      end
      if fail then
        break
      end
    end
    if not fail then
      local num_pop = tonumber(g.getpop())
      local trivial_end = num_pop < trivial_end_pop_thresholds[1] or num_pop > trivial_end_pop_thresholds[2]
      if save_trivial_ending or (not save_trivial_ending and not trivial_end) then
        if show_successes then
          g.update()
        end
        if save then
          local ruleints_file = io.open(ruleints_filename, "a+")
          local rulestrings_file = io.open(rulestrings_filename, "a+")
          ruleints_file:write(rule_integer, "\n")
          rulestrings_file:write(rule_string, "\n")
          ruleints_file:close()
          rulestrings_file:close()
        end
      end
    end
  end
end
