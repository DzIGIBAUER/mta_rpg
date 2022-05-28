-- da ne bi sve stavljali u Element Data
local players_info = {}

--- Cuva informacije igraca u bazi podataka, ako je igrac ulogovan i nije banovan.
-- Treba da ga pokrece samo 'onPlayerQuit' event.
local function _igrac_diskonektovan(quit_type)
    local id = getElementData(source, "id", false)
    if quit_type == "banned" or not id then return end -- ako je banovan ili nije ulogovan bas nas briga

    local db = exports.dbSistem.get_connection()
    if not db then 
        return
    end

    local pos_x, pos_y, pos_z = getElementPosition(source)
    local rot_x, rot_y, rot_z = getElementRotation(source)

    dbExec(
        db,
        "UPDATE igrac SET novac = ?, pos_x = ?, pos_y = ?, pos_z = ?, rot_x = ?, rot_y = ?, rot_z = ? WHERE id= ?",
        getPlayerMoney(source), pos_x, pos_y, pos_z, rot_x, rot_y, rot_z, id
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

    local px, py, pz = player_info.pos_x, player_info.pos_y, player_info.pos_z
    local rx, ry, rz = player_info.rot_x, player_info.rot_y, player_info.rot_z

    setElementData(player, "id", player_info.id)
    triggerEvent("voziloSistem:ucitajVozila", player)

    setPlayerMoney(player, tonumber(player_info.novac), true)

    -- brisemo ono sto nam ne treba ili smo vec namestili sa element data
    izbrisi_kljuceve(player_info, "pos_x", "pos_y", "pos_z", "rot_x", "rot_y", "rot_z", "id")

    players_info[player] = player_info

    spawnPlayer(player, px, py, pz)
    setElementRotation(player, rx, ry, rz)

    showChat(player, true)

    fadeCamera(player, true)
    setCameraTarget(player, player)
    
end
addEvent("igracSistem:igracUlogovan", true)
addEventHandler("igracSistem:igracUlogovan", root, _stvori_igraca)

--- Menja skin igraca i cuva ga u bazi podataka.
-- @param model_id int: ID skina 'https://wiki.multitheftauto.com/wiki/Character_Skins'.
local function _namesti_skin_igraca(model_id)
    if getElementType(source) ~= "player" or not getElementData(source, "id", false) then
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

    local db = exports.dbSistem.get_connection()
    if not db then 
        outputDebugString("Ne mozemo da azuriramo skin igraca jer veza ka bazi podataka nije ostvarena.")
        return
    end

    dbExec(db, "UPDATE igrac SET model_id = ? WHERE id = ?", model_id, getElementData(source, "id", false))
    setElementModel(source, model_id)
end
addEvent("igracSistem:promeniSkin")
addEventHandler("igracSistem:promeniSkin", root, _namesti_skin_igraca)