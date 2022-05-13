local db

function get_connection() return db end

--- Povezuje se sa bazom podataka koristeci ENV promenljive koje ucitava pomocu 'ml_sysutils.so' modula.
-- https://github.com/4O4/mta-ml-sysutils
-- @return database connection element/nil
local function povezi_se()
    local db_name = getSystemEnvVariable("DB_NAME")
    local db_host = getSystemEnvVariable("DB_HOST")
    local db_user = getSystemEnvVariable("DB_USER")
    local db_pass = getSystemEnvVariable("DB_PASS")
    db = dbConnect("mysql", "dbname=".. db_name ..";host=".. db_host ..";charset=utf8", db_user, db_pass)

    if not db then
        iprint("Nije uspostavljena veza ka bazi podataka.")
    end

end
addEventHandler("onResourceStart", resourceRoot, povezi_se)