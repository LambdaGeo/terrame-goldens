-- Golden ensembles of the TerraME "ca" package: for the models that draw
-- random numbers while they run, the number of cells in each state after
-- every step, for seeds 1 .. $GOLDEN_SEEDS (default 50).
--
-- Output: $GOLDEN_OUT/ca/ensembles/<case>.csv (seed,step,value,count)
--
-- Some models keep the number of cells in each state constant (SolidDiffusion
-- only swaps atoms), so their counts say nothing. For those, an extra summary
-- adds counts of a spatial condition, written as more values of the same file.

dofile(os.getenv("GOLDEN_LUA").."/common.lua")
import("ca")

local N = tonumber(os.getenv("GOLDEN_SEEDS") or "50")
-- Optional: run only one case and a range of seeds (to run in parallel);
-- the parts are joined afterwards by build_manifest.py.
local ONLY = os.getenv("GOLDEN_CASE")
local FIRST = tonumber(os.getenv("GOLDEN_SEED_FIRST") or "1")
local LAST = tonumber(os.getenv("GOLDEN_SEED_LAST") or tostring(N))

-- SolidDiffusion: atoms that crossed to the other side of the middle column.
local function crossed(cs)
	local middle = math.floor(cs.xdim / 2)
	local out = {atom1_right = 0, atom2_left = 0}
	forEachCell(cs, function(cell)
		if cell.cover == "atom1" and cell.x > middle then
			out.atom1_right = out.atom1_right + 1
		elseif cell.cover == "atom2" and cell.x < middle then
			out.atom2_left = out.atom2_left + 1
		end
	end)
	return out
end

local cases = {
	{"growth",                    "Growth",                   {}, "cs",    "state"},
	{"snow",                      "Snow",                     {}, "cs",    "state"},
	{"solid_diffusion",           "SolidDiffusion",           {}, "cs",    "cover", crossed},
	{"interspecific_competition", "InterspecificCompetition", {}, "cells", "species"},
	-- random initial state, deterministic rule: the counts check the initial draw
	{"fire",                      "Fire",                     {}, "cs",    "state"},
}

for _, c in ipairs(cases) do
	local name, model, args, field, attr, extra = c[1], c[2], c[3], c[4], c[5], c[6]
	if ONLY and ONLY ~= name then goto continue end
	local suffix = (FIRST == 1 and LAST == N) and "" or ("."..FIRST.."-"..LAST)
	local f = assert(io.open(goldenOutput("ca/ensembles/"..name..suffix..".csv"), "w"))
	f:write("seed,step,value,count\n")
	for seed = FIRST, LAST do
		Random{seed = seed}
		local copy = {}
		for k, v in pairs(args) do copy[k] = v end
		local m = _G[model](copy)
		recordCounts(m, m[field], attr, f, seed, extra)
	end
	f:close()
	print(name.." done (seeds "..FIRST.."-"..LAST..")")
	::continue::
end
