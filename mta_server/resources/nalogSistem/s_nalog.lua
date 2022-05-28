policy = {
    min_pass_length = tonumber(get("minPassLength")),
    max_user_lenght = tonumber(get("maxUserLength")),
    min_user_length = tonumber(get("minUserLength"))
}

pocetni = {
    spawn = {
        pos_x = tonumber(get("pocetniPosX")),
        pos_y = tonumber(get("pocetniPosY")),
        pos_z = tonumber(get("pocetniPosZ")),
        rot_x = tonumber(get("pocetniRotX")),
        rot_y = tonumber(get("pocetniRotY")),
        rot_z = tonumber(get("pocetniRotZ")),
    },
    novac = tonumber(get("pocetniNovac")),
    model_id = tonumber(get("pocetniModel"))
}



--- Proverava da li su opcije kao sto su pocetni spawn, novac itd. definisane u meta.xml fajlu.
local function _proveri_pocetne_opcije(_)
    local potrebno = {"pocetniPosX", "pocetniPosY", "pocetniPosZ", "pocetniRotX", "pocetniRotY", "pocetniRotZ", "pocetniNovac", "pocetniModel"}

    for _, setting in ipairs(potrebno) do
        if not get(setting) then
            outputDebugString(string.format("Opcija %s nije definisana u 'meta.xml' fajlu. Resurs: %s", setting, getResourceName(resource)))
        end
    end

end
addEventHandler("onResourceStart", resourceRoot, _proveri_pocetne_opcije)



--- Helper funkcije za lakse slanju poruke clientu
-- @param client player: Kome saljemo.
-- @param event string: Ime eventa.
-- @param poruka string: Poruka koju saljemo
-- @param[opt] ... string: poruka ce da bude formatirana sa ovi argumentima.
function posalji_poruku(client, event, poruka, ...)
    if poruka then
        poruka = string.format(poruka, ...)
    end
    triggerClientEvent(client, event, client, poruka)
end


local function _igrac_resurs_pokrenut(pokrenut_resurs)
    if pokrenut_resurs ~= resource and not getElementData(source, "id", false) then return end

    triggerClientEvent("nalogSistem:clientPolicyInfo", resourceRoot, policy)
end
addEventHandler("onPlayerResourceStart", root, _igrac_resurs_pokrenut)
