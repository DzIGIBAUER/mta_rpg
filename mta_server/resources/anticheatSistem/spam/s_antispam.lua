local INTERVAL = 200

local executions = {}

local function _igrac_komanda(command)
    local zadnje_vreme = executions[source]

    if not zadnje_vreme then return end

    if getTickCount() - zadnje_vreme > INTERVAL then
        cancelEvent(true, "Antispam: Ne možete toliko često da koristite komande.")
    end

    executions[source] = getTickCount()
end
addEventHandler("onPlayerCommand", root, _igrac_komanda)
