local FILE_PATH = "preferences/userData.xml"

--- Ucitava XML fajl kao string.
-- @return string: Ucitan XML fjal.
local function ucitaj_xml()
    local file = nil

    if fileExists(FILE_PATH) then
        file = fileOpen(FILE_PATH, true)
    else
        error(string.format("userBinds: Nije pronadjen fajl %s.", FILE_PATH))
    end

    local file_data = fileRead(file, fileGetSize(file))
    fileClose(file)

    return file_data
end

--- Ucitava XML fajl kao string i salje ga korisniku,
-- ili prikazuje notifikaciju korisniku.
-- @param[opt] ... any: Argumenti koje ce server proslediti sa ucitanim XML fajlom
-- i zavisi od implementacije handler funkcije za ovaj event na strani clienta.
-- Vidi 'c_obnovi.lua'.
local function _posalji_xml_string(...)

    local file_data = ucitaj_xml()
    if not file_data then
        return triggerClientEvent(
            "igracSistem:notifikacija",
            client,
            "greska",
            "Greška sa vašim postavkama",
            "Server nije uspeo da vam dostavi fajl sa postavkama. Ukoliko vaše postavke ne funkcionišu, pokušajte da se rekonektujete na server."
        )
    end
    
   triggerClientEvent(client, "userBinds:serverPosaloStandardnePostavke", resourceRoot, file_data, unpack({...}) )

end
addEvent("userBinds:clientTraziStandardnePostavke", true)
addEventHandler("userBinds:clientTraziStandardnePostavke", resourceRoot, _posalji_xml_string)