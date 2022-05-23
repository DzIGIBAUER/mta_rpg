loadstring(exports.dgs:dgsImportFunction())()


local UI = {
    REGISTER = 0,
    LOGIN = 1,
}

local prikazan_ui = UI.REGISTER
local switch_duration = 150 -- ms

local gui = {
    login = {},
    register = {},
}


--[[ POLICY ]]
local policy -- tabela. Od servera dobijemo min_pass_length, maxPassLength, min_user_length, max_user_lenght


--- Animira menjanje teksta u dgs label-u.
-- @param label dgs label: Label ciji tekst menjamo.
-- @param novi_text string: novi_tekst.
local function fade_change_text(label, novi_text)
    dgsAlphaTo(label, 0, false, "Linear", switch_duration)
    if novi_text and novi_text ~= "" then
        setTimer(function()
            dgsSetText(label, novi_text)
            dgsAlphaTo(label, 1, false, "Linear", switch_duration)
        end, switch_duration, 1)
    end
end


--- Prikazuje/sakriva login UI.
-- @param[opt] prikazi bool: Da li da ga prikaze ili sakrije.
local function prikazi_login_ui(prikazi)
    if prikazi == nil then prikazi = true end

    if prikazi then
        prikazan_ui = UI.LOGIN
        fade_change_text(gui.header_label, "Login")
        dgsSetText(gui.switch_button, "Registruj se")
        fade_change_text(gui.tip_label, "Nemate nalog? Registrujte se.")
    end

    for _, element in pairs(gui.login) do
        dgsSetVisible(element, prikazi)
    end
end


--- Prikazuje/sakriva register UI.
-- @param[opt] prikazi bool: Da li da ga prikaze ili sakrije.
local function prikazi_register_ui(prikazi)
    if prikazi == nil then prikazi = true end

    if prikazi then
        prikazan_ui = UI.REGISTER
        fade_change_text(gui.header_label, "Registracija")
        dgsSetText(gui.switch_button, "Login")
        fade_change_text(gui.tip_label, "Već imate nalog? Prijavite se.")
    end

    for _, element in pairs(gui.register) do
        dgsSetVisible(element, prikazi)
    end
end

--- Menja trenutno prikazan UI izmedju LOGIN i REGISTER
local function switch_ui()
    local r_state -- da li treba da prikazemo register UI, login UI ce da bude kontra

    if prikazan_ui == UI.LOGIN then
        r_state = true

    else
        r_state = false
    end
    
    prikazi_register_ui(r_state)
    prikazi_login_ui(not r_state)
end

--- Handler za login dugme.
local function _login()
    dgsSetText(gui.poruka_label, "")

    local username = dgsGetText(gui.login.user_edit)
    local lozinka = dgsGetText(gui.login.pass_label)

    triggerServerEvent("igracSistem:loginPokusaj", resourceRoot, username, lozinka)
end

local function _register()
    dgsSetText(gui.poruka_label, "")

    local username = dgsGetText(gui.register.user_edit)
    local lozinka = dgsGetText(gui.register.pass_label)
    local lozinka_potvrda = dgsGetText(gui.register.pass_confirm_edit)

    -- ove provere imamo i na strani servera za slucaj da korisnik pokusa da ih zaobidje ovde
    if #username < policy.min_user_length or #username > policy.max_user_lenght then
        return triggerEvent(
            "igracSistem:registracijeNeuspesna",
            localPlayer,
            string.format("Korisničko ime mora da bude duže od %s a kraće od %s karaktera.", policy.min_user_length, policy.max_user_lenght)
        )
    end

    if #lozinka < policy.min_pass_length or #username > policy.maxPassLength then
        return triggerEvent(
            "igracSistem:registracijeNeuspesna",
            localPlayer,
            string.format("Lozinka mora da bude duža od %s karaktera.", policy.min_pass_length)
        )
    end

    if lozinka ~= lozinka_potvrda then
        return triggerEvent(
            "igracSistem:registracijeNeuspesna",
            localPlayer,
            "Lozinke se ne podudaraju."
        )
    end

    triggerServerEvent("igracSistem:registerPokusaj", resourceRoot, username, lozinka)
end


local function _login_uspesan()
    destroyElement(gui.window)
    gui = nil
    showCursor(false)
end
addEvent("igracSistem:loginNeuspesan", true)
addEventHandler("igracSistem:loginNeuspesan", localPlayer, _login_uspesan)

local function _login_neuspesan(poruka)
    dgsLabelSetColor(gui.poruka_label, 255, 50, 50, 255)
    dgsSetText(gui.poruka_label, poruka)
end
addEvent("igracSistem:loginUspesan", true)
addEventHandler("igracSistem:loginUspesan", localPlayer, _login_neuspesan)


local function _registracija_uspesna()
    prikazi_login_ui(true)
    prikazi_register_ui(false)
    dgsLabelSetColor(gui.poruka_label, 50, 255, 50, 255)
    dgsSetText(gui.poruka_label, "Uspesno ste registrovani, sada možete da se ulogujete.")
end
addEvent("igracSistem:registracijeUspesna", true)
addEventHandler("igracSistem:registracijeUspesna", localPlayer, _registracija_uspesna)

local function _registracija_nesupesna(poruka)
    dgsLabelSetColor(gui.poruka_label, 255, 50, 50, 255)
    dgsSetText(gui.poruka_label, poruka)
end
addEvent("igracSistem:registracijeNeuspesna", true)
addEventHandler("igracSistem:registracijeNeuspesna", localPlayer, _registracija_nesupesna)


local function prikazi_welcome_screen()
    local sirina, visina = dgsGetScreenSize()

    showChat(false)
    showCursor(true, true)
    gui.window = dgsCreateWindow(0, 0, sirina, visina, "", false, nil, nil, nil, nil, nil, nil, nil, true)
    dgsSetProperty(gui.window, "movable", false)
    dgsSetProperty(gui.window, "sizable", false)
    dgsSetProperty(gui.window, "titleHeight", 0)

    gui.header_label = dgsCreateLabel(0.1, 0.20, 0.25, 0.1, "LOGIN", true, gui.window, nil, 2, 2, nil, nil, nil, "left", "center")

    -- [[ LOGIN ]]
    gui.login.user_label = dgsCreateLabel(0.1, 0.3, 0.25, 0.04, "Korisnicko ime", true, gui.window)
    gui.login.user_edit = dgsCreateEdit(0.1, 0.33, 0.25, 0.04, "", true, gui.window)

    gui.login.pass_label = dgsCreateLabel(0.1, 0.38, 0.25, 0.04, "Lozinka", true, gui.window)
    gui.login.pass_edit = dgsCreateEdit(0.1, 0.41, 0.25, 0.04, "", true, gui.window)

    gui.login.button = dgsCreateButton(0.1, 0.49, 0.25, 0.04, "Login", true, gui.window)

    -- [[ REGISTER ]]
    gui.register.user_label = dgsCreateLabel(0.1, 0.3, 0.25, 0.04, "Korisnicko ime", true, gui.window)
    gui.register.user_edit = dgsCreateEdit(0.1, 0.33, 0.25, 0.04, "", true, gui.window)

    gui.register.pass_label = dgsCreateLabel(0.1, 0.38, 0.25, 0.04, "Lozinka", true, gui.window)
    gui.register.pass_edit = dgsCreateEdit(0.1, 0.41, 0.25, 0.04, "", true, gui.window)

    gui.register.pass_confirm_label = dgsCreateLabel(0.1, 0.46, 0.25, 0.04, "Potvrdi lozinku", true, gui.window)
    gui.register.pass_confirm_edit = dgsCreateEdit(0.1, 0.49, 0.25, 0.04, "", true, gui.window)

    gui.register.button = dgsCreateButton(0.1, 0.56, 0.25, 0.04, "Registruj nalog", true, gui.window)


    gui.poruka_label = dgsCreateLabel(0.1, 0.62, 0.25, 0.08, "", true, gui.window)

    gui.switch_button = dgsCreateButton(0.1, 0.70, 0.12, 0.04, "Registruj se", true, gui.window)
    gui.tip_label = dgsCreateLabel(0.1, 0.74, 0.25, 0.04, "Nemate nalog? Registrujte se.", true, gui.window)

    switch_ui()

    addEventHandler("onDgsMouseClickUp", gui.switch_button, switch_ui, false)

    addEventHandler("onDgsMouseClickUp", gui.login.button, _login, false)
    addEventHandler("onDgsMouseClickUp", gui.register.button, _register, false)
end

addEvent("igracSistem:clientPolicyInfo", true)
addEventHandler("igracSistem:clientPolicyInfo", resourceRoot, function(policy_settings)
    policy = policy_settings
    prikazi_welcome_screen()
end)
