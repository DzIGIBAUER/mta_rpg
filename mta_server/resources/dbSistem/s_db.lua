local RETRY_DELAY = get("retry_delay")
local db

local db_info = {
    name = getSystemEnvVariable("DB_NAME"),
    host = getSystemEnvVariable("DB_HOST"),
    user = getSystemEnvVariable("DB_USER"),
    pass = getSystemEnvVariable("DB_PASS")
}

-- Vraca db objekat, a ako nije validan pokrece ponovno povezivanje sa bazom podataka.
-- @return database connection element/nil
function get_connection()
    if not db then povezi_se(true) end
    return db
end

--- Povezuje se sa bazom podataka koristeci ENV promenljive koje ucitava pomocu 'ml_sysutils.so' modula.
-- https://github.com/4O4/mta-ml-sysutils
-- @param[opt] retry bool: Da li da pokusamo povezivanje ponovo ako ne predhodno bilo neuspesno.
local function povezi_se(retry)
    
    db = dbConnect("mysql", "dbname=".. db_info.name ..";host=".. db_info.host ..";charset=utf8", db_info.user, db_info.pass)

    if not db and retry then
        setTimer(povezi_se, RETRY_DELAY, 1, true)
    end

end
addEventHandler("onResourceStart", resourceRoot, povezi_se)