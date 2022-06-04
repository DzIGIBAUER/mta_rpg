loadstring(exports.dgs:dgsImportFunction())()


KontrolnaTabla = {
    BOJA_POZADINE = tocolor(0, 0, 0)
}
KontrolnaTabla.__index = KontrolnaTabla

local kontrolna_tabla -- namestamo na dnu fajla.


function KontrolnaTabla.new()
    local self = setmetatable({}, KontrolnaTabla)

    self.vozilo = nil

    self._gui = {
        window = dgsCreateWindow(0.7, 0.8, 0.3, 0.2, "", true),
        vozilo_ime = dgsCreateLabel(0.1, 0.7, 0.5, 0.3, "", true),
        brzina = dgsCreateLabel(0.3, 0.0, 0.4, 0.7, "", true),
        gorivo = dgsCreateLabel(0.6, 0.7, 0.4, 0.3, "", true)
    }

    self:sakrij_prozor()
    
    dgsSetProperties(self._gui.window, {
            closeButtonEnabled = false,
            titleHeight = 0,
            color = BOJA_POZADINE,
            movable = false
        }
    )

    dgsSetParent(self._gui.vozilo_ime, self._gui.window)

    dgsSetParent(self._gui.brzina, self._gui.window)
    dgsSetProperty(self._gui.brzina, "alignment", {"center", "center"})

    dgsSetParent(self._gui.gorivo, self._gui.window)


    dgsSetProperty({self._gui.vozilo_ime, self._gui.brzina, self._gui.gorivo}, "textSize", {1.5, 1.5})

    
    addEventHandler("onDgsPreRender", self._gui.window,
        function()
            if dgsGetVisible(self._gui.window) then
                dgsSetText(self._gui.brzina, get_element_speed(self.vozilo))
            end
        end
    )


    return self
end

function KontrolnaTabla:namesti_vozilo(vozilo)
    self.vozilo = vozilo
    dgsSetText(self._gui.vozilo_ime, getVehicleName(vozilo))
end

function KontrolnaTabla:prikazi_prozor()
    dgsSetVisible(self._gui.window, true)
end

function KontrolnaTabla:sakrij_prozor()
    dgsSetVisible(self._gui.window, false)
end

function KontrolnaTabla:azuriraj_gorivo(nova_kolicina)
    dgsSetText(self._gui.gorivo, nova_kolicina)
end


local function _igrac_usao_u_vozilo(ped, seat)
    if ped ~= localPlayer or seat ~= 0 then return end

    kontrolna_tabla:namesti_vozilo(source)
    kontrolna_tabla:prikazi_prozor()
end
addEventHandler("onClientVehicleEnter", root, _igrac_usao_u_vozilo)


local function _igrac_napustio_vozilo(ped, seat)
    if ped ~= localPlayer or seat ~= 0 then return end

    kontrolna_tabla:sakrij_prozor()
end
addEventHandler("onClientVehicleExit", root, _igrac_napustio_vozilo)


local function _azuriraj_gorivo(nova_kolicina)
    kontrolna_tabla:azuriraj_gorivo(nova_kolicina)
end
addEvent("voziloSistem:gorivoKolicinaPromenjena", true)
addEventHandler("voziloSistem:gorivoKolicinaPromenjena", root, _azuriraj_gorivo)



function get_element_speed(the_element)
    -- Return the speed (km/h) by calculating the length of the velocity vector, after converting the velocity to the specified unit
    return (Vector3(getElementVelocity(the_element)) * 180).length
end


kontrolna_tabla = KontrolnaTabla.new()