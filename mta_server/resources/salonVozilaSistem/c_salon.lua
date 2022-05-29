loadstring(exports.dgs:dgsImportFunction())()

local gui = {}

local saloni_vozila
local trenutni_salon

local TrenutniSalon = {}
TrenutniSalon.__index = TrenutniSalon

local SMER = {
    NAZAD = -1,
    NAPRED = 1
}



--- Menja boju cene vozila u odnosu na to da li igrac ima vise, manje ili tacno onliko novca koliko je potrebno
-- za kupovinu trenutno prikazanog vozila.
-- @param label dgs element: Label kojim je prikazana cena.
-- @param cena int: cena vozila.
local function _set_cena_label_color(label, cena)
    if cena == getPlayerMoney() then
        dgsSetProperty(label, "textColor", tocolor(255, 0, 255))
    elseif cena > getPlayerMoney() then
        dgsSetProperty(label, "textColor", tocolor(255, 0, 0))
    else
        dgsSetProperty(label, "textColor", tocolor(0, 255, 0))
    end
end

--- Sklanja/prikazuje kursor i iskljucuje/ukljucuje kontrole igraca.
-- @param[opt] enabled bool: Da li kontrole treba ukljuciti ili iskljuciti.
local function set_controls_state(enabled)
    showCursor(not enabled)
    toggleAllControls(enabled, true, false)
end







--- Konstruise salon objekat za lakse upravljanje trenutnim salonom.
-- @param salon element: Salon u kom se nalazimo.
-- @param info table: Informacije o vozilima ovog salona.
-- @return table: ovaj objekat.
function TrenutniSalon.new(salon, info)
    local self = setmetatable({}, TrenutniSalon)
    
    local camera_pos_element = getElementsByType("camerapos", salon)[1]
    local vozilo_preview_element = getElementsByType("vozilopreview", salon)[1]
    local vozilo_spawn_element = getElementsByType("vozilospawn", salon)[1]
    local vozilo_color_element = getElementsByType("vozilocolor", salon)[1]

    do
        local assert_msg = "Node '%s' nije pronadjen u 'salon' node-u u fajlu 'saloni.map'."
        assert(camera_pos_element, string.format(assert_msg, "camerapos"))
        assert(vozilo_preview_element, string.format(assert_msg, "vozilopreview"))
        assert(vozilo_spawn_element, string.format(assert_msg, "vozilospawn"))
        assert(vozilo_color_element, string.format(assert_msg, "vozilocolor"))
    end

    self.camera = {
        pos = Vector3(getElementPosition(camera_pos_element))
    }

    self.preview = {
        pos = Vector3(getElementPosition(vozilo_preview_element)),
        rot = Vector3(getElementRotation(vozilo_preview_element))
    }

    self.spawn = {
        pos = Vector3(getElementPosition(vozilo_spawn_element)),
        rot = Vector3(getElementRotation(vozilo_spawn_element))
    }


    local color_1 = getElementData(vozilo_color_element, "color1")
    local color_2 = getElementData(vozilo_color_element, "color2")
    local color_3 = getElementData(vozilo_color_element, "color3")
    local color_headlight = getElementData(vozilo_color_element, "colorheadlight")

    self.colors = {
        { tonumber("0x"..color_1:sub(2,3)), tonumber("0x"..color_1:sub(4,5)), tonumber("0x"..color_1:sub(6,7)) },
        { tonumber("0x"..color_2:sub(2,3)), tonumber("0x"..color_2:sub(4,5)), tonumber("0x"..color_2:sub(6,7)) },
        { tonumber("0x"..color_3:sub(2,3)), tonumber("0x"..color_3:sub(4,5)), tonumber("0x"..color_3:sub(6,7)) },
        { tonumber("0x"..color_headlight:sub(2,3)), tonumber("0x"..color_headlight:sub(4,5)), tonumber("0x"..color_headlight:sub(6,7)) }
    }

    self.salon_element = salon
    self.info = info
    self.trenutno_vozilo_idx = nil
    self.trenutno_vozilo_elem = nil

    setCameraMatrix(self.camera.pos.x, self.camera.pos.y, self.camera.pos.z, self.preview.pos.x,self.preview.pos.y, self.preview.pos.z)
    self:prikazi_gui()

    set_controls_state(false)
    self:promeni_prikaz(SMER.NAPRED)

    return self
end

--- Stvara vozilo za clienta i brise predhodno.
-- @param[opt] model_id int: Model vozila ili nil ako samo zelimo da uklonimo trenutno.
function TrenutniSalon:_prikazi_vozilo(model_id)
    if isElement(self.trenutno_vozilo_elem) then
        destroyElement(self.trenutno_vozilo_elem)
    end

    if not model_id then return end

    self.trenutno_vozilo_elem = createVehicle(
        model_id, self.preview.pos.x, self.preview.pos.y, self.preview.pos.z,
        self.preview.rot.x, self.preview.rot.y, self.preview.rot.z
    )

    setVehicleColor(self.trenutno_vozilo_elem, unpack(self.colors[1]), unpack(self.colors[2]), unpack(self.colors[2]), nil, nil, nil)
end

--- Menja trenutno prikazano vozilo u salonu.
-- @param smer int: Da li prikazujemo sledece vozila veceg ili manjeg id-a. (1 ili -1).
function TrenutniSalon:promeni_prikaz(smer)
    smer = smer or SMER.NAPRED
    local novi_idx

    if not self.trenutno_vozilo_idx then
        novi_idx = 1
    else
        novi_idx = self.trenutno_vozilo_idx + smer
    end

    local v_info = self.info[novi_idx]

    if not v_info then
        if smer == SMER.NAPRED then
            novi_idx = 1
        else
            novi_idx = #self.info
        end
        
        v_info = self.info[novi_idx]
    end

    self.trenutno_vozilo_idx = novi_idx

    dgsSetText(gui.vozilo_label, getVehicleNameFromModel(v_info.m_id))
    dgsSetText(gui.cena_label, v_info.cena)
    self:_prikazi_vozilo(v_info.m_id)
    _set_cena_label_color(gui.cena_label, v_info.cena)
end


--- Salje event serveru da igrac zeli da kupi vozilo.
function TrenutniSalon:kupi_vozilo()
    triggerServerEvent("salonVozilaSistem:igracKupujeVozilo", localPlayer, self.salon_element, self.trenutno_vozilo_idx, self.colors)
end


--- Prikazuje GUI salona vozila.
-- TODO: titleHeight sjebava sve.
function TrenutniSalon:prikazi_gui()
    gui.window = dgsCreateWindow(0.20, 0.80, 0.60, 0.20, "Salon", true)
    dgsSetProperty(gui.window, "color", tocolor(0, 0, 0, 0))

    gui.vozilo_label = dgsCreateLabel(0.25, 0, 0.25, 0.35, "Učitavanje...", true, gui.window)
    dgsLabelSetHorizontalAlign(gui.vozilo_label, "center")
    dgsLabelSetVerticalAlign(gui.vozilo_label, "center")
    dgsSetProperty(gui.vozilo_label, "textSize", {2.0, 2.0})

    gui.cena_label = dgsCreateLabel(0.50, 0, 0.25, 0.35, "", true, gui.window)
    dgsLabelSetHorizontalAlign(gui.cena_label, "center")
    dgsLabelSetVerticalAlign(gui.cena_label, "center")
    dgsSetProperty(gui.cena_label, "textSize", {2.0, 2.0})

    gui.btn_buy = dgsCreateButton(0.25, 0.50, 0.50, 0.35, "Kupi", true, gui.window)
    dgsSetProperty(gui.btn_buy, "textSize", {2.0, 2.0})

    gui.btn_left = dgsCreateButton(0, 0, 0.25, 0.85, "<", true, gui.window)
    dgsSetProperty(gui.btn_left, "textSize", {2.0, 2.0})

    gui.btn_right = dgsCreateButton(0.75, 0, 0.25, 0.85, ">", true, gui.window)
    dgsSetProperty(gui.btn_right, "textSize", {2.0, 2.0})


    addEventHandler("onDgsWindowClose", gui.window,
        function()
            self:_prikazi_vozilo(nil)
            setCameraTarget(localPlayer)
            set_controls_state(true)
        end    
    )

    addEventHandler("onDgsMouseClickUp", gui.window,
        function(button)
            if button ~= "left" then return end 

            if source == gui.btn_left then
                self:promeni_prikaz(SMER.NAZAD)
            elseif source == gui.btn_right then
                self:promeni_prikaz(SMER.NAPRED)
            elseif source == gui.btn_buy then
                self:kupi_vozilo()
            end

        end
    )
end



local function _marker_hit(hit_player, matching_dimension)
    if hit_player ~= localPlayer or not matching_dimension or getPedOccupiedVehicle(localPlayer) then return end

    local salon = getElementParent(source)

    trenutni_salon = TrenutniSalon.new(salon, saloni_vozila[salon])
end
addEventHandler("onClientMarkerHit", resourceRoot, _marker_hit)

local function _marker_leave(left_player, matching_dimension)
    if left_player ~= localPlayer or not matching_dimension or getPedOccupiedVehicle(localPlayer) then return end

    trenutni_salon = nil
end
addEventHandler("onClientMarkerLeave", resourceRoot, _marker_leave)

    




local function _server_poslao_saloni_info(veh_info)
    saloni_vozila = veh_info
end
addEvent("salonVozilaSistem:serverPoslaoSalonInfo", true)
addEventHandler("salonVozilaSistem:serverPoslaoSalonInfo", resourceRoot, _server_poslao_saloni_info)

addEventHandler("onPlayerMoneyChange", root,
    function()
        if isElement(gui.window) then
            _set_cena_label_color(gui.cena_label)
        end
    end
)
