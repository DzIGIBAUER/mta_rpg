local MAX_VOZILA_U_PROVERI = 50 -- koliko vozila u jednoj proveri, tj. jednom foor loop-u
local REST_TIME = 1000 -- koliko vremena izmedju foor loop-ova.

local POTROSNJA = (5.5 / 100) / 1000 --- l/m

-- key: vozilo element, value {gorivo=int, zadnja_provera=float}
local vozila = {}


function namesti_gorivo(vozilo, kolicina)
    vozila[vozilo] = {
        gorivo = kolicina,
        zadnja_provera = getTickCount()
    }
end


local function izracunaj_potroseno_gorivo(vozilo)
    local vozilo_info = vozila[vozilo]
    if not vozilo_info then
        outputDebugString(string.format("Vozilo %s za koje izracunavamo gorivo nije dodato u tabelu vozila.", vozilo))
        return false
    end

    local trenutno_vreme = getTickCount()

    local proteklo_vreme = (trenutno_vreme - vozilo_info.zadnja_provera) * 100

    vozilo_info.zadnja_provera = trenutno_vreme

    --- (Vector3(getElementVelocity(vozilo)) * 180).length ==> km/h
    -- 180km/h / 1000 ==> 0.18m/h / 60 ==> 0.003m/s
    local trenutna_brzina = (Vector3(getElementVelocity(vozilo)) * 0.003).length

    --- trenutna_brzina * proteklo_vreme ===> predjeni put u metrima.
    -- POTROSNJA u l/m * predjeni put ===> portoseno goriva.
    return trenutna_brzina * proteklo_vreme * POTROSNJA
end


local function pokreni_proveru(max_provera)
    local odradjenih_provera = 0

    for vozilo, vozilo_info in pairs(vozila) do
        if odradjenih_provera >= max_provera then
            coroutine.yield()
            odradjenih_provera = 0
        end

        if vozilo_info.gorivo == 0 then return end

        if getVehicleEngineState(vozilo) then
            local potroseno = izracunaj_potroseno_gorivo(vozilo)
            vozilo_info.gorivo = vozilo_info.gorivo - potroseno

            if vozilo_info.gorivo < 0 then
                vozilo_info.gorivo = 0
                setVehicleEngineState(vozilo, false)
            end

            local vozac = getVehicleController(vozilo)
            if vozac then
                triggerClientEvent(vozac, "voziloSistem:gorivoKolicinaPromenjena", vozilo, vozilo_info.gorivo)
            end
        end

        odradjenih_provera = odradjenih_provera + 1
    end
end


local function main()

    local pokreni_proveru_co

    setTimer(
        function()
            if next(vozila) == nil then return end
            
            if not pokreni_proveru_co or coroutine.status(pokreni_proveru_co) == "dead" then
                pokreni_proveru_co = coroutine.create(pokreni_proveru)
            end

            coroutine.resume(pokreni_proveru_co, MAX_VOZILA_U_PROVERI)

        end,
        REST_TIME,
        0
    )
end

local function _resurs_pokrenut(_pokrenut_resurs)
    main()
end
addEventHandler("onResourceStart", resourceRoot, _resurs_pokrenut)