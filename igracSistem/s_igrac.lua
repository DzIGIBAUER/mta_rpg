-- da ne bi sve stavljali u Element Data
local players_info = {}

--- Cuva informacije igraca u bazi podataka, ako je igrac ulogovan i nije banovan.
-- Treba da ga pokrece samo 'onPlayerQuit' event.
local function _igrac_diskonektovan(quit_type)
    local nalogID = getElementData(source, "nalogID", false)
    if quit_type == "banned" or not nalogID then return end -- ako je banovan ili nije ulogovan bas nas briga

    local db = exports["dbSistem"].get_connection()
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
addEventHandler("onPlayerQuit", root, _igrac_diskonektovan)

--- Helper funkcija koja ce iz tabele 't' da izbrise sve vrednosti u tabeli '{...}'.
-- @param t table: tabela iz koje brisemo.
-- @param ... any: vrednosti koje brisemo iz 't'.
local function izbrisi_kljuceve(t, ...)
    local arg = {...}
    for _, k in ipairs(arg) do
        t[k] = nil
    end
end

--- Spawn-uje igraca i ucitava informacije igraca iz baze podataka.
-- Treba da ga pokrece samo 'igracSistem:igracUlogovan' event.
local function _stvori_igraca(player_info)
    local player = client or source

    local x, y, z = player_info.spawnX or get("spawnX"), player_info.spawnY or get("spawnY"), player_info.spawnZ or get("spawnZ")
    local rx, ry, rz = player_info.rotX or get("rotX"), player_info.rotY or get("rotY"), player_info.rotZ or get("rotZ")

    setElementData(player, "nalogID", player_info.nalogID)
    triggerEvent("voziloSistem:ucitajVozila", player)

    setPlayerMoney(player, tonumber(player_info.novac), true)

    -- brisemo ono sto nam ne treba ili smo vec namestili sa element data
    izbrisi_kljuceve(player_info, "spawnX", "spawnY", "spawnZ", "rotX", "rotY", "rotZ", "nalogID")

    players_info[player] = player_info

    spawnPlayer(player, x, y, z)
    setElementRotation(player, rx, ry, rz)

    showChat(player, true)

    fadeCamera(player, true)
    setCameraTarget(player, player)
    
end
addEvent("igracSistem:igracUlogovan", true)
addEventHandler("igracSistem:igracUlogovan", root, _stvori_igraca)

--- Menja skin igraca i cuva ga u bazi podataka.
-- @param model_id int: id skina 'https://wiki.multitheftauto.com/wiki/Character_Skins'.
local function namesti_skin_igraca(model_id)
    if getElementType(source) ~= "player" or not getElementData(source, "nalogID", false) then
        return outputDebugString("source mora da bude ulogovan igrac")
    end

    model_id = tonumber(model_id)
    if not model_id then
        return outputDebugString("model_id mora da bude INT ili STR koji moze da se pretvori u INT!")
    end

    local nasao = false
    for _, v in ipairs(getValidPedModels()) do
        if model_id == v then
            nasao = true
            break
        end
    end

    if not nasao then
        return outputDebugString(string.format("Ne postoji model sa tim ID-em(%s).", model_id))
    end

    local db = exports["dbSistem"].get_connection()
    if not db then 
        outputDebugString("Ne mozemo da azuriramo skin igraca jer veza ka bazi podataka nije ostvarena.")
    end

    dbExec(db, "UPDATE igrac SET skinID = ? WHERE nalogID = ?", model_id, getElementData(source, "nalogID", false))
    setElementModel(source, model_id)
end
addEvent("igracSistem:promeniSkin")
addEventHandler("igracSistem:promeniSkin", root, namesti_skin_igraca)