--- Da bi dodali bind za funkciju u nekom resursu moramo dodati novi XML Node u userData.xml
-- sa imenom resursa gde se nalazi funkcija koji ce biti 'dete' <binds> node-a.
-- tu dodati <bind> koji mora da sadrzi atribute: 'command' i/ili 'key' i 'function_name'.
-- Takodje u meta.xml resursa moramo exportovati funkciju za koju je zakacen bind

loadstring(exports.actionBufferSistem:send_function_buffer_construct())()

FILE_PATH = "preferences/userData.xml"

local buffer_mngr = Buffer.new(200, "resource")


--- kljuc: ime funkcije, vrednost: dugme za koje je funkcija zakacena
local zauzeti_bindovi = {}

--- Povezuje 'dugme' sa exportovanom funkcijom sa imenom 'function_name' iz resursa 'resource'
-- i sklanja stari, ako postoji.
-- Ne mozemo da koristimo samu funkciju kao argument zato sto funkcija mozda dolazi iz drugig Lua VM
-- pa umesto funkcije dobijemo 'nil', vec imamo ime i pristupimo 'exports' tabeli sa tim imenom.
-- @param resource element: Resurs gde se nalazi exportovana funkcija.
-- @param dugme string: Dugme sa kojim se povezuje exportovana funkcija.
-- @param function_name string: Ime exportovane funkcije.
local function namesti_novi_resurs_bind(resource, dugme, function_name)
    local handler_function = exports[getResourceName(resource)][function_name]

    -- sklanjamo stari bind ako ga ima
    local old_bind = zauzeti_bindovi[function_name]
    if old_bind then
        unbindKey(old_bind, "up", handler_function)
    end

    bindKey(dugme, "up", handler_function)
    zauzeti_bindovi[function_name] = dugme
end

--- Dodaje novi/azurira postojeci bind nekog resursa u XML fajlu i aktivara ga ako XML fajl postoji.
-- Ako ime greske sa XML fajlom obnovice ga i pokusati ponovo.
-- @param resource element: Resurs ciji bind azuriramo.
-- @param function_name string: Ime funkcije koju vezujemo za 'dugme'.
-- @param dugme string: Dugme za koje vezujemo funkciju.
function azuriraj_bind(resource, function_name, dugme)

    local root_node = xmlLoadFile("preferences/userData.xml")
    if not root_node then
        obnovi_user_preferences{callback = azuriraj_bind, callback_arguments = {resource, function_name, dugme}, target_node = "binds" }
        return outputDebugString("userData.xml nije pronadjen")
    end

    local binds_node = xmlFindChild(root_node, "binds", 0)
    local resource_bind_node = xmlFindChild(binds_node, getResourceName(resource), 0)

    if not resource_bind_node then return end

    local nasao = false
    for _, bind_node in ipairs(xmlNodeGetChildren(resource_bind_node)) do
        local function_attr = xmlNodeGetAttribute(bind_node, "function")
        if function_attr == function_name then
            nasao = true
            
            xmlNodeSetAttribute(bind_node, "key", dugme)

            namesti_novi_resurs_bind(resource, dugme, function_name)
            break
        end
    end

    if not nasao then
        local bind_node = xmlCreateChild(resource_bind_node, "bind")

        xmlNodeSetAttribute("function_name", function_name)
        xmlNodeSetAttribute("key", dugme)

    end

    xmlSaveFile(root_node)
    xmlUnloadFile(root_node)
end

-- TODO: Mozda je bolje imati tabelu i cuvati sve resurse ciji bindovi nisu mogli
-- biti ucitani i vratiti je 'buffer_mngr'.

--- Ocu funkciju zove function buffer sistem, te dobija tabelu sa elementima
-- i vraca true ili false. Vidi 'run_funciton' metodu 'buffer_mngr' objekta za vise informacija. 
-- @param resursi_na_cekanju table: Root elementi svih resursa koji zahtevaju ucitavanje njihovih bindova.
-- @return bool: true ako je sve u redu, false ako nije.
local function ucitaj_resurs_bindove(resursi_na_cekanju)
    local root_node = xmlLoadFile(FILE_PATH, true)
    if not root_node then
        obnovi_user_preferences{callback = function() buffer_mngr:force_run() end, target_node = "binds" }
        return false
    end

    local binds_node = xmlFindChild(root_node, "binds", 0)
    for _, _resource_root in ipairs(resursi_na_cekanju) do
        local resource = getResourceFromName(getElementID(_resource_root)) 

        local resource_bind_node = xmlFindChild(binds_node, getResourceName(resource), 0)
        -- ako resurs ima key bind-ove
        if resource_bind_node then
            for _, bind_node in ipairs(xmlNodeGetChildren(resource_bind_node)) do
                local attrs = xmlNodeGetAttributes(bind_node)

                local handler_function = exports[getResourceName(resource)][attrs.function_name]
                
                if attrs.command then
                    -- sklanjamo ako vec postoji da ne bi bilo zakaceno na vise funkcija
                    removeCommandHandler(attrs.command)
                    addCommandHandler(attrs.command, handler_function)
                end
                
                if attrs.key then
                    namesti_novi_resurs_bind(resource, attrs.key, attrs.function_name)
                end
            end
        end
    end

    xmlUnloadFile(root_node)
    return true
end
buffer_mngr:set_handler(ucitaj_resurs_bindove)

--- Kada je neki resurs pokrenut dodaj ga na listu elemenata koji cekaju u 'buffer_mngr'.
-- Ako je pokrenut resurs ovaj, onda obnovi user preferences.
-- @param started_resource element: Resurs koji je pokrenut.
local function _resurs_pokrenut(started_resource)
    if started_resource == resource then
        obnovi_user_preferences{callback = function() buffer_mngr:force_run() end, target_node = "binds" }
    end

    --- Ako je 'standardnePostavke' nil onda cekamo od servera postavke, u suprotnom buffer_mngr pokrece automatski    
    buffer_mngr:append_element(getResourceRootElement(started_resource), standardne_postavke)
end
addEventHandler("onClientResourceStart", root, _resurs_pokrenut)