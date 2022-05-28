local imports = {
    policy = policy,
    pocetni = pocetni,
    posalji_poruku = posalji_poruku
}

Login = {}
Login.__index = Login

--- Konstruktor za objekat koji ce autentikovati korisnika i obavestiti ga o procesu.
-- Koristi coroutine(kao async) tako da kada ova funkcija vrati vrednost autentikacije jos nije gotova.
-- @param client player: Igrac koji pokusava da se uloguje.
-- @param korisnicko_ime string:
-- @param lozinka string:
-- @return table: ovaj objekat.
function Login.new(client, korisnicko_ime, lozinka)
    self = setmetatable({}, Login)

    self._db_result = nil

    self.client = client
    self.korisnicko_ime = korisnicko_ime
    self.lozinka = lozinka

    self.db = exports.dbSistem.get_connection()
    if not self.db then
        return imports.posalji_poruku(client, "nalogSistem:loginNeuspesan", "Nije ostvarena veza sa bazom podataka.")
    end

    self.uloguj_igraca_co = coroutine.create(self._uloguj_igraca)
    coroutine.resume(self.uloguj_igraca_co, self)

    return self
end


--- Metoda koja se koristi za coroutine.create, tako da je ne pozivamo direktno,
-- vec pozivamo coroutine.resume. Metoda je async, kao i svaka pozvana odavde.
-- Proverava da li postoji nalog sa datim korsnickim imenom,da li je uneta lozinka tacna
-- i azurira poslednji login u bazi podataka.
function Login:_uloguj_igraca()
    local nalog_info = self:_get_nalog_info()
    if not nalog_info then
        return imports.posalji_poruku(self.client, "nalogSistem:loginNeuspesan", "Netačno korisničko ime ili lozinka.")
    end

    self._db_result = nalog_info

    local lozinka_tacna = self:_lozinka_tacna()
    if not lozinka_tacna then
        return imports.posalji_poruku(self.client, "nalogSistem:loginNeuspesan", "Netačno korisničko ime ili lozinka.")
    end


    imports.posalji_poruku(self.client, "nalogSistem:loginUspesan")
    self._db_result.lozinka = nil -- vise nam ne treba

    triggerEvent("igracSistem:igracUlogovan", self.client, self._db_result)

    dbExec(self.db, "UPDATE nalog SET poslednji_login = CURRENT_TIMESTAMP() WHERE id = ?", self._db_result.nalog_id)
end


--- Salje zahtev bazi podataka za informacije naloga i igraca,
-- zatim zaustavlja coroutine dok ne dobijemo rezultate.
-- return table/nil: informacije igraca.(Prosledju je nam coroutine.resume)
function Login:_get_nalog_info()
    dbQuery(
        function(handle) self:_get_nalog_info_query_done(handle) end,
        self.db, "SELECT * FROM nalog INNER JOIN igrac ON nalog.id = igrac.nalog_id AND nalog.korisnicko_ime = ?", self.korisnicko_ime
    )
    return coroutine.yield()
end


--- Ovde dobijamo rezultate o informacijama naloga i igraca,
-- zatim nastavljamo coroutine i prosledjujemo info iz db.
-- @param handle db_handle:
function Login:_get_nalog_info_query_done(handle)
    local result, aff_rows, last_id = dbPoll(handle, 0)

    if result == false then
        local err_code, err_msg = aff_rows, last_id
        return imports.posalji_poruku(
            self.client,
            "nalogSistem:loginNeuspesan",
            "Došlo je do greške sa bazom podataka prilikom pokusaja logina."
        )
    end

    local nalog_info = result[1]

    coroutine.resume(self.uloguj_igraca_co, nalog_info)
end

--- Proverava unetu lozinku i hash iz db, zaustavlja coroutine.
-- Kada rezultat stigne nstavlja coroutine i prosledjuje da li se podudaraju.
-- @return bool: Da li se lozinke poklapaju.
function Login:_lozinka_tacna()
    passwordVerify(self.lozinka, self._db_result.lozinka, function(matches)
        coroutine.resume(self.uloguj_igraca_co, matches)
    end)

    return coroutine.yield()
end



local function _login_pokusaj(korisnicko_ime, loznka)
    Login.new(client, korisnicko_ime, loznka)
end
addEvent("nalogSistem:loginPokusaj", true)
addEventHandler("nalogSistem:loginPokusaj", resourceRoot, _login_pokusaj)
