loadstring(exports.actionBufferSistem.send_function_buffer_construct())()

local func_buff_mngr = Buffer.new(200, "player")

local vozila_salona = {}



local function _igrac_kupuje_vozilo(salon, vozilo_index)
    if not client or source ~= client then return end


    local v_info = vozila_salona[salon][vozilo_index]
    if not v_info then
        return triggerClientEvent(client, "igracSistem:notifikacija", client,
            "greska",
            "Kupovina neuspešna",
            "Vozilo više nije u ponudi salona."
        )
    end

    if getPlayerMoney(client) < v_info.cena then
        return triggerClientEvent(client, "igracSistem:notifikacija", client,
            "greska",
            "Kupovina neuspešna",
            "Nemate dovoljno novca za ovo vozilo."
        )
    end

    exports.voziloSistem:dodaj_vozilo_u_db(client, v_info.m_id, v_info.cena)
end
addEvent("salonVozilaSistem:igracKupujeVozilo", true)
addEventHandler("salonVozilaSistem:igracKupujeVozilo", root, _igrac_kupuje_vozilo)


local function _vozilo_db_query_finished(vlasnik, new_client_veh_data, new_veh_id, cena_vozila)
    local veh_data

    for _, v_data in ipairs(new_client_veh_data) do
        if v_data.id == new_veh_id then
            veh_data = v_data
            break
        end
    end

    if not veh_data then
        return triggerClientEvent(vlasnik, "igracSistem:notifikacija", vlasnik,
            "greska",
            "Greška",
            "Čuvanje vozila u bazu podataka nije uspelo."
        )
    end

    triggerClientEvent(vlasnik, "igracSistem:notifikacija", vlasnik,
        "uspesno",
        "Vozilo kupljeno",
        string.format("Uspešno ste kupili vozilo %s za %s$.", getVehicleNameFromModel(veh_data.model_id), cena_vozila)
    )

    takePlayerMoney(vlasnik, cena_vozila)

end
addEvent("voziloSistem:voziloDBQuery", false)
addEventHandler("voziloSistem:voziloDBQuery", resourceRoot, _vozilo_db_query_finished)



local function _resurs_pokrenut(_resurs)
    local config_root = getResourceConfig(":salonVozilaSistem/saloni.xml")
    assert(config_root, string.format("Config fajl '%s' nije pronadjen.", "saloni.xml"))

    local vozila_conf_node = xmlFindChild(config_root, "vozilaconf", 0)
    
    for _, salon in ipairs(getElementsByType("salon")) do
        local vozila_salon = getElementData(salon, "vozilaSalona", false)
        local vozila_node = xmlFindChild(vozila_conf_node, vozila_salon, 0)

        local vozila_info = {}

        for _, vozilo_node in ipairs(xmlNodeGetChildren(vozila_node)) do
            local m_id = xmlNodeGetAttribute(vozilo_node, "m_id")
            local cena = xmlNodeGetAttribute(vozilo_node, "cena")
    
            vozila_info[#vozila_info+1] = {
                m_id = m_id,
                cena = tonumber(cena)
            }
        end

        vozila_salona[salon] = vozila_info

    end

end
addEventHandler("onResourceStart", resourceRoot, _resurs_pokrenut)


local function posalji_salon_info(clients)
    triggerClientEvent(clients, "salonVozilaSistem:serverPoslaoSalonInfo", resourceRoot, vozila_salona)
end
func_buff_mngr:set_handler(posalji_salon_info)


local function _player_resurs_pokrenut(resurs)
    if resurs ~= resource then return end

    func_buff_mngr:append_element(source, true)
end
addEventHandler("onPlayerResourceStart", root, _player_resurs_pokrenut)
