local db

function get_connection() return db end

-- TODO: koristi .env.
--- Povezuje se sa bazom podataka koristeci 'DB_NAME', 'HOSTNAME', 'USERNAME' i 'PASSWORD',
-- koji treba da budu definisani u scope-u izvan funkcije tj. u 's_config.lua' fajlu.
-- @return database connection element/nil
local function povezi_se()
    db = dbConnect("mysql", "dbname=".. DB_NAME ..";host=".. HOSTNAME ..";charset=utf8", USERNAME, PASSWORD)

    if not db then
        iprint("nije uspostavljena veza")
    end

end
addEventHandler("onResourceStart", resourceRoot, povezi_se)