local policy = {
    maxPassLength = tonumber(get("maxPassLength")),
    minPassLength = tonumber(get("minPassLength")),
    maxUserLength = tonumber(get("maxUserLength")),
    minUserLength = tonumber(get("minUserLength"))
}

local function posaljiPoruku(client, event, poruka, ...)
    if poruka then
        poruka = string.format(poruka, arg)
    end
    triggerClientEvent(client, event, client, poruka)
end

local function loginPokusaj(username, lozinka)
    local db = exports["dbSistem"].get_connection()
    if not db then
        return posaljiPoruku(client, "onLoginNeuspesan", "Nije ostvarena veza sa bazom podataka.")

    end

    local client = client

    dbQuery(function(handle)
        local result, affRows, lastID = dbPoll(handle, 0)

        if handle == false then
            local errCode, errMsg = affRows, lastID
            return posaljiPoruku(
                client,
                "onLoginNeuspesan",
                "Došlo je do greške sa bazom podataka. Error code %s.", errCode
            )
        end

        if next(result) == nil then
            return posaljiPoruku(client, "onLoginNeuspesan", "Nepostoji nalog sa tim korisničkim imenom.")
        end

        passwordVerify(lozinka, result[1].lozinka, function(matches)
            if not matches then
                return posaljiPoruku(client, "onLoginNeuspesan", "Netačna lozinka.")
            end

            posaljiPoruku(client, "onLoginUspesan")
            result[1].id = nil -- imamo nalogID vec, ne treba nam 2 puta a uzeo sam sve sa '*' u sql komandi
            result[1].lozinka = nil -- vise nam ne treba
            
            triggerEvent("igracSistem:igracUlogovan", client, result[1])
            

            dbExec(db, "UPDATE nalog SET zadnjaPrijava = CURRENT_TIMESTAMP() WHERE id = ?", result[1].id)

        end)

    end, db, "SELECT * FROM nalog n INNER JOIN igrac i ON i.nalogID = n.id AND n.ime = ?", username)

end
addEvent("onLoginPokusaj", true)
addEventHandler("onLoginPokusaj", resourceRoot, loginPokusaj)

local function registerPokusaj(username, lozinka)
    if #username < policy.minUserLength or #username > policy.maxUserLength then
        return posaljiPoruku(
            client,
            "onRegistracijaNeuspesna",
            "Korisničko ime mora da bude duže od %s a kraće od %s karaktera.", policy.minUserLength, policy.maxUserLength
        )
    end

    if #lozinka < policy.minPassLength or #username > policy.maxUserLength then
        return posaljiPoruku(
            client,
            "onRegistracijaNeuspesna",
            "Lozinka mora da bude duža od %s a kraća od %s karaktera.", policy.minPassLength, policy.maxPassLength
        )
    end

    local db = exports["dbSistem"].get_connection()
    if not db then
        return posaljiPoruku(client, "onRegistracijaNeuspesna", "Nije ostvarena veza sa bazom podataka.")
    end

    local client = client

    local function lozinkaSpremna(hashedPassword)
        dbQuery(function(handle)
            local result, affRows, lastID = dbPoll(handle, 0)

            if handle == false then
                local errCode, errMsg = affRows, lastID
                return posaljiPoruku(
                    client,
                    "onRegistracijaNeuspesna",
                    "Došlo je do greške sa bazom podataka prilikom registracije vašeg naloga. Error code %s.", errCode
                )
            end

            posaljiPoruku(client, "onRegistracijaUspesna")

        end, db, "INSERT INTO nalog (ime, lozinka) VALUES (?, ?)", username, hashedPassword)
    end

    local function preoveraUnikatnosti(handle)
        local result, affRows, lastID = dbPoll(handle, 0)

        if handle == false then
            local errCode, errMsg = affRows, lastID
            return posaljiPoruku(
                client,
                "onRegistracijaNeuspesna",
                "Došlo je do greške sa bazom podataka. Error code %s.", errCode
            )
        end

        if select(2, next(result[1])) ~= 0 then
            return posaljiPoruku(client, "onRegistracijaNeuspesna", "Već postoji nalog sa tim korisničkim imenom. Izaberite drugo.")
        end

        passwordHash(lozinka, "bcrypt", {}, lozinkaSpremna)
    end
    dbQuery(preoveraUnikatnosti, db, "SELECT EXISTS(SELECT * FROM nalog WHERE ime = ?)", username)

end
addEvent("onRegisterPokusaj", true)
addEventHandler("onRegisterPokusaj", resourceRoot, registerPokusaj)


addEvent("onClientTraziPolicyInfo", true)
addEventHandler("onClientTraziPolicyInfo", resourceRoot, function()
    triggerClientEvent("onClientPolicyInfo", resourceRoot, policy)
end)