loadstring(exports.anticheatSistem.init())()

local imports = {
    validate_event = validate_event
}


local relations = {}


local function get_corresponding_marker(marker)
    for k, v in pairs(relations) do
        if k == marker then
            return v 
        elseif v == marker then
            return k
        end
    end
end


local function _igrac_interact(u_vozilu)
    if u_vozilu then return end

    imports.validate_event{
        [client] = "player"
    }

    if not isElementWithinMarker(client, source) then
        return
    end

    local corresponding_marker = get_corresponding_marker(source)
    if not corresponding_marker then
        outputDebugString(("Nije pronađen odgovarajući marker za marker %s."):format(source))
        return
    end

    local interior = getElementInterior(corresponding_marker)
    local x, y, z = getElementPosition(corresponding_marker)
    setElementInterior(client, interior, x, y, z)
end
addEvent("igracSistem:interact", true)
addEventHandler("igracSistem:interact", resourceRoot, _igrac_interact)


local function _resurs_pokrenut()

    for _, banka in ipairs(getElementsByType("banka")) do

        for _, rel in ipairs(getElementsByType("relation", banka)) do
            local markeri = getElementsByType("marker", rel)
            assert(#markeri >= 2, ("Node 'relations' banke treba da ima minimum 2 marker node-a, a pronađena su %s."):format(#markeri))

            relations[markeri[1]] = markeri[2]
        end
    end
end
addEventHandler("onResourceStart", resourceRoot, _resurs_pokrenut)
