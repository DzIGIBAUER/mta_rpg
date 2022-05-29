-- TODO: mozda ovo malo bolje? coroutine ili nes.

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
        string.format("%.2X%.2X%.2X", unpack(colors[1])), string.format("%.2X%.2X%.2X", unpack(colors[2])),
        string.format("%.2X%.2X%.2X", unpack(colors[3])), string.format("%.2X%.2X%.2X", unpack(colors[4]))
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