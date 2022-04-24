--[[

NE DOKUMENTUJEM. MENJAMO SA CEF-OM, SVAKAKO.

]]
loadstring(exports.dgs:dgsImportFunction())()

--[[ UI ]]
local prikazan_ui = "register" -- login ili register
local switch_duration = 150 -- ms
local login_elementi = {}
local register_elementi = {}

--[[ POLICY ]]
local policy -- tabela. Od servera dobijemo minPassLength, maxPassLength, minUserLength, maxUserLength


local function fade_change_text(label, novi_text)
    dgsAlphaTo(label, 0, false, "Linear", switch_duration)
    if novi_text and novi_text ~= "" then
        setTimer(function()
            dgsSetText(label, novi_text)
            dgsAlphaTo(label, 1, false, "Linear", switch_duration)
        end, switch_duration, 1)
    end
end

local function prikaziLoginUI(prikazi)
    if prikazi == nil then prikazi = true end

    if prikazi then
        prikazan_ui = "login"
        fade_change_text(headerLabel, "Login")
        dgsSetText(switchBtn, "Registruj se")
        fade_change_text(tipLabel, "Nemate nalog? Registrujte se.")
    end

    for _, element in ipairs(login_elementi) do
        dgsSetVisible(element, prikazi)
    end
end

local function prikaziRegisterUI(prikazi)
    if prikazi == nil then prikazi = true end

    if prikazi then
        prikazan_ui = "register"
        fade_change_text(headerLabel, "Registracija")
        dgsSetText(switchBtn, "Login")
        fade_change_text(tipLabel, "Već imate nalog? Prijavite se.")
    end

    for _, element in ipairs(register_elementi) do
        dgsSetVisible(element, prikazi)
    end
end

local function switchUI()
    local rState -- da li treba da prikazemo register UI, login UI ce da bude kontra

    if prikazan_ui == "login" then
        rState = true

    else
        rState = false

    end

    prikaziRegisterUI(rState)
    prikaziLoginUI(not rState)

end



local function login()
    dgsSetText(porukaLabel, "")

    local username = dgsGetText(lUsr)
    local lozinka = dgsGetText(lSfr)

    -- ove provere imamo i na strani servera za slucaj da korisnik pokusa da zaobidje ovo
    if #username < policy.minUserLength or #username > policy.maxUserLength then
        return triggerEvent(
            "onRegistracijaNeuspesna",
            localPlayer,
            string.format("Korisničko ime mora da bude duže od %s a kraće od %s karaktera.", policy.minUserLength, policy.maxUserLength)
        )
    end

    if #lozinka < policy.minPassLength or #username > policy.maxPassLength then
        return triggerEvent(
            "onRegistracijaNeuspesna",
            localPlayer,
            string.format("Lozinka mora da bude duža od %s a kraća od %s karaktera.", policy.minPassLength, policy.maxPassLength)
        )
    end

    triggerServerEvent("onLoginPokusaj", resourceRoot, username, lozinka)
end

local function register()
    dgsSetText(porukaLabel, "")

    local username = dgsGetText(rUsr)
    local lozinka = dgsGetText(rSfr)
    local lozinkaPotvrda = dgsGetText(rSfrc)

    -- ove provere imamo i na strani servera za slucaj da korisnik pokusa da ih zaobidje ovde
    if #username < policy.minUserLength or #username > policy.maxUserLength then
        return triggerEvent(
            "onRegistracijaNeuspesna",
            localPlayer,
            string.format("Korisničko ime mora da bude duže od %s a kraće od %s karaktera.", policy.minUserLength, policy.maxUserLength)
        )
    end

    if #lozinka < policy.minPassLength or #username > policy.maxPassLength then
        return triggerEvent(
            "onRegistracijaNeuspesna",
            localPlayer,
            string.format("Lozinka mora da bude duža od %s a kraća od %s karaktera.", policy.minPassLength, policy.maxPassLength)
        )
    end

    if lozinka ~= lozinkaPotvrda then
        return triggerEvent(
            "onRegistracijaNeuspesna",
            localPlayer,
            "Lozinke se ne podudaraju."
        )
    end

    triggerServerEvent("onRegisterPokusaj", resourceRoot, username, lozinka)
end

--###################
local function loginUspesan()
    destroyElement(window)
    showCursor(false)
end
addEvent("onLoginUspesan", true)
addEventHandler("onLoginUspesan", localPlayer, loginUspesan)

-- ako je login uspesan server ce sam da nas spawnuje

local function loginNeuspesan(poruka)
    dgsLabelSetColor(porukaLabel, 255, 50, 50, 255)
    dgsSetText(porukaLabel, poruka)
