function dodaj_vozilo_u_db(vlasnik, model_id, cena)
    local db = exports.dbSistem.get_connection()

    local ok = dbExec(db, "INSERT INTO `nalog_vozilo` (`vlasnik_id`, `model_id`) VALUES(?, ?)", getElementData(vlasnik, "id", false), model_id)

    if not ok then
        triggerEvent("voziloSistem:voziloDBQuery", sourceResourceRoot, vlasnik, false)
    end


    dbQuery(

        function(qh, vlasnik, cena, sourceResourceRoot)
            local result, num_affected_rows, last_insert_id = dbPoll(qh, 0)
            
            triggerEvent("voziloSistem:voziloDBQuery", sourceResourceRoot, vlasnik, result, last_insert_id, cena)

        end,

        {vlasnik, cena, sourceResourceRoot},
        db,
        "SELECT * FROM `nalog_vozilo` WHERE vlasnik_id = ? AND model_id = ?", getElementData(vlasnik, "id", false), model_id
    )

end