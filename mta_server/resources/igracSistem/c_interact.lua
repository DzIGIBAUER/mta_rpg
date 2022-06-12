local active_marker


function interact()
    if not active_marker then return end

    triggerServerEvent("igracSistem:interact", active_marker, getPedOccupiedVehicle(localPlayer))
end


local function _igrac_izasao_iz_markera(_left_player, matching_dimension)
    if not matching_dimension then return end
    active_marker = nil
end
addEventHandler("onClientMarkerLeave", root, _igrac_izasao_iz_markera)

local function _igrac_usao_u_marker(_hit_player, matching_dimension)
    if not matching_dimension then return end
    active_marker = source
end
addEventHandler("onClientMarkerHit", root, _igrac_usao_u_marker)
