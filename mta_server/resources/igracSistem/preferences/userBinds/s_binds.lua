loadstring(exports.anticheatSistem.init())()

local imports = {
    validate_event = validate_event
}

local zauzeti_bindovi = {}


--- Povezuje 'dugme' sa exportovanom funkcijom sa imenom 'function_name' iz resursa 'resource'
-- i sklanja stari, ako postoji.
-- Ne mozemo da koristimo samu funkciju kao argument zato sto funkcija mozda dolazi iz drugog Lua VM
-- pa umesto funkcije dobijemo 'nil', vec imamo ime i pristupimo 'exports' tabeli sa tim imenom.
-- @param resource_name string: Ime resursa gde se nalazi exportovana funkcija.
-- @param attrs table: Tabela sa atributima bind-a(function_name, key i/ili command).
local function _namesti_bind_igraca(resource_name, attrs)
    imports.validate_event{
        [client] = "player"
    }

    if not zauzeti_bindovi[client] then zauzeti_bindovi[client] = {} end

    local function_name = attrs.function_name
    local function handler_function(...)
        call(getResourceFromName(resource_name), function_name, ...)
    end

    local dugme = attrs.key
    if dugme then

        local old_bind = zauzeti_bindovi[client][function_name]
        if old_bind then
            unbindKey(client, old_bind, "up")
        end

        bindKey(client, dugme, "up", handler_function)
        zauzeti_bindovi[client][function_name] = dugme
    end

    local komanda = attrs.command
    if komanda then

        removeCommandHandler(komanda)
        addCommandHandler(komanda, handler_function)

    end

end
addEvent("igracSistem:namestiBind", true)
addEventHandler("igracSistem:namestiBind", root, _namesti_bind_igraca)