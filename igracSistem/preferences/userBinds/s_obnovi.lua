local FILE_PATH = "preferences/userData.xml"


local function _ucitajXML()
    local file = nil

    if fileExists(FILE_PATH) then
        file = fileOpen(FILE_PATH, true)
    else
        error(string.format("userBinds: Nije pronadjen fajl %s.", FILE_PATH))
    end

    local fileData = fileRead(file, fileGetSize(file))
    fileClose(file)

    return fileData
end

-- pretvara XML u Tabelu
local function _posaljiXMLTabelu(...)

    local fileData = _ucitajXML()
    if not fileData then
        return triggerClientEvent(
            "notifikacija",
            client,
            "greska",
            "Greška sa vašim postavkama",
            "Server nije uspeo da vam dostavi fajl sa postavkama. Ukoliko vaše postavke ne funkcionišu, pokušajte da se rekonektujete na server."
        )
    end
    
   triggerClientEvent(client, "userBinds:serverPosaloStandardnePostavke", resourceRoot, fileData, unpack({...}) )

end
addEvent("userBinds:clientTraziStandardnePostavke", true)
addEventHandler("userBinds:clientTraziStandardnePostavke", resourceRoot, _posaljiXMLTabelu)