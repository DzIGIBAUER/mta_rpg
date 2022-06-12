loadstring(exports.dgs:dgsImportFunction())()

local gui = {}
local trenutno_vozilo

--- Stvara gui.
local function init_gui()
    gui.window = dgsCreateWindow(0.7, 0.8, 0.3, 0.2, "", true)

    gui.vozilo_ime = dgsCreateLabel(0.1, 0.7, 0.5, 0.3, "", true, gui.window)
    gui.brzina = dgsCreateLabel(0.3, 0.0, 0.4, 0.7, "", true, gui.window)
    gui.gorivo = dgsCreateLabel(0.6, 0.7, 0.4, 0.3, "", true, gui.window)

    dgsSetProperties(gui.window, {
        closeButtonEnabled = false,
        titleHeight = 0,
        color = tocolor(0, 0, 0),
        movable = false
    })

    dgsSetProperty(gui.brzina, "alignment", {"center", "center"})

    dgsSetProperty({gui.vozilo_ime, gui.brzina, gui.gorivo}, "textSize", {1.5, 1.5})

    dgsSetVisible(gui.window, false)

    addEventHandler("onDgsPreRender", gui.window,
        function()
            if dgsGetVisible(gui.window) then
                dgsSetText(gui.brzina, get_element_speed(trenutno_vozilo))
            end
        end
    )
end

--- Vozilo u kom se trenutno nalazimo.
-- @param vozilo Vehicle: Vozilo u kom se nalazimo.
local function namesti_vozilo(vozilo)
    trenutno_vozilo = vozilo
    dgsSetText(gui.vozilo_ime, getVehicleName(vozilo))
end

--- Prikazuje prozor.
local function prikazi_prozor()
    dgsSetVisible(gui.window, true)
end

--- Sakriva prozor.
local function sakrij_prozor()
    dgsSetVisible(gui.window, false)
end

local function _igrac_usao_u_vozilo(ped, seat)
    if ped ~= localPlayer or seat ~= 0 then return end

    namesti_vozilo(source)
    prikazi_prozor()
end
addEventHandler("onClientVehicleEnter", root, _igrac_usao_u_vozilo)


local function _igrac_napustio_vozilo(ped, seat)
    if ped ~= localPlayer or seat ~= 0 then return end

    sakrij_prozor()
end
addEventHandler("onClientVehicleExit", root, _igrac_napustio_vozilo)

--- Azurira prikazanu kolicnu goriva u gui-u.
local function azuriraj_gorivo(nova_kolicina)
    dgsSetText(gui.gorivo, nova_kolicina)
end
addEvent("voziloSistem:gorivoKolicinaPromenjena", true)
addEventHandler("voziloSistem:gorivoKolicinaPromenjena", root, azuriraj_gorivo)

--- Racuna brzinu vozila u km/h.
-- @param the_element Element: Element ciju brzinu zelimo.
function get_element_speed(the_element)
    -- Return the speed (km/h) by calculating the length of the velocity vector, after converting the velocity to the specified unit
    return (Vector3(getElementVelocity(the_element)) * 180).length
end


local function _resurs_pokrenut(_pokrenut_resurs)
    init_gui()
end
addEventHandler("onClientResourceStart", resourceRoot, _resurs_pokrenut)
