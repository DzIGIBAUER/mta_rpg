local igraciInfo = {} -- da ne bi sve stavljali u Element Data


local function igracDiskonektovan(quitType)
    local nalogID = getElementData(source, "nalogID", false)
    if quitType == "banned" or not nalogID then return end -- ako je banovan ili nije ulogovan bas nas briga

    local db = exports["dbSistem"].getConnection()
    if not db then 
        return
    end

    local sX, sY, sZ = getElementPosition(source)
    local rX, rY, rZ = getElementRotation(source)

    dbExec(
        db,
        "UPDATE igrac SET novac = ?, spawnX = ?, spawnY = ?, spawnZ = ?, rotX = ?, rotY = ?, rotZ = ? WHERE nalogID = ?",
        getPlayerMoney(source), sX, sY, sZ, rX, rY, rZ, nalogID
    )
end
addEventHandler("onPlayerQuit", root, igracDiskonektovan)

local function izbrisiKljuceve(t, ...)
    local arg = {...}
    for _, k in ipairs(arg) do
        t[k] = nil
    end
end

local function stvoriIGraca(playerInfo)
    local player = client or source

    local x, y, z = playerInfo.spawnX or get("spawnX"), playerInfo.spawnY or get("spawnY"), playerInfo.spawnZ or get("spawnZ")
    local rx, ry, rz = playerInfo.rotX or get("rotX"), playerInfo.rotY or get("rotY"), playerInfo.rotZ or get("rotZ")

    setElementData(player, "nalogID", playerInfo.nalogID)
    triggerEvent("ucitajVozilaIgraca", player)

    setPlayerMoney(player, tonumber(playerInfo.novac), true)

    -- brisemo ono sto nam ne treba ili smo vec namestili sa element data
    izbrisiKljuceve(playerInfo, "spawnX", "spawnY", "spawnZ", "rotX", "rotY", "rotZ", "nalogID")

    igraciInfo[player] = playerInfo

    spawnPlayer(player, x, y, z)
    setElementRotation(player, rx, ry, rz)

    showChat(player, true)

    fadeCamera(player, true)
    setCameraTarget(player, player)
    
end
addEvent("onIgracUlogovan", true)
addEventHandler("onIgracUlogovan", root, stvoriIGraca)

-- menja skin igraca i azurira ga u bazi podataka.
local function namestiSkinIgraca(modelID)
    if getElementType(source) ~= "player" or not getElementData(source, "nalogID", false) then
        return outputDebugString("source mora da bude ulogovan igrac")
    end

    modelID = tonumber(modelID)
    if not modelID then
        return outputDebugString("modelID mora da bude INT ili STR koji moze da se pretvori u INT!")
    end

    local nasao = false
    for _, v in ipairs(getValidPedModels()) do
        if modelID == v then
            nasao = true
            break
        end
    end

    if not nasao then
        return outputDebugString(string.format("Ne postoji model sa tim ID-em(%s).", modelID))
    end

    local db = exports["dbSistem"].getConnection()
    if not db then 
        outputDebugString("Ne mozemo da azuriramo skin igraca jer veza ka bazi podataka nije ostvarena.")
    end

    dbExec(db, "UPDATE igrac SET skinID = ? WHERE nalogID = ?", modelID, getElementData(source, "nalogID", false))
    setElementModel(source, modelID)
end
addEvent("onNamestiSkinIgraca")
addEventHandler("onNamestiSkinIgraca", root, namestiSkinIgraca)