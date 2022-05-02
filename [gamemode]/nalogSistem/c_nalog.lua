loadstring(exports.dgs:dgsImportFunction())()

local auth_code
local gui = {}
local browser_ucitan


--- Ucitava sajt za autorizaciju i salje mu 'auth_code'.
local function ucitaj_auth_sajt()
    local post_data = toJSON({mta_auth_code = auth_code}):sub(2, -2)
    loadBrowserURL(gui.browser, AUTH_URL, post_data, false)
    dgsBringToFront(gui.browser)
end


--- Odlucuje koji je sledeci korak na osnovu toga da li je
-- pretrazivac ucitan i da li nam je server poslao 'auth_code'.
-- Ako jeste ucitavamo sajt za autorizaciju.
local function next_step_manager()
    if not browser_ucitan or not auth_code or isBrowserDomainBlocked(AUTH_URL, true) then
        return
    end

    ucitaj_auth_sajt()

end


--- Trazi od igraca da odobri pristup sajtu za autorizaciju.
-- Ako je igrac prihvatio pozvan je 'next_step_manager'.
-- @param url string: URL na kom se nalazi sajt.
local function zatrazi_dozvolu(url)
    if not isBrowserDomainBlocked(url, true) then
        next_step_manager()
        return 
    end

    requestBrowserDomains({url}, true,    
    function(prihvaceno, _)
        if prihvaceno then
            destroyElement(gui.button)
            dgsSetText(gui.label, "Uskoro će se učitati sajt za autorizaciju. Barem bi trebalo...")
            next_step_manager()
        end
    end
)

end


--- Prikazuje igracu dugme na ciji klik mu se pokrece 'zatrazi_dozvolu' i
-- poruku u kojij pise da mora da prihvati da bi nastavio dalje.
-- @param url string: URL satja za autorizaciju.
local function sredi_dozvolu(url)
    if isBrowserDomainBlocked(url, true) then
        local poruka = "Da bi mogli da nastavite morate da dozvolite pristup sajtu na adresi "
            ..url..
            ".\nTo možete učiniti i u Settings -> Web Browser -> Custom Whitelist."
        dgsSetText(gui.label, poruka)

        gui.button = dgsCreateButton(0.45, 0.51, 0.1, 0.05, "Dozvoli", true, gui.window)

        addEventHandler("onDgsMouseClickUp", gui.button,
            function(mouse_button)
                if mouse_button ~= "left" then return end
                zatrazi_dozvolu(url)
            end,
        false)
    end
end

--- Sakriva chat, kursor i iskljucuje komande igraca; Kreira pretrazivac u kom ce igrac da se uloguje/registuje;
-- Kreira prozor u kom su mu prikazane istrukcije za nastavak.
local function _resurs_pokrenut(_srated_resource)

    showCursor(true, true)
    toggleAllControls(false, true, true)
    showChat(false, true)


    gui.browser = dgsCreateBrowser(0, 0, 1, 1, true)
    addEventHandler("onClientBrowserCreated", gui.browser,
        function()
            browser_ucitan = true
            next_step_manager()
        end
    )


    gui.window = dgsCreateWindow(0, 0, 1, 1, "", true, nil, 0, nil, nil, nil, nil, 1, true)
    gui.label = dgsCreateLabel(0, 0, 1, 0.5, "", true, gui.window)
    dgsLabelSetHorizontalAlign(gui.label, "center")
    dgsLabelSetVerticalAlign(gui.label, "bottom")

    sredi_dozvolu(AUTH_URL)

end
addEventHandler("onClientResourceStart", resourceRoot, _resurs_pokrenut)





local function pokreni_auth(code)
    auth_code = code

    next_step_manager()
end
addEvent("nalogSistem:ServerPoslaoAuthCode", true)
addEventHandler("nalogSistem:ServerPoslaoAuthCode", resourceRoot, pokreni_auth)

local function _auth_gotov()
    for _key, element in pairs(gui) do
        if isElement(element) then destroyElement(element) end
    end

    showCursor(false, false)
    showChat(true, false)
    toggleAllControls(true, true, true)

end
addEvent("igracSistem:authGotov", true)
addEventHandler("igracSistem:authGotov", localPlayer, _auth_gotov)