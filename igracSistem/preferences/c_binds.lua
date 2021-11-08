local vremeCekanja = 200
local resursiNaCekanju = {}

-- Da bi dodali bind za funkciju u nekom resursu moramo dodati novi XML Node u userData.xml
-- sa imenom resursa gde se nalazi funkcija koji ce biti 'dete' <binds> node-a.
-- Node mora da sadrzi atribute: 'command', 'functionName' i key.
-- Takodje u meta.xml resursa moramo exportovati funkciju za koju je zakacen bind


-- kljuc je ime funkcije a vrednost dugme za koje je funkcija zakacena
local _zauzetiBindovi = {}

local function _namestiNoviResursBind(resource, dugme, functionName)
    -- Ne mozemo da koristimo samu funkciju kao kljuc u tabeli
    -- jer lua pri sledecem pozivu ove funkcije ne prepoznaje 
    -- kljuc iz tabele i handlerFunction parametar kao isti objekat iz nekog razloga
    -- vec koristimo ime funkcije
    local handlerFunction = exports[getResourceName(resource)][functionName]

    -- sklanjamo stari bind ako ga ima
    local oldBind = _zauzetiBindovi[functionName]
    if oldBind then
        unbindKey(oldBind, "up", handlerFunction)
    end

    bindKey(dugme, "up", handlerFunction)
    _zauzetiBindovi[functionName] = dugme
end


-- exports["igracSistem"].azurirajBind(nil, resource, functionName, newKey)
-- iz nekog razloga prvi argument prilikom pozivanja funkcije se gubi,
-- pa moramo da prosledimo dummy argument
function azurirajBind(resource, functionName, newKey)

    local rootNode = xmlLoadFile("preferences/userData.xml")
    if not rootNode then
        obnoviUserPreferences()
        return outputDebugString("userData.xml nije pronadjen")
    end

    local _resourceRoot = getResourceRootElement(resource)

    local bindsNode = xmlFindChild(rootNode, "binds", 0)
    local resourceBindNode = xmlFindChild(bindsNode, getResourceName(resource), 0)

    if not resourceBindNode then
        return -- resurs nema bindove
    end

    for _, bindNode in ipairs(xmlNodeGetChildren(resourceBindNode)) do
        local functionAtr = xmlNodeGetAttribute(bindNode, "function")
        if functionAtr == functionName then
            --menjamo u xml fajlu
            xmlNodeSetAttribute(bindNode, "key", newKey)

            -- sada menjamo bind
            _namestiNoviResursBind(resource, newKey, functionName)

            break
        end
    end

    xmlSaveFile(rootNode)
    xmlUnloadFile(rootNode)
end

local function _ucitajResursBindove(xmlFilePAth)
    local rootNode = xmlLoadFile(xmlFilePAth, true)
    if not rootNode then
        obnoviUserPreferences()
        return outputDebugString("Podesavanja igraca nisu ucitana. Zahtevana nova.")
    end

    local bindsNode = xmlFindChild(rootNode, "binds", 0)

    for ridx, resource in ipairs(resursiNaCekanju) do
        local resourceBindNode = xmlFindChild(bindsNode, getResourceName(resource), 0)
        
        -- ako resurs ima key bind-ove
        if resourceBindNode then
            for _, bindNode in ipairs(xmlNodeGetChildren(resourceBindNode)) do
                local command = xmlNodeGetAttribute(bindNode, "command")
                local functionName = xmlNodeGetAttribute(bindNode, "function")
                local key = xmlNodeGetAttribute(bindNode, "key")
                
                -- sklanjamo ako vec postoji da ne bi bilo zakaceno na vise funkcija
                removeCommandHandler(command)
                
                addCommandHandler(command, exports[getResourceName(resource)][functionName])
                _namestiNoviResursBind(resource, key, functionName)
            end
        end

        resursiNaCekanju[ridx] = nil -- imao bindove ili ne leti sa liste

    end

    xmlUnloadFile(rootNode)
end

local function resursPokrenut(startedResource)
    if next(resursiNaCekanju) == nil then
        setTimer(_ucitajResursBindove, vremeCekanja, 1, "preferences\\UserData.xml")
    end

    table.insert(resursiNaCekanju, startedResource)
end
addEventHandler("onClientResourceStart", root, resursPokrenut)