end
addEvent("onLoginNeuspesan", true)
addEventHandler("onLoginNeuspesan", localPlayer, loginNeuspesan)


local function registracijaUspesna()
    prikaziLoginUI(true)
    prikaziRegisterUI(false)
    dgsLabelSetColor(porukaLabel, 50, 255, 50, 255)
    dgsSetText(porukaLabel, "Uspesno ste registrovani, sada možete da se ulogujete.")
end
addEvent("onRegistracijaUspesna", true)
addEventHandler("onRegistracijaUspesna", localPlayer, registracijaUspesna)

local function registracijaNesupesna(poruka)
    dgsLabelSetColor(porukaLabel, 255, 50, 50, 255)
    dgsSetText(porukaLabel, poruka)
end
addEvent("onRegistracijaNeuspesna", true)
addEventHandler("onRegistracijaNeuspesna", localPlayer, registracijaNesupesna)

--###################

local function prikaziWelcomeScreen()
    local sirina, visina = dgsGetScreenSize()

    showChat(false)
    showCursor(true, true)

    window = dgsCreateWindow(0, 0, sirina, visina, "", false, nil, nil, nil, nil, nil, nil, nil, true)
    dgsSetProperty(window, "movable", false)
    dgsSetProperty(window, "sizable", false)
    dgsSetProperty(window, "titleHeight", 0)

    headerLabel = dgsCreateLabel(0.1, 0.20, 0.25, 0.1, "LOGIN", true, window, nil, 2, 2, nil, nil, nil, "left", "center")

    -- [[ LOGIN ]]
    local lUsrLabel = dgsCreateLabel(0.1, 0.3, 0.25, 0.04, "Korisnicko ime", true, window)
    lUsr = dgsCreateEdit(0.1, 0.33, 0.25, 0.04, "", true, window)

    local lSfrLabel = dgsCreateLabel(0.1, 0.38, 0.25, 0.04, "Lozinka", true, window)
    lSfr = dgsCreateEdit(0.1, 0.41, 0.25, 0.04, "", true, window)

    local lBtn = dgsCreateButton(0.1, 0.48, 0.25, 0.04, "Login", true, window)


    -- [[ REGISTER ]]
    local rUsrLabel = dgsCreateLabel(0.1, 0.3, 0.25, 0.04, "Korisnicko ime", true, window)
    rUsr = dgsCreateEdit(0.1, 0.33, 0.25, 0.04, "", true, window)

    local rSfrLabel = dgsCreateLabel(0.1, 0.38, 0.25, 0.04, "Lozinka", true, window)
    rSfr = dgsCreateEdit(0.1, 0.41, 0.25, 0.04, "", true, window)

    local rSfrcLabel = dgsCreateLabel(0.1, 0.46, 0.25, 0.04, "Potvrdi lozinku", true, window)
    rSfrc = dgsCreateEdit(0.1, 0.49, 0.25, 0.04, "", true, window)

    local rBtn = dgsCreateButton(0.1, 0.56, 0.25, 0.04, "Registuj nalog", true, window)
    --

    porukaLabel = dgsCreateLabel(0.1, 0.62, 0.25, 0.08, "", true, window)

    switchBtn = dgsCreateButton(0.1, 0.70, 0.12, 0.04, "Registruj se", true, window)
    tipLabel = dgsCreateLabel(0.1, 0.74, 0.25, 0.04, "Nemate nalog? Registrujte se.", true, window)

    table.insert(login_elementi, lUsr)
    table.insert(login_elementi, lUsrLabel)
    table.insert(login_elementi, lSfr)
    table.insert(login_elementi, lSfrLabel)
    table.insert(login_elementi, lBtn)

    table.insert(register_elementi, rUsr)
    table.insert(register_elementi, rUsrLabel)
    table.insert(register_elementi, rSfr)
    table.insert(register_elementi, rSfrLabel)
    table.insert(register_elementi, rSfrc)
    table.insert(register_elementi, rSfrcLabel)
    table.insert(register_elementi, rBtn)

    switchUI()

    addEventHandler("onDgsMouseClickUp", switchBtn, switchUI, false)

    addEventHandler("onDgsMouseClickUp", lBtn, login, false)
    addEventHandler("onDgsMouseClickUp", rBtn, register, false)

end
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- ako igrac nije ulogovan
    if not getElementData(localPlayer, "nalogID", false) then
        triggerServerEvent("onClientTraziPolicyInfo", resourceRoot)
    end
end)

addEvent("onClientPolicyInfo", true)
addEventHandler("onClientPolicyInfo", resourceRoot, function(policySettings)
    policy = policySettings
    prikaziWelcomeScreen()
end)