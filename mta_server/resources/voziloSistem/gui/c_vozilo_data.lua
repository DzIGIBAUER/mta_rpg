loadstring(exports.dgs:dgsImportFunction())()

local gui = {}


function set_vozilo_data(data)
    if dgsGetText ~= tostring(data.id) then
        dgsSetText(gui.vozilo_id, data.id)
        dgsSetText(gui.vozilo_naziv, getVehicleNameFromModel(data.model_id))
        dgsSetText(gui.vozilo_stvoreno, "NE")
    end
end

function prikazi_vozilo_data(prikazi)
    prikazi = (prikazi ~= false) and true

    dgsSetVisible(gui.window, prikazi)
    if prikazi then dgsBringToFront(gui.window) end

end


function init_gui()
    gui.window = dgsCreateWindow(0.35, 0.35, 0.3, 0.3, "", true)

    dgsSetVisible(gui.window, false)

    gui._vozilo_id = dgsCreateLabel(0.1, 0.1, 0.2, 0.1, "ID: ", true, gui.window)
    gui.vozilo_id = dgsCreateLabel(0.4, 0.1, 0.3, 0.1, "", true, gui.window)

    gui._vozilo_naziv = dgsCreateLabel(0.1, 0.2, 0.2, 0.1, "Naziv: ", true, gui.window)
    gui.vozilo_naziv = dgsCreateLabel(0.4, 0.2, 0.5, 0.1, "", true, gui.window)

    gui._vozilo_stvoreno = dgsCreateLabel(0.1, 0.3, 0.2, 0.1, "Stvoreno: ", true, gui.window)
    gui.vozilo_stvoreno = dgsCreateLabel(0.4, 0.3, 0.3, 0.1, "NE", true, gui.window)

    gui.spawn_vozilo = dgsCreateButton(0.35, 0.7, 0.3, 0.2, "Stvori", true, gui.window)


    addEventHandler("onDgsWindowClose", gui.window,
        function()
            cancelEvent()
            dgsSetVisible(source, false)
        end
    )

    addEventHandler("onDgsMouseClickUp", gui.spawn_vozilo,
        function(button)
            if button ~= "left" then return end

            local vozilo_id = tonumber(dgsGetText(gui.vozilo_id))
            triggerServerEvent("voziloSistem:spawnVozilo", localPlayer, vozilo_id)
        end
    )
end


local function _resurs_pokrenut(_pokrenut_resurs)
    init_gui()
end
addEventHandler("onClientResourceStart", resourceRoot, _resurs_pokrenut)