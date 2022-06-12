local active_marker = {}

local u_vozilu = false


function interact(player_source, key, key_state)
    if not active_marker[player_source] then return end
    triggerEvent("igracSistem:interact", player_source, active_marker[player_source], u_vozilu)
end


local function _igrac_izasao_iz_markera(_left_marker, matching_dimension)
    if not matching_dimension then return end
    active_marker[source] = nil
end
addEventHandler("onPlayerMarkerLeave", root, _igrac_izasao_iz_markera)

local function _igrac_usao_u_marker(hit_marker, matching_dimension)
    if not matching_dimension then return end
    active_marker[source] = hit_marker
end
addEventHandler("onPlayerMarkerHit", root, _igrac_usao_u_marker)


--- Jebeno ne moze da se vidi na serveru dal je igrac fizicki u vozilu.
local function _igrac_usao_u_vozilo()
    u_vozilu = true
end
addEventHandler("onPlayerVehicleEnter", root, _igrac_usao_u_vozilo)

local function _igrac_izasao_iz_vozila()
    u_vozilu = false
end
addEventHandler("onPlayerVehicleExit", root, _igrac_izasao_iz_vozila)
