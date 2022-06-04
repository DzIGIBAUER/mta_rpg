local vozila = {}
local stvorena_vozila = {}


--- TODO: mozda ovo malo bolje? coroutine ili nes.
--- Dodaje vozilo u db i trigger-uje event.
-- @param vlasnik player: Ko je vlasnik vozila.
-- @param model_id int: model vozila.
-- @param x, y, z, rx, ry, rz float: Gde se vozilo nalazi.
-- @param colors talbe: Boje vozila (1, 2, 3, headlight).
-- @param[opt] ... any: Sta proslediti kada trigger-ujemo event da je query zavrsen.
function dodaj_vozilo_u_db(vlasnik, model_id, x, y, z, rx, ry, rz, colors, ...)
    local db = exports.dbSistem.get_connection()

    local vlasnik_id = getElementData(vlasnik, "id", false)

    local ok = dbExec(
        db,
        [[
        INSERT INTO vozilo (vlasnik_id, model_id, gorivo, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z, color_1, color_2, color_3, color_headlight) 
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
        ]],
        vlasnik_id, model_id, 10, x, y, z, rx, ry, rz,
        ("%.2X%.2X%.2X"):format(unpack(colors[1])), ("%.2X%.2X%.2X"):format(unpack(colors[2])),
        ("%.2X%.2X%.2X"):format(unpack(colors[3])), ("%.2X%.2X%.2X"):format(unpack(colors[4]))
    )

    if not ok then
        triggerEvent("voziloSistem:voziloDBQuery", sourceResourceRoot, vlasnik, false)
    end


    dbQuery(

        function(qh, vlasnik, sourceResourceRoot, ...)
            local result, num_affected_rows, last_insert_id = dbPoll(qh, 0)
            
            triggerEvent("voziloSistem:voziloDBQuery", sourceResourceRoot, vlasnik, result, last_insert_id, ...)

        end,

        {vlasnik, sourceResourceRoot, ...},
        db,
        "SELECT * FROM vozilo WHERE vlasnik_id = ? AND model_id = ?", getElementData(vlasnik, "id", false), model_id
    )

end



local function _ucitaj_vozila_igraca_query_done(handle, igrac)
    local result, aff_rows, last_id = dbPoll(handle, 0)

    if result == false then
        local err_code, err_msg = aff_rows, last_id
        return triggerClientEvent(
            igrac,
            "igracSistem:notifikacija",
            igrac,
            "greska",
            "Vozila nisu učitana",
            "Vaša vozila nisu učitana, greška sa bazom podataka."
        )
    end

    vozila[igrac] = result
    triggerClientEvent(igrac, "voziloSistem:vozilaIgracaUcitana", igrac, result) 
end

local function _ucitaj_vozila_igraca()
    local id = getElementData(source, "id", false)
    if not id then return end

    local db = exports.dbSistem.get_connection()

    dbQuery(_ucitaj_vozila_igraca_query_done, {source}, db, "SELECT * FROM vozilo WHERE vlasnik_id = ?", id)

end
addEvent("voziloSistem:ucitajVozila")
addEventHandler("voziloSistem:ucitajVozila", root, _ucitaj_vozila_igraca)




-- TODO: Dodaj timer protiv spama
function spawn_vozilo(id)
    local vozila_igraca = vozila[source]
    if not vozila_igraca then
        return triggerClientEvent(
            source,
            "igracSistem:notifikacija",
            source,
            "greska",
            "Nemate vozila",
            "Izgleda da vasa vozila nisu učitana."
        )
    end

    for i, v in ipairs(vozila_igraca) do
        if v.id == id then
            local vozilo = createVehicle(v.model_id, 0, 0, -500, 0, 0, 0, v.registarska_tablica)
            
            setVehicleColor(
                vozilo,
                tonumber("0x"..v.color_1:sub(1,2)), tonumber("0x"..v.color_1:sub(3,4)), tonumber("0x"..v.color_1:sub(5,6)),
                tonumber("0x"..v.color_2:sub(1,2)), tonumber("0x"..v.color_2:sub(3,4)), tonumber("0x"..v.color_2:sub(5,6)),
                tonumber("0x"..v.color_3:sub(1,2)), tonumber("0x"..v.color_3:sub(3,4)), tonumber("0x"..v.color_3:sub(5,6)),
                nil, nil, nil
            )

            setVehicleHeadLightColor(
                vozilo,
                tonumber("0x"..v.color_headlight:sub(1,2)), tonumber("0x"..v.color_headlight:sub(3,4)), tonumber("0x"..v.color_headlight:sub(5,6))
            )

            spawnVehicle(vozilo, v.pos_x, v.pos_y, v.pos_z, v.rot_x, v.rot_y, v.rot_z)

            return
        end
    end

    triggerClientEvent(
        source,
        "igracSistem:notifikacija",
        source,
        "greska",
        "Vozilo nije pronađeno",
        string.format("Vozilo id %s nije pronađeno.", id)
    )
end
addEvent("voziloSistem:spawnVozilo", true)
addEventHandler("voziloSistem:spawnVozilo", root, spawn_vozilo)