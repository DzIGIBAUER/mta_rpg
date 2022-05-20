loadstring(exports.dgs:dgsImportFunction())()

local salon_vozila = {}
local trenutno_prikazano_vozilo
local gui = {}


--- Sklanja/prikazuje kursor i iskljucuje/ukljucuje kontrole igraca.
-- @param[opt] enabled bool: Da li kontrole treba ukljuciti ili iskljuciti.
local function set_controls_state(enabled)
    showCursor(not enabled)
    toggleAllControls(enabled, true, false)
end


--- Salje event serveru da igrac zeli da kupi vozilo.
-- @param salon element: Salon u kom igrac kupuje.
-- @param vozilo_index int: Id vozila u tom salonu.
local function kupi_vozilo(salon, vozilo_index)
    triggerServerEvent("salonVozilaSistem:igracKupujeVozilo", localPlayer, salon, vozilo_index)
end


--- Menja boju cene vozila u odnosu na to da li igrac ima vise, manje ili tacno onliko novca koliko je potrebno
-- za kupovinu trenutno prikazanog vozila.
-- @param label dgs element: Label kojim je prikazana cena.
-- @param cena int: cena vozila.
local function set_cena_label_color(label, cena)
    if cena == getPlayerMoney() then
        dgsSetProperty(label, "textColor", tocolor(255, 0, 255))
    elseif cena > getPlayerMoney() then
        dgsSetProperty(label, "textColor", tocolor(255, 0, 0))
    else
        dgsSetProperty(label, "textColor", tocolor(0, 255, 0))
    end
end

--- Menja trenutno prikazano vozilo u salonu.
-- @param salon element: Salon u kom se trenutno igrac nalazi.
-- @param smer int: Da li prikazujemo sledece vozila veceg ili manjeg id-a. (1 ili -1).
local function promeni_prikaz(salon, smer)
    smer = smer or 1
    local novi_idx

    if not trenutno_prikazano_vozilo then
        novi_idx = 1
    else
        novi_idx = trenutno_prikazano_vozilo + smer
    end

    local v_info = salon_vozila[salon][novi_idx]

    if not v_info then
        if smer == 1 then
            novi_idx = 1
        else
            novi_idx = #salon_vozila[salon]
        end
        
        v_info = salon_vozila[salon][novi_idx]
    end

    trenutno_prikazano_vozilo = novi_idx

    dgsSetText(gui.vozilo_label, getVehicleNameFromModel(v_info.m_id))
    dgsSetText(gui.cena_label, v_info.cena)
    set_cena_label_color(gui.cena_label, v_info.cena)
end


--- Prikazuje GUI salona vozila.
-- @param salon element: Salon ciji GUI prikazujemo.
-- TODO: titleHeight sjebava sve.
local function prikazi_gui_salona(salon)
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
            setCameraTarget(localPlayer)
            set_controls_state(true)
            trenutno_prikazano_vozilo = nil
        end    
    )

    addEventHandler("onDgsMouseClickUp", gui.window,
        function(button)
            if button ~= "left" then return end 

            if source == gui.btn_left then
                promeni_prikaz(salon, -1)
            elseif source == gui.btn_right then
                promeni_prikaz(salon, 1)
            elseif source == gui.btn_buy then
                kupi_vozilo(salon, trenutno_prikazano_vozilo)
            end

        end
    )

end


--- Uzima informacije salona u ciji smo marker usli.
local function _marker_hit(hit_player, matching_dimension)
    if hit_player ~= localPlayer or not matching_dimension or getPedOccupiedVehicle(localPlayer) then return end

    local salon = getElementParent(source)

    local camera_pos_element = getElementsByType("camerapos", salon)[1]
    local vozilo_preview_element = getElementsByType("vozilopreview", salon)[1]
    local vozilo_spawn_element = getElementsByType("vozilospawn", salon)[1]

    do
        local assert_msg = "Node '%s' nije pronadjen u 'salon' node-u u fajlu 'saloni.map'."
        assert(camera_pos_element, string.format(assert_msg, "camerapos"))
        assert(vozilo_preview_element, string.format(assert_msg, "vozilopreview"))
        assert(vozilo_spawn_element, string.format(assert_msg, "vozilospawn"))
    end
    
    
    local camera_pos = {
        x = getElementData(camera_pos_element, "posX", false),
        y = getElementData(camera_pos_element, "posY", false),
        z = getElementData(camera_pos_element, "posZ", false)
    }

    local look_at = {
        x = getElementData(vozilo_preview_element, "posX", false),
        y = getElementData(vozilo_preview_element, "posY", false),
        z = getElementData(vozilo_preview_element, "posZ", false)
    }

    setCameraMatrix(camera_pos.x, camera_pos.y, camera_pos.z, look_at.x, look_at.y, look_at.z)

    set_controls_state(false)
    prikazi_gui_salona(salon)

    promeni_prikaz(salon)

end
addEventHandler("onClientMarkerHit", resourceRoot, _marker_hit)



local function _server_poslao_saloni_info(veh_info)
    salon_vozila = veh_info
end
addEvent("salonVozilaSistem:serverPoslaoSalonInfo", true)
addEventHandler("salonVozilaSistem:serverPoslaoSalonInfo", resourceRoot, _server_poslao_saloni_info)


addEventHandler("onPlayerMoneyChange", root,
    function()
        if isElement(gui.window) then
            set_cena_label_color(gui.cena_label)
        end
    end
)