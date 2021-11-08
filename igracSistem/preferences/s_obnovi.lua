local FILE_PATH = "preferences\\userData.xml"

local function _ucitajXML()
    if not fileExists(FILE_PATH) then return false end

    local file = fileOpen(FILE_PATH)

    local fileData = fileRead(file, fileGetSize(file))

    fileClose(file)

    return fileData
end

local function _posaljiFajl()
    local fileData = _ucitajXML()
    if not fileData then 
        return triggerClientEvent(client, "fajlNedostupan", client)
    end

    triggerClientEvent(client, "serverPosaloFajl", resourceRoot, fileData, FILE_PATH)

end
addEvent("clientTraziFajl", true)
addEventHandler("clientTraziFajl", resourceRoot, _posaljiFajl)