loadstring(exports.dgs:dgsImportFunction())()

local vreme_poruke = 5000

local tip_notifikacije = {
    ["greska"] = {255, 10, 10},
    ["opomena"] = {255, 255, 10},
    ["obavestenje"] = {255, 255, 255},
    ["uspesno"] = {10, 255, 10}
}

-- https://gist.github.com/marceloCodget/3862929#gistcomment-3729315
function rgbToHex(r, g, b)
    -- EXPLANATION:
    -- The integer form of RGB is 0xRRGGBB
    -- Hex for red is 0xRR0000
    -- Multiply red value by 0x10000(65536) to get 0xRR0000
    -- Hex for green is 0x00GG00
    -- Multiply green value by 0x100(256) to get 0x00GG00
    -- Blue value does not need multiplication.

    -- Final step is to add them together
    -- (r * 0x10000) + (g * 0x100) + b =
    -- 0xRR0000 +
    -- 0x00GG00 +
    -- 0x0000BB =
    -- 0xRRGGBB
    local rgb = (r * 0x10000) + (g * 0x100) + b
    return string.format("%x", rgb)
end

--- Animira dgs element kako dolazi na vrh ekrana i vraca se nakon 'vreme_poruke'.
-- @param element dgs element: Element koji animiramo.
local function notifikacija_animacija(element)
    local x, y = dgsGetPosition(element, true)
    local w, h = dgsGetSize(element, true)
    
    dgsSetPosition(element, x, -h, true)
    
    dgsMoveTo(element, x, y, true, false, "OutQuad", 250)

    setTimer(function() -- nakon sto prodje vreme_poruke sklanjamo notifikaciju

        dgsMoveTo(element, x, -h, true, false, "OutQuad", 250)
        
        setTimer(function() -- cekamo dok se notifikacija skloni i unistavamo je
            destroyElement(element)
        
        end, 250, 1)

    end, vreme_poruke, 1)

end

--- Stvara GUI element koji predstavlja notifikaciju i prikazuje je.
-- @param tip string: Iz 'tip_notifikacije', odredjuje boju teksta naslova.
-- @param naslov string: Naslov notifikajije.
-- @param poruka string: Sadrzaj notifikacije.
local function prikazi_notifikaciju(tip, naslov, poruka)
    if #poruka > 80 then return end
    
    local naslovColor = tip_notifikacije[tip] or tip_notifikacije["obavestenje"]
    naslovColor = rgbToHex(unpack(naslovColor))

    local window = dgsCreateWindow(0.35, 0, 0.3, 0.15, naslov, true, naslovColor, nil, nil, nil, nil, nil, nil, true)
    dgsSetProperty(window, "movable", false)
    dgsSetProperty(window, "sizable", false)

    local label = dgsCreateLabel(0, 0, 1, 0.8, poruka, true, window, nil, nil, nil, nil, nil, nil, "center", "center")
    dgsSetProperty(label, "wordbreak", true)

    notifikacija_animacija(window)
end
addEvent("igracSistem:notifikacija", true)
addEventHandler("igracSistem:notifikacija", localPlayer, prikazi_notifikaciju)