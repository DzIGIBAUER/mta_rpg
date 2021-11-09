loadstring(exports.dgs:dgsImportFunction())()

local salonInfo

local window
local voziloInfoLabel

local prikazanoVoziloElement
local prikazanoVoziloIdx = 0

-- index pozicija salona u salonInfo array-u u kom se trenutno nalazimo
local salonIdx


--[[ PRIKUPLJANJE INORMACIJA O SOLANIMA ]]
local function sacuvajSalonInfo(sinfo)
    salonInfo = sinfo
end
addEvent("onSalonInfo", true)
addEventHandler("onSalonInfo", resourceRoot, sacuvajSalonInfo)

local function traziSalonInfo()
    triggerServerEvent("onClientTraziSalonInfo", localPlayer)
end
addEventHandler("onClientResourceStart", resourceRoot, traziSalonInfo)



--[[ SALTANJE VOZILA U SALONU ]]
local function saltajVozilo(strana)
    local noviIdx
    if strana == "levo" then
        noviIdx = prikazanoVoziloIdx - 1
    else
        noviIdx = prikazanoVoziloIdx + 1
    end

    local vinfo = salonInfo[salonIdx]["vozila"][noviIdx]
    
    -- ako nema vozila sa tim indexom(ako idemo desno stigli smo do kraja, a levo do pocetka)
    if not vinfo then return end

    if isElement(prikazanoVoziloElement) then
        destroyElement(prikazanoVoziloElement)
    end

    local voziloPreview = salonInfo[salonIdx].voziloPreview

    prikazanoVoziloElement = createVehicle(vinfo.model, voziloPreview.x, voziloPreview.y, voziloPreview.z)
    setVehicleColor(prikazanoVoziloElement, 255, 255, 255)

    prikazanoVoziloIdx = noviIdx

    dgsSetText(voziloInfoLabel, getVehicleNameFromModel(vinfo.model) .." (".. vinfo.cena .."$)")

end

local function kupiVozilo()
    if not isElement(prikazanoVoziloElement) or getElementType(prikazanoVoziloElement) ~= "vehicle" then
        return outputDebugString("Kupovina je pokrenuta bez izabranog vozila.")
    end

    local vinfo = salonInfo[salonIdx]["vozila"][prikazanoVoziloIdx]

    if vinfo.cena > getPlayerMoney() then
        return triggerEvent(
            "notifikacija",
            localPlayer,
            "obavestenje",
            "Nemate dovoljno novca.",
            string.format("Nemate dovoljno novca da kupite željeno vozilo. Fali vam %s$", vinfo.cena - getPlayerMoney())
        )
    end

    triggerServerEvent("onVoziloKupovina", resourceRoot, salonIdx, vinfo.model)

end



--[[ GUI ]]
local function napustiGUI()
    destroyElement(window)

    destroyElement(prikazanoVoziloElement)
    prikazanoVoziloIdx = 0
    salonIdx = nil

    showCursor(false, false)        
    setCameraTarget(localPlayer)
end

local function prikaziKupovinaGUI()

    window = dgsCreateWindow(0.3, 0.80, 0.4, 0.2, "", true, nil, 0, nil, nil, nil, nil, nil, true)  
    dgsSetProperty(window, "sizable", false)

    local nazadDugme = dgsCreateButton(0, 0, 0.1, 0.5, "<", true, window, nil, 2, 2)
    voziloInfoLabel = dgsCreateLabel(0.4, 0, 0.2, 0.5, "IME VOZILA", true, window, nil, 2, 2, nil, nil, nil, "center", "center")
    local napredDugme = dgsCreateButton(0.9, 0, 0.1, 0.5, ">", true, window, nil, 2, 2)
    local kupiDugme = dgsCreateButton(0.8, 0.7, 0.2, 0.3, "Kupi", true, window)

    local exitDugme = dgsCreateButton(0, 0.7, 0.2, 0.3, "Napusti", true, window)


    addEventHandler("onDgsMouseClickUp", kupiDugme, function(button)
        if button ~= "left" then return end
        kupiVozilo()
    end, false)

    addEventHandler("onDgsMouseClickUp", napredDugme, function(button)
        if button ~= "left" then return end
        saltajVozilo("desno")
    end, false)

    addEventHandler("onDgsMouseClickUp", nazadDugme, function(button)
        if button ~= "left" then return end
        saltajVozilo("levo")
    end, false)

    addEventHandler("onDgsMouseClickUp", exitDugme, function(button)
        if button ~= "left" then return end
        napustiGUI()
    end, false)
end

local function markerHit(hitPlayer, matchingDimension)
    if hitPlayer ~= localPlayer or not matchingDimension or getPedOccupiedVehicle(localPlayer) then return end

    local sinfo

    -- trazimo salonInfo ciji markerElement je marker u koji smo usli
    for idx, s in ipairs(salonInfo) do
        if s.markerElement == source then
            salonIdx = idx
            sinfo = s
        end
    end

    setCameraMatrix(
        sinfo.cameraPos.x, sinfo.cameraPos.y, sinfo.cameraPos.z,
        sinfo.voziloPreview.x, sinfo.voziloPreview.y, sinfo.voziloPreview.z
    )

    showCursor(true, true)

    prikaziKupovinaGUI()
    saltajVozilo("desno")
end
addEventHandler("onClientMarkerHit", resourceRoot, markerHit)

addEvent("onClientVoziloKupljeno", true)
addEventHandler("onClientVoziloKupljeno", resourceRoot, napustiGUI)