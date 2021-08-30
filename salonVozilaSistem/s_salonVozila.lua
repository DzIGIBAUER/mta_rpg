-- ako dva igraca posalju zahtev za salonInfo za manje od 'vremeCekanja'
-- necemo poslati 2 razlicita zahteva vec cemo ih spojiti u jedan
local vremeCekanja = 200
local cekaju = {}

local function namestiSalone()
    for i, salonInfo in ipairs(saloni) do
        salonInfo["markerElement"] = createMarker(salonInfo.markerPos.x, salonInfo.markerPos.y, salonInfo.markerPos.z, "cylinder", 1.5, 255, 255, 20)
    end

end
addEventHandler("onResourceStart", resourceRoot, namestiSalone)


local function posaljiSalonInfo()
    local zaClient = {}

    for sindex, salonInfo in ipairs(saloni) do
        local vinfo = {}
        
        for i, v in ipairs(tipoviVozila[salonInfo.tipVozila]) do
            vinfo[i] = {
                ["model"] = v,
                ["cena"] = cenaVozila[v]
            }
        end

        zaClient[sindex] = {
            ["markerElement"] = salonInfo.markerElement,
            ["voziloPreview"] = salonInfo.voziloPreview,
            ["cameraPos"] = salonInfo.cameraPos,
            ["vozila"] = vinfo
        }

    end

    triggerClientEvent(cekaju, "onSalonInfo", resourceRoot, zaClient)
    cekaju = {} -- ispraznimo array posto smo im poslali informacije

end

local function clientTraziSalonInfo()
    if not client then return end

    if next(cekaju) == nil then
        setTimer(posaljiSalonInfo, vremeCekanja, 1)
    end

    table.insert(cekaju, client)

end
addEvent("onClientTraziSalonInfo", true)
addEventHandler("onClientTraziSalonInfo", root, clientTraziSalonInfo)


local function voziloUPonudi(salonIdx, voziloModelID)
    -- tip vozila koja se prodaju u salonu
    local tipVozila = saloni[salonIdx]["tipVozila"]

    -- da li salon ima to vozilo u ponudi
    for _, mid in ipairs(tipoviVozila[tipVozila]) do
        if mid == voziloModelID then
            return true
        end
    end

    return false
end

local function voziloKupovina(salonIdx, voziloModelID)
    
    if not voziloUPonudi(salonIdx, voziloModelID) then
        return triggerClientEvent(
            client,
            "notifikacija",
            client,
            "greska",
            "Vozilo nije u ponudi",
            string.format("Vozilo marke %s nije u ponudi ovog salona.", getVehicleNameFromModel(voziloModelID)))
    end

    local cenaVozila = cenaVozila[voziloModelID]
    if cenaVozila > getPlayerMoney(client) then
        return triggerClientEvent(
            client,
            "notifikacija",
            client,
            "obavestenje",
            "Nemate dovoljno novca",
            string.format("Nemate dovoljno novca da kupite željeno vozilo. Fali vam %s$.", vinfo.cena - getPlayerMoney())
        )
    end

    local db = exports["dbSistem"].getConnection()
    if not db then
        return triggerClientEvent(
            client,
            "notifikacija",
            client,
            "greska",
            "Greška sa bazom podataka",
            "Došlo je do greške sa bazom podataka."
        )
    end

    local voziloSpawn = saloni[salonIdx].voziloSpawn

    -- ime kolone u bazi podataka i vrednost
    local args = {
        ["model"] = voziloModelID,
        ["vlasnik"] = getElementData(client, "nalogID", false),
        ["spawnX"] = voziloSpawn.x,
        ["spawnY"] = voziloSpawn.y,
        ["spawnZ"] = voziloSpawn.z,
        ["rotX"] = voziloSpawn.rx,
        ["rotY"] = voziloSpawn.ry,
        ["rotZ"] = voziloSpawn.rz
    }

    local kolone = {}
    local vrednosti = {}



    local n = 0 -- brze je od table.insert
    for kolona, vrednost in pairs(args) do
        n = n + 1
        kolone[n] = kolona
        vrednosti[n] = vrednost
    end

    dbQuery(function(handle, client)
        local result, affRows, lastID = dbPoll(handle, 0)

        if handle == false or not result then
            local errCode, errMsg = affRows, lastID -- log ovo?
            return triggerClientEvent(
                client,
                "notifikacija",
                client,
                "greska",
                "Greška sa bazom podataka",
                "Došlo je do greške sa bazom podataka."
            )
        end

        takePlayerMoney(client, cenaVozila)
        
        local vozilo = createVehicle(voziloModelID, 0, 0, -50)
        spawnVehicle(vozilo, voziloSpawn.x, voziloSpawn.y, voziloSpawn.z, voziloSpawn.rx, voziloSpawn.ry, voziloSpawn.rz)
        
        triggerClientEvent(
                client,
                "notifikacija",
                client,
                "uspesno",
                "Vozilo kupljeno",
                string.format("Uspešno ste kupili vozilo marke %s.", getVehicleNameFromModel(voziloModelID))
            )

        args["voziloID"] = lastID -- ovo polje je PRIMARY KEY i AUTO_INCREMENT, pa ga ne dodajemo u query
        
        -- posaljemo odmah ako nekoj skripri treba, da ne bi morali da uzimamo iz baze podataka kad vec imamo ovde
        triggerEvent("onVoziloKupljeno", client, args)
        -- ovo saljemo clientu koji je kupio vozila kako bi izasao iz GUI salona
        triggerClientEvent(client, "onClientVoziloKupljeno", resourceRoot)

    end, {client}, db, "INSERT INTO vozilo (".. table.concat(kolone, ", ") ..") VALUES (?, ?, ?, ?, ?, ?, ?, ?)", unpack(vrednosti))


end
addEvent("onVoziloKupovina", true)
addEventHandler("onVoziloKupovina", resourceRoot, voziloKupovina)