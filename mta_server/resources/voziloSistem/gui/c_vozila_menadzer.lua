loadstring(exports.dgs:dgsImportFunction())()

local imports = {
    set_vozilo_data = set_vozilo_data,
    prikazi_vozilo_data = prikazi_vozilo_data
}

local VOZILO_ITEM_DATA_COLUMN = 1

local gui = {}



function toggle_gui()
    local new_state = not dgsGetVisible(gui.window)
    
    dgsSetVisible(gui.window, new_state)
    imports.prikazi_vozilo_data(false)

    showCursor(new_state, true)
end


local function init_gui()
    gui.window = dgsCreateWindow(0.3, 0.3, 0.35, 0.35, "Menadžer vozila", true)

    dgsSetVisible(gui.window, false)

    gui.grid_list = dgsCreateGridList(0, 0, 1, 1, true, gui.window)

    dgsGridListAddColumn(gui.grid_list, "ID", 0.2)
    dgsGridListAddColumn(gui.grid_list, "Vozilo", 0.6)
    dgsGridListAddColumn(gui.grid_list, "Stvoreno", 0.2)

    addEventHandler("onDgsWindowClose", gui.window,
        function()
            cancelEvent()
            toggle_gui()
        end
    )

    addEventHandler("onDgsGridListItemDoubleClick", gui.grid_list,
        function(button, state, item_id)
            if button ~= "left" or state ~= "up" then return end

            local vozilo_data = dgsGridListGetItemData(source, item_id, VOZILO_ITEM_DATA_COLUMN)
            imports.set_vozilo_data(vozilo_data)
            imports.prikazi_vozilo_data()
        end
    )
end

local function _resurs_pokrenut(_pokrenut_resurs)
    init_gui()
end
addEventHandler("onClientResourceStart", resourceRoot, _resurs_pokrenut)






local function _vozila_igraca_ucitana(vozila)
    for i, v in ipairs(vozila) do
        dgsGridListAddRow(gui.grid_list, i, v.id, getVehicleNameFromModel(v.model_id), "NE")
        dgsGridListSetItemData(gui.grid_list, i, VOZILO_ITEM_DATA_COLUMN, v)
    end
end
addEvent("voziloSistem:vozilaIgracaUcitana", true)
addEventHandler("voziloSistem:vozilaIgracaUcitana", localPlayer, _vozila_igraca_ucitana)
