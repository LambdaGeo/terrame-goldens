-- Golden trajectories of the TerraME "sysdyn" package: the value of each
-- state variable before the first step and after every step, with 17
-- significant digits, for the default parameters of each model (and a few
-- choices offered by the models). RandomWalk draws random numbers: it is
-- recorded for seeds 1 .. $GOLDEN_SEEDS (default 50) in one file.
--
-- Output: $GOLDEN_OUT/sysdyn/<case>.csv and $GOLDEN_OUT/sysdyn/cases.csv

dofile(os.getenv("GOLDEN_LUA").."/common.lua")
import("sysdyn")

local N = tonumber(os.getenv("GOLDEN_SEEDS") or "50")

-- case, model, arguments, variables
local cases = {
	{"chaotic_growth",    "ChaoticGrowth",    {}, {"pop"}},
	{"coffee",            "Coffee",           {}, {"temperature"}},
	{"daisyworld",        "Daisyworld",       {}, {"whiteArea", "blackArea", "emptyArea",
	                                               "aveTemp", "tempNearWhite", "tempNearBlack"}},
	{"homeostasis",       "Homeostasis",      {}, {"stock"}},
	{"homeostasis_100",   "Homeostasis",      {stock = 100.0}, {"stock"}},
	{"limited_growth",    "LimitedGrowth",    {}, {"pop"}},
	{"lorenz",            "Lorenz",           {}, {"x", "y", "z"}},
	{"mono_lake",         "MonoLake",         {}, {"waterInLake", "level"}},
	{"mono_lake_export_50", "MonoLake",       {export = 50}, {"waterInLake", "level"}},
	{"population_growth", "PopulationGrowth", {}, {"population", "growth"}},
	{"predator_prey",     "PredatorPrey",     {}, {"prey", "predator"}},
	{"room_temperature",  "RoomTemperature",  {}, {"inside", "outside"}},
	{"sir",               "SIR",              {}, {"susceptible", "infected", "recovered", "contacts"}},
	{"tub",               "Tub",              {}, {"water"}},
	{"yeast",             "Yeast",            {}, {"cells"}},
	{"yeast_rate_2",      "Yeast",            {rate = 2.0}, {"cells"}},
}

local function argsText(args)
	local keys = {}
	for k in pairs(args) do keys[#keys + 1] = k end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do parts[#parts + 1] = k.."="..tostring(args[k]) end
	return table.concat(parts, ";")
end

local meta = assert(io.open(goldenOutput("sysdyn/cases.csv"), "w"))
meta:write("case,model,arguments,seeds,final_time,variables\n")

for _, c in ipairs(cases) do
	local name, model, args, vars = c[1], c[2], c[3], c[4]
	Random{seed = 1}
	local copy = {}
	for k, v in pairs(args) do copy[k] = v end
	local m = _G[model](copy)
	meta:write(name, ",", model, ",", argsText(args), ",,", m.finalTime, ",", table.concat(vars, ";"), "\n")
	recordVars(m, vars, goldenOutput("sysdyn/"..name..".csv"))
	print(name.." done")
end

-- RandomWalk: one file, one block of rows per seed
local f = assert(io.open(goldenOutput("sysdyn/random_walk.csv"), "w"))
f:write("seed,step,value\n")
local finalTime
for seed = 1, N do
	Random{seed = seed}
	local m = RandomWalk{}
	finalTime = m.finalTime
	f:write(seed, ",0,", m.value, "\n")
	m.timer:add(Event{priority = 100, action = function(ev)
		f:write(seed, ",", ev:getTime(), ",", m.value, "\n")
	end})
	m:run()
end
f:close()
meta:write("random_walk,RandomWalk,,", N, ",", finalTime, ",value\n")
meta:close()
print("random_walk done ("..N.." seeds)")
