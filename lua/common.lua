-- Helpers shared by the drivers: write the state of every cell, one row per
-- grid row, so that a file is a stack of grids (step, y, x0 .. x{n-1}).

sessionInfo().graphics = false
sessionInfo().autoclose = true

function goldenOutput(name)
	local dir = os.getenv("GOLDEN_OUT") or "."
	return dir.."/"..name
end

function openGrid(path, cs)
	local f = assert(io.open(path, "w"))
	local header = {"step", "y"}
	for x = 0, cs.xdim - 1 do header[#header + 1] = "x"..x end
	f:write(table.concat(header, ","), "\n")
	return f
end

function writeGrid(f, cs, step, attr)
	for y = 0, cs.ydim - 1 do
		local row = {step, y}
		for x = 0, cs.xdim - 1 do
			row[#row + 1] = tostring(cs:get(x, y)[attr])
		end
		f:write(table.concat(row, ","), "\n")
	end
end

-- Record the grid before the first step and after every step. The recording
-- Event has a large priority number, so it runs after the model's own events
-- at the same time.
function recordGrid(model, cs, attr, path)
	local f = openGrid(path, cs)
	writeGrid(f, cs, 0, attr)
	model.timer:add(Event{priority = 100, action = function(ev)
		writeGrid(f, cs, ev:getTime(), attr)
	end})
	model:run()
	f:close()
end

-- Count the cells in each state after every step, for ensembles.
function countStates(cs, attr)
	local counts = {}
	forEachCell(cs, function(cell)
		local v = tostring(cell[attr])
		counts[v] = (counts[v] or 0) + 1
	end)
	return counts
end

function recordCounts(model, cs, attr, f, seed, extra)
	local function write(step)
		local counts = countStates(cs, attr)
		if extra then
			for k, v in pairs(extra(cs)) do counts[k] = v end
		end
		local keys = {}
		for k in pairs(counts) do keys[#keys + 1] = k end
		table.sort(keys)
		for _, k in ipairs(keys) do
			f:write(seed, ",", step, ",", k, ",", counts[k], "\n")
		end
	end
	write(0)
	model.timer:add(Event{priority = 100, action = function(ev) write(ev:getTime()) end})
	model:run()
end
