-- Golden trajectories of the TerraME "ca" package: the state of every cell
-- before the first step and after every step, for the models whose rules are
-- deterministic (some draw their initial state at random; the file records
-- it, so that a port can start from the same state).
--
-- Output: $GOLDEN_OUT/ca/grids/<case>.csv and $GOLDEN_OUT/ca/grids/cases.csv

dofile(os.getenv("GOLDEN_LUA").."/common.lua")
import("ca")

local SEED = 1

-- case, model name, arguments, seeded?, cellular space field, attribute
local cases = {
	{"life_glider",     "Life",      {pattern = "glider"},     false, "cs", "state"},
	{"life_rpentomino", "Life",      {pattern = "rPentomino"}, false, "cs", "state"},
	{"life_random",     "Life",      {},                       true,  "cs", "state"},
	{"parity",          "Parity",    {},                       false, "cs", "state"},
	{"excitable",       "Excitable", {},                       false, "cs", "state"},
	{"wolfram_30",      "Wolfram",   {rule = 30},              false, "cs", "state"},
	{"wolfram_90",      "Wolfram",   {rule = 90},              false, "cs", "state"},
	{"wolfram_110",     "Wolfram",   {rule = 110},             false, "cs", "state"},
	{"fire",            "Fire",      {},                       true,  "cs", "state"},
	{"anneal",          "Anneal",    {},                       true,  "cs", "state"},
	{"oscillator",      "Oscillator",{},                       true,  "cs", "state"},
	{"parasit",         "Parasit",   {},                       true,  "cs", "state"},
}

local function argsText(args)
	local keys = {}
	for k in pairs(args) do keys[#keys + 1] = k end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do parts[#parts + 1] = k.."="..tostring(args[k]) end
	return table.concat(parts, ";")
end

local meta = assert(io.open(goldenOutput("ca/grids/cases.csv"), "w"))
meta:write("case,model,arguments,seed,final_time,xdim,ydim,attribute\n")

for _, c in ipairs(cases) do
	local name, model, args, seeded, field, attr = c[1], c[2], c[3], c[4], c[5], c[6]
	Random{seed = SEED}  -- also for unseeded cases, so nothing depends on the clock
	local copy = {}
	for k, v in pairs(args) do copy[k] = v end
	local m = _G[model](copy)
	local cs = m[field]
	meta:write(name, ",", model, ",", argsText(args), ",", seeded and SEED or "", ",",
		m.finalTime, ",", cs.xdim, ",", cs.ydim, ",", attr, "\n")
	recordGrid(m, cs, attr, goldenOutput("ca/grids/"..name..".csv"))
	print(name.." done")
end

meta:close()
