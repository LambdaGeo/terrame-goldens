-- Golden ensembles of the TerraME "ca" package: for the models that draw
-- random numbers while they run, the number of cells in each state after
-- every step, for seeds 1 .. $GOLDEN_SEEDS (default 50).
--
-- Output: $GOLDEN_OUT/ca/ensembles/<case>.csv (seed,step,value,count)

dofile(os.getenv("GOLDEN_LUA").."/common.lua")
import("ca")

local N = tonumber(os.getenv("GOLDEN_SEEDS") or "50")
-- Optional: run only one case and a range of seeds (to run in parallel);
-- the parts are joined afterwards by build_manifest.py.
local ONLY = os.getenv("GOLDEN_CASE")
local FIRST = tonumber(os.getenv("GOLDEN_SEED_FIRST") or "1")
local LAST = tonumber(os.getenv("GOLDEN_SEED_LAST") or tostring(N))

local cases = {
	{"growth",                    "Growth",                   {}, "cs",    "state"},
	{"snow",                      "Snow",                     {}, "cs",    "state"},
	{"solid_diffusion",           "SolidDiffusion",           {}, "cs",    "cover"},
	{"interspecific_competition", "InterspecificCompetition", {}, "cells", "species"},
	-- random initial state, deterministic rule: the counts check the initial draw
	{"fire",                      "Fire",                     {}, "cs",    "state"},
}

for _, c in ipairs(cases) do
	local name, model, args, field, attr = c[1], c[2], c[3], c[4], c[5]
	if ONLY and ONLY ~= name then goto continue end
	local suffix = (FIRST == 1 and LAST == N) and "" or ("."..FIRST.."-"..LAST)
	local f = assert(io.open(goldenOutput("ca/ensembles/"..name..suffix..".csv"), "w"))
	f:write("seed,step,value,count\n")
	for seed = FIRST, LAST do
		Random{seed = seed}
		local copy = {}
		for k, v in pairs(args) do copy[k] = v end
		local m = _G[model](copy)
		recordCounts(m, m[field], attr, f, seed)
	end
	f:close()
	print(name.." done (seeds "..FIRST.."-"..LAST..")")
	::continue::
end
