local policy = {
    min_pass_length = tonumber(get("minPassLength")),
    max_user_lenght = tonumber(get("maxUserLength")),
    min_user_length = tonumber(get("minUserLength"))
}

--- Helper funkcije za lakse slanju poruke clientu
-- @param client player: Kome saljemo.
-- @param event string: Ime eventa.
-- @param poruka string: Poruka koju saljemo
local function posalji_poruku(client, event, poruka)
    if poruka then
        poruka = string.format(poruka, arg)
    end
    triggerClientEvent(client, event, client, poruka)
end

--- Kada igrac pokusa da se uloguje.
local function _login_pokusaj(username, lozinka)
    local db = exports.dbSistem.get_connection()
    if not db then
        return posalji_poruku(client, "igracSistem:loginNeuspesan", "Nije ostvarena veza sa bazom podataka.")
    end

    local client = client

    dbQuery(function(handle)
        local result, aff_rows, last_id = dbPoll(handle, 0)

        if handle == false then
            local err_code, err_msg = aff_rows, last_id
            return posalji_poruku(
                client,
                "igracSistem:loginNeuspesan",
                "Došlo je do greške sa bazom podataka. Error code %s.", err_code
            )
        end

        if next(result) == nil then
            return posalji_poruku(client, "igracSistem:loginNeuspesan", "Netačno korisničko ime ili lozinka.")
        end

        iprint(result)
        iprint(#result)

        passwordVerify(lozinka, result[1].lozinka, function(matches)
            if not matches then
                return posalji_poruku(client, "igracSistem:loginNeuspesan", "Netačno korisničko ime ili lozinka.")
            end

            posalji_poruku(client, "onLoginUspesan")
            result[1].id = nil -- imamo nalogID vec, ne treba nam 2 puta a uzeo sam sve sa '*' u sql komandi
            result[1].lozinka = nil -- vise nam ne treba

            triggerEvent("igracSistem:igracUlogovan", client, result[1])


            dbExec(db, "UPDATE nalog SET zadnji_login = CURRENT_TIMESTAMP() WHERE id = ?", result[1].id)

        end)

    end, db, "SELECT * FROM nalog INNER JOIN igrac ON nalog.id = igrac.nalog_id AND nalog.korisnicko_ime = ?", username)
end
addEvent("igracSistem:loginPokusaj", true)
addEventHandler("igracSistem:loginPokusaj", resourceRoot, _login_pokusaj)

--- Kada igrac pokusa da se registruje.
local function _register_pokusaj(username, lozinka)
    if #username < policy.min_user_length or #username > policy.max_user_lenght then
        return posalji_poruku(
            client,
            "igracSistem:registracijeNeuspesna",
            "Korisničko ime mora da bude duže od %s a kraće od %s karaktera.", policy.min_user_length, policy.max_user_lenght
        )
    end

    if #lozinka < policy.minPassLength or #username > policy.maxUserLength then
        return posalji_poruku(
            client,
            "igracSistem:registracijeNeuspesna",
            "Lozinka mora da bude duža od %s karaktera.", policy.min_pass_length
        )
    end

    local db = exports.dbSistem.get_connection()
    if not db then
        return posalji_poruku(client, "igracSistem:registracijeNeuspesna", "Nije ostvarena veza sa bazom podataka.")
    end

    local client = client

    local function lozinka_spremna(hashed_password)
        dbQuery(function(handle)
            local result, aff_rows, last_id = dbPoll(handle, 0)

            if handle == false then
                local err_code, err_msg = aff_rows, last_id
                return posalji_poruku(
                    client,
                    "igracSistem:registracijeNeuspesna",
                    "Došlo je do greške sa bazom podataka prilikom registracije vašeg naloga. Error code %s.", err_code
                )
            end

            posalji_poruku(client, "igracSistem:registracijaUspesna")

        end, db, "INSERT INTO nalog (korisnicko_ime, lozinka) VALUES (?, ?)", username, hashed_password)
    end

    local function preovera_unikatnosti(handle)
        local result, aff_rows, last_id = dbPoll(handle, 0)
        if handle == false then
            local err_code, err_msg = aff_rows, last_id
            return posalji_poruku(
                client,
                "igracSistem:registracijeNeuspesna",
                "Došlo je do greške sa bazom podataka. Error code %s.", err_code
            )
        end
        if select(2, next(result[1])) ~= 0 then
            return posalji_poruku(client, "igracSistem:registracijeNeuspesna", "Već postoji nalog sa tim korisničkim imenom. Izaberite drugo.")
        end

        passwordHash(lozinka, "bcrypt", {}, lozinka_spremna)
    end
    dbQuery(preovera_unikatnosti, db, "SELECT EXISTS(SELECT id FROM nalog WHERE korisnicko_ime = ?)", username)
end
addEvent("igracSistem:registerPokusaj", true)
addEventHandler("igracSistem:registerPokusajPokusaj", resourceRoot, _register_pokusaj)

local function _igrac_resurs_pokrenut(pokrenut_resurs)
    if pokrenut_resurs ~= resource and getElementData(source, "id", false) then return end

    triggerClientEvent("igracSistem:clientPolicyInfo", resourceRoot, policy)
end
addEventHandler("onPlayerResourceStart", root, _igrac_resurs_pokrenut)
