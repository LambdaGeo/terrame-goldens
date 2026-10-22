-- Golden ensembles of the TerraME "logo" package (agent-based models): for
-- each seed, the values a model reports after every step (populations,
-- unhappy agents, food...), with the default parameters of the model.
--
-- One seed per TerraME process (TerraME does not free finished models):
--   GOLDEN_CASE=<case> GOLDEN_SEED_FIRST=s GOLDEN_SEED_LAST=s terrame logo.lua
-- Output: $GOLDEN_OUT/logo/<case>.<first>-<last>.csv (seed,step,variable,value)

dofile(os.getenv("GOLDEN_LUA").."/common.lua")
import("logo")

local ONLY = os.getenv("GOLDEN_CASE")
local FIRST = tonumber(os.getenv("GOLDEN_SEED_FIRST") or "1")
local LAST = tonumber(os.getenv("GOLDEN_SEED_LAST") or "1")

local function countAgents(soc, select)
	local n = 0
	forEachAgent(soc, function(agent) if select(agent) then n = n + 1 end end)
	return n
end

local function countCells(cs, select)
	local n = 0
	forEachCell(cs, function(cell) if select(cell) then n = n + 1 end end)
	return n
end

-- case, model, summary (model -> {variable = value})
local cases = {
	{"schelling", "Schelling", function(m)
		return {
			-- what the model's chart shows: unhappy agents counted when the step
			-- started, before the move, in percent
			unhappy = m.unhappy(),
			-- unhappy agents after the move, in percent
			unhappy_after = 100 * countAgents(m.society, function(a) return a:isUnhappy() end) / #m.society,
		}
	end},
	{"predator_prey", "PredatorPrey", function(m)
		return {
			rabbits = #m.rabbits,
			wolves = #m.wolves,
			pasture = countCells(m.cs, function(c) return c.state == "pasture" end),
		}
	end},
	{"life_cycle", "LifeCycle", function(m)
		return {agents = #m.soc}
	end},
	{"ants", "Ants", function(m)
		return {
			food = m.cs.food,
			bringing = countAgents(m.soc, function(a) return a.state == "bringing" end),
		}
	end},
	{"disease", "Disease", function(m)
		return {susceptible = m.susceptible, infected = m.infected, recovered = m.recovered}
	end},
}

local function fmt(v)
	if math.type(v) == "float" then return string.format("%.17g", v) end
	return tostring(v)
end

for _, c in ipairs(cases) do
	local name, model, summary = c[1], c[2], c[3]
	if ONLY and ONLY ~= name then goto continue end
	local f = assert(io.open(goldenOutput("logo/"..name.."."..FIRST.."-"..LAST..".csv"), "w"))
	f:write("seed,step,variable,value\n")
	for seed = FIRST, LAST do
		Random{seed = seed}
		local m = _G[model]{}
		local function write(step)
			local values = summary(m)
			local keys = {}
			for k in pairs(values) do keys[#keys + 1] = k end
			table.sort(keys)
			for _, k in ipairs(keys) do f:write(seed, ",", step, ",", k, ",", fmt(values[k]), "\n") end
		end
		write(0)
		-- most models keep their Timer in model.timer; Disease keeps it in model.t
		local timer = m.timer or m.t
		timer:add(Event{priority = 100, action = function(ev) write(ev:getTime()) end})
		m:run()
	end
	f:close()
	print(name.." done (seeds "..FIRST.."-"..LAST..")")
	::continue::
end
