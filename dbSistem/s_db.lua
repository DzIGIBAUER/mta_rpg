local db

function getConnection() return db end

local function poveziSe()
    db = dbConnect("mysql", "dbname=".. dbName ..";host=".. host ..";charset=utf8", user, pass)

    if not db then
        iprint("nije uspostavljena veza")
    end

end
addEventHandler("onResourceStart", resourceRoot, poveziSe)