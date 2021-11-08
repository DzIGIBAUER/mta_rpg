--[[
    Ukoliko je fajl sa podacima igraca nepostojeci, unisten ili igrac zeli da obnovi podesavanja,
    zatrazicemo od servera kopiju fajla
]]

--TODO: pozovi ponovo funkciju za ucitavanje resource bindova

function obnoviUserPreferences()
    triggerServerEvent("clientTraziFajl", resourceRoot)
end

local function _sacuvajFajl(fileData, filePath)
    local file = fileExists(filePath) and fileOpen(filePath) or fileCreate(filePath)

    fileWrite(file, fileData)
    fileClose(file)
end

addEvent("serverPosaloFajl", true)
addEventHandler("serverPosaloFajl", resourceRoot, _sacuvajFajl)


local function _fajlNedostupan()
    triggerEvent("notifikacija", localPlayer, "greska", "au jee", "au jeee")

end
addEvent("fajlNedostupan", true)
addEventHandler("fajlNedostupan", resourceRoot, _fajlNedostupan)