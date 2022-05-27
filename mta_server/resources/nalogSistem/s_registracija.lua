local imports = {
    policy = policy,
    pocetni = pocetni,
    posalji_poruku = posalji_poruku
}

Registracija = {}
Registracija.__index = Registracija


function Registracija.new(client, korisnicko_ime, lozinka)
    local self = setmetatable({}, Registracija)

    self.client = client
    self.korisnicko_ime = korisnicko_ime
    self.lozinka = lozinka

    self.db = exports.dbSistem.get_connection()
    if not self.db then
        return imports.posalji_poruku(client, "nalogSistem:registracijaNeuspesna", "Nije ostvarena veza sa bazom podataka.")
    end

    if not self:_input_valid() then return end

    self.azuriranje_db_co = coroutine.create(self._azuriraj_db)
    coroutine.resume(self.azuriranje_db_co, self)

    return self
end


function Registracija:_input_valid()
    if #self.korisnicko_ime < imports.policy.min_user_length or #self.korisnicko_ime > imports.policy.max_user_lenght then
        imports.posalji_poruku(
            self.client,
            "nalogSistem:registracijaNeuspesna",
            "Korisničko ime mora da bude duže od %s a kraće od %s karaktera.", imports.policy.min_user_length, imports.policy.max_user_lenght
        )
        return
    end

    if #self.lozinka < imports.policy.min_pass_length then
        imports.posalji_poruku(
            self.client,
            "nalogSistem:registracijaNeuspesna",
            "Lozinka mora da bude duža od %s karaktera.", imports.policy.min_pass_length
        )
        return
    end

    return true
end




function Registracija:_azuriraj_db()
    local zauzeto = self:_korisnicko_ime_zauzeto()
    if zauzeto then
        imports.posalji_poruku(self.client, "nalogSistem:registracijaNeuspesna", "Već postoji nalog sa tim korisničkim imenom. Izaberite drugo.")
        return
    end

    local uspesno, nalog_id = self:_sacuvaj_nalog()

    if not uspesno then
        imports.posalji_poruku(self.client, "nalogSistem:registracijaNeuspesna", "Došlo je do greške sa bazom podataka prilikom registracije vašeg naloga.")
        return
    end
    
    uspesno = self:_sacuvaj_igraca(nalog_id)
    if not uspesno then
        imports.posalji_poruku(self.client, "nalogSistem:registracijaNeuspesna", "Došlo je do greške sa bazom podataka prilikom registracije vašeg naloga.")
        dbExec(self.db, "DELETE FROM nalog WHERE id = ?", nalog_id)
        return        
    end

    imports.posalji_poruku(self.client, "nalogSistem:registracijaUspesna")
end



function Registracija:_korisnicko_ime_zauzeto()
    dbQuery(
        function(handle) self:_korisnicko_ime_zauzeto_query_done(handle) end,
        self.db, "SELECT EXISTS(SELECT id FROM nalog WHERE korisnicko_ime = ?)", self.korisnicko_ime
    )

    return coroutine.yield()
end

function Registracija:_korisnicko_ime_zauzeto_query_done(handle)
    local result, aff_rows, last_id = dbPoll(handle, 0)

    if result == false then
        local err_code, err_msg = aff_rows, last_id
        return imports.posalji_poruku(
            self.client,
            "nalogSistem:registracijaNeuspesna",
            "Došlo je do greške sa bazom podataka prilikom registracije vašeg naloga."
        )
    end

    local vec_postoji = select(2, next(result[1])) ~= 0

    coroutine.resume(self.azuriranje_db_co, vec_postoji)
end



function Registracija:_sacuvaj_nalog()
    passwordHash(self.lozinka, "bcrypt", {},
        function(hashed_password)
            dbQuery(
                function(handle) self:_nalog_query_done(handle) end,
                self.db, "INSERT INTO nalog (korisnicko_ime, lozinka) VALUES (?, ?)", self.korisnicko_ime, hashed_password
            )
        end
    )
    return coroutine.yield()
end

function Registracija:_nalog_query_done(handle)
        local result, aff_rows, last_id = dbPoll(handle, 0)

        if result == false then
            local err_code, err_msg = aff_rows, last_id
            return imports.posalji_poruku(
                client,
                "nalogSistem:registracijaNeuspesna",
                "Došlo je do greške sa bazom podataka prilikom registracije vašeg naloga."
            )
        end

        coroutine.resume(self.azuriranje_db_co, type(result) == "table", last_id)
end



function Registracija:_igrac_query_done(handle)
    local result, aff_rows, last_id = dbPoll(handle, 0)

    if result == false then
        local err_code, err_msg = aff_rows, last_id
        return imports.posalji_poruku(
            client,
            "nalogSistem:registracijaNeuspesna",
            "Došlo je do greške sa bazom podataka prilikom registracije vašeg naloga."
        )
    end

    coroutine.resume(self.azuriranje_db_co, type(result) == "table")
end

function Registracija:_sacuvaj_igraca(nalog_id)
    dbQuery(
        function(handle) self:_igrac_query_done(handle) end,
        self.db, "INSERT INTO igrac (pos_x, pos_y, pos_z, rot_x, rot_y, rot_z, model_id, novac, nalog_id) VALUES (?,?,?,?,?,?,?,?,?)",
        imports.pocetni.spawn.pos_x, imports.pocetni.spawn.pos_y, imports.pocetni.spawn.pos_z,
        imports.pocetni.spawn.rot_x, imports.pocetni.spawn.rot_y, imports.pocetni.spawn.rot_z,
        imports.pocetni.model_id, imports.pocetni.novac, nalog_id
    )
    return coroutine.yield()
end



local function _register_pokusaj(korisnicko_ime, lozinka)
    Registracija.new(client, korisnicko_ime, lozinka)
end
addEvent("nalogSistem:registerPokusaj", true)
addEventHandler("nalogSistem:registerPokusaj", resourceRoot, _register_pokusaj)