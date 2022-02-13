--[[
    Ukoliko je fajl sa podacima igraca nepostojeci, unisten ili igrac zeli da obnovi podesavanja,
    zatrazicemo od servera kopiju fajla
]]

-- TODO: obnovi samo <binds> node a ne ceo fajl

standardnePostavke = nil -- xml string sa standardnim postavkama
local cMngr = Comparator.new()
local _callBack = nil-- funkcija koju treba da pozovema kada obnovimo user preferences
local _args = nil -- argumenti koje treba proslediti callback-u


function obnoviUserPreferences(args)
    _callback = args.callback
    _args = args.callbackArguments

    if not standardnePostavke then
        triggerServerEvent("userBinds:clientTraziStandardnePostavke", resourceRoot, args.xPath)
    else
        _osveziPostavke(standardnePostavke, args.xPath)
    end
end

local function _osveziPostavke(fileData, xPath)
    standardnePostavke = fileData

    local userXMLRoot = xmlLoadFile(FILE_PATH)
    local userXML = userXMLRoot
    if userXMLRoot then
        local serverXML = xmlLoadString(fileData)

        if xPath then
            for nName, index in pairs(xPath) do
                -- da li ga user ima
                nasao = xmlFindChild(userXML, nName, index)
                if not nasao then
                    break
                end
                
                userXML = nasao
                serverXML = xmlFindChild(serverXML, nName, index)
            end
        end

        cMngr:compareAndFix(userXML, serverXML, true, true)

        xmlUnloadFile(userXML)

        xmlUnloadFile(serverXML)
    else
        if fileExists(FILE_PATH) then fileDelete(FILE_PATH) end

        local file = fileCreate(FILE_PATH)
        fileWrite(file, fileData)
        fileClose(file)
    end


    triggerEvent(
        "notifikacija",
        localPlayer,
        "uspesno",
        "Osvežene postavke",
        "Fajl sa vašim postavkama je uspesno osvežen"
    )

    if _callback then
        _callback(unpack{_args})

        _callback = nil
        _args = nil
    end

end
addEvent("userBinds:serverPosaloStandardnePostavke", true)
addEventHandler("userBinds:serverPosaloStandardnePostavke", resourceRoot, _osveziPostavke)
