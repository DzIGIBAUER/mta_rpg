policy = {
    min_pass_length = tonumber(get("minPassLength")),
    max_user_lenght = tonumber(get("maxUserLength")),
    min_user_length = tonumber(get("minUserLength"))
}

pocetni = {
    spawn = {
        pos_x = tonumber(get("pocetniPosX")),
        pos_y = tonumber(get("pocetniPosY")),
        pos_z = tonumber(get("pocetniPosZ")),
        rot_x = tonumber(get("pocetniRotX")),
        rot_y = tonumber(get("pocetniRotY")),
        rot_z = tonumber(get("pocetniRotZ")),
    },  
    novac = tonumber(get("pocetniNovac")),
    model_id = tonumber(get("pocetniModel"))
}



--- Proverava da li su opcije kao sto su pocetni spawn, novac itd. definisane u meta.xml fajlu.
local function _proveri_pocetne_opcije(_)
    local potrebno = {"pocetniPosX", "pocetniPosY", "pocetniPosZ", "pocetniRotX", "pocetniRotY", "pocetniRotZ", "pocetniNovac", "pocetniModel"}

    for _, setting in ipairs(potrebno) do
        if not get(setting) then
            outputDebugString(string.format("Opcija %s nije definisana u 'meta.xml' fajlu. Resurs: %s", setting, getResourceName(resource)))
        end
    end

end
addEventHandler("onResourceStart", resourceRoot, _proveri_pocetne_opcije)



--- Helper funkcije za lakse slanju poruke clientu
-- @param client player: Kome saljemo.
-- @param event string: Ime eventa.
-- @param poruka string: Poruka koju saljemo
-- @param[opt] ... string: poruka ce da bude formatirana sa ovi argumentima.
function posalji_poruku(client, event, poruka, ...)
    if poruka then
        poruka = string.format(poruka, ...)
    end
    triggerClientEvent(client, event, client, poruka)
end



--- Provarava da li je igrac uneo tacnu lozinku za datog korisnika.
local function _procces_login_query(handle, db, client, uneta_lozinka)
    local result, aff_rows, last_id = dbPoll(handle, 0)

    if handle == false then
        local err_code, err_msg = aff_rows, last_id
        return posalji_poruku(
            client,
            "nalogSistem:loginNeuspesan",
            "Došlo je do greške sa bazom podataka."
        )
    end

    if next(result) == nil then
        return posalji_poruku(client, "nalogSistem:loginNeuspesan", "Netačno korisničko ime ili lozinka.")
    end

    passwordVerify(uneta_lozinka, result[1].lozinka, function(matches)
        if not matches then
            return posalji_poruku(client, "nalogSistem:loginNeuspesan", "Netačno korisničko ime ili lozinka.")
        end

        posalji_poruku(client, "nalogSistem:loginUspesan")
        result[1].lozinka = nil -- vise nam ne treba

        triggerEvent("igracSistem:igracUlogovan", client, result[1])

        dbExec(db, "UPDATE nalog SET zadnji_login = CURRENT_TIMESTAMP() WHERE id = ?", result[1].nalog_id)
    end)
end

--- Kada igrac pokusa da se uloguje.
local function _login_pokusaj(username, uneta_lozinka)
    local db = exports.dbSistem.get_connection()
    if not db then
        return posalji_poruku(client, "nalogSistem:loginNeuspesan", "Nije ostvarena veza sa bazom podataka.")
    end

    local client = client

    dbQuery(
        _procces_login_query,
        {db, client, uneta_lozinka},
        db,
        "SELECT * FROM nalog INNER JOIN igrac ON nalog.id = igrac.nalog_id AND nalog.korisnicko_ime = ?", username
    )
end
addEvent("nalogSistem:loginPokusaj", true)
addEventHandler("nalogSistem:loginPokusaj", resourceRoot, _login_pokusaj)





local function _igrac_resurs_pokrenut(pokrenut_resurs)
    if pokrenut_resurs ~= resource and not getElementData(source, "id", false) then return end

    triggerClientEvent("nalogSistem:clientPolicyInfo", resourceRoot, policy)
end
addEventHandler("onPlayerResourceStart", root, _igrac_resurs_pokrenut)
