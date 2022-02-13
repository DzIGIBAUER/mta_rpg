-- Da bi dodali bind za funkciju u nekom resursu moramo dodati novi XML Node u userData.xml
-- sa imenom resursa gde se nalazi funkcija koji ce biti 'dete' <binds> node-a.
-- tu dodati <bind> koji mora da sadrzi atribute: 'command' i/ili 'key' i 'functionName'.
-- Takodje u meta.xml resursa moramo exportovati funkciju za koju je zakacen bind

loadstring(exports.actionBufferSistem:sendFunctionBufferConstruct())()

FILE_PATH = "preferences/userData.xml"

local bufferMngr = Buffer.new(200, "resource")


-- kljuc je ime funkcije a vrednost dugme za koje je funkcija zakacena
local _zauzetiBindovi = {}

local function _namestiNoviResursBind(resource, dugme, functionName)
    -- Ne mozemo da koristimo samu funkciju kao kljuc u tabeli
    -- jer lua pri sledecem pozivu ove funkcije ne prepoznaje 
    -- kljuc iz tabele i handlerFunction parametar kao isti objekat iz nekog razloga
    -- vec koristimo ime funkcije
    -- UPDATE: exportovanu funkciju ne mozemo da prosledimo kao parametar jer se sama funkcija nalazi u drugom Lua VM
    local handlerFunction = exports[getResourceName(resource)][functionName]

    -- sklanjamo stari bind ako ga ima
    local oldBind = _zauzetiBindovi[functionName]
    if oldBind then
        unbindKey(oldBind, "up", handlerFunction)
    end

    bindKey(dugme, "up", handlerFunction)
    _zauzetiBindovi[functionName] = dugme
end

function azurirajBind(resource, functionName, newKey)

    local rootNode = xmlLoadFile("preferences/userData.xml")
    if not rootNode then
        obnoviUserPreferences{callback = azurirajBind, callbackArguments = {resource, functionName, newKey}, xPath = {binds=0} }
        return outputDebugString("userData.xml nije pronadjen")
    end

    local bindsNode = xmlFindChild(rootNode, "binds", 0)
    local resourceBindNode = xmlFindChild(bindsNode, getResourceName(resource), 0)

    if not resourceBindNode then
        return -- resurs nije dodat u xml fajl
    end

    local nasao = false
    for _, bindNode in ipairs(xmlNodeGetChildren(resourceBindNode)) do
        local functionAtr = xmlNodeGetAttribute(bindNode, "function")
        if functionAtr == functionName then
            nasao = true
            
            --menjamo u xml fajlu
            xmlNodeSetAttribute(bindNode, "key", newKey)

            -- sada menjamo bind
            _namestiNoviResursBind(resource, newKey, functionName)

            break
        end
    end

    -- ako bind ne postoji napravi ga, pa ce da postoji
    if not nasao then
        local bindNode = xmlCreateChild(resourceBindNode, "bind")

        xmlNodeSetAttribute("functionName", functionName)
        xmlNodeSetAttribute("key", newKey)

    end

    xmlSaveFile(rootNode)
    xmlUnloadFile(rootNode)
end

local function _ucitajResursBindove(resursiNaCekanju)
    local rootNode = xmlLoadFile(FILE_PATH, true)
    if not rootNode then
        obnoviUserPreferences{callback = function() bufferMngr:forceRun() end, xPath = {binds=0} }
        return false
    end

    local bindsNode = xmlFindChild(rootNode, "binds", 0)
    for ridx, _resourceRoot in ipairs(resursiNaCekanju) do
        local resource = getResourceFromName(getElementID(_resourceRoot)) 

        local resourceBindNode = xmlFindChild(bindsNode, getResourceName(resource), 0)
        -- ako resurs ima key bind-ove
        if resourceBindNode then
            for _, bindNode in ipairs(xmlNodeGetChildren(resourceBindNode)) do
                local attrs = xmlNodeGetAttributes(bindNode)

                local handlerFunction = exports[getResourceName(resource)][attrs.functionName]
                
                if attrs.command then
                    -- sklanjamo ako vec postoji da ne bi bilo zakaceno na vise funkcija
                    removeCommandHandler(attrs.command)
                    addCommandHandler(attrs.command, handlerFunction)
                end
                
                if attrs.key then
                    _namestiNoviResursBind(resource, attrs.key, attrs.functionName)
                end
            end
        end
    end

    xmlUnloadFile(rootNode)
    return true
end
bufferMngr:setHandler(_ucitajResursBindove)


local function _resursPokrenut(startedResource)
    -- kada je ovaj resurs pokrenut, javi serveru kako bi nam poslao standardne postavke igraca
    if startedResource == resource then
        obnoviUserPreferences{callback = function() bufferMngr:forceRun() end, xPath = {binds=0} }
    end

    -- ako je 'standardnePostavke' nil onda cekamo od servera postavke, u suprotnom bufferMngr pokrece automatski    
    bufferMngr:appendElement(getResourceRootElement(startedResource), standardnePostavke)
end
addEventHandler("onClientResourceStart", root, _resursPokrenut)