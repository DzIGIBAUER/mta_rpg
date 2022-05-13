local active_codes = {}


--- Pretvara string karaktere u decimal code point i sabira ih.
-- Ovo koristimo da od nasumicnog teksta dobijemo nasumican broj.
-- @param str string: Teks koji prevramo u broj.
local function string_to_num(str)
    local num = 1
    for i = 1, #str do
        local char = string.sub(str, i, i)
        num = num + utfCode(char)
    end
    return num
end


--- Pravi 'auth_kod' za igraca kako bi mogao da se uloguje preko sajta u igricu.
-- Kod mora da bude unikatan pa se serial igraca pretvara u broj i mnozi sa 'getTickCount'.
-- @param text string: Tekst koji je pretvoren u broj i pomnozen sa 'getTickCount' da bi se dobio sto unikatniju broj.
local function kreiraj_auth_code(text)
    local rand_number = string_to_num(text) * getTickCount()
    return string.format("%010d", rand_number)
end

--- Dodaje kod u tabelu aktivnih kodova kao kljuc cija je vrednost igrac.
-- Takodje salje kod igracu.
-- @param player player: Igrac ciji kod je aktiviran.
-- @param code string: Kod igraca.
local function aktiviraj_auth_code(player, code)
    triggerClientEvent(player, "nalogSistem:ServerPoslaoAuthCode", resourceRoot, code)
    active_codes[code] = player
end


--- Kada se igrac poveze generisemo mu i saljemo kod od njegovog serial-a ili IP adrese.
-- Ako kod nije unikatan cekamo 10ms i pokusamo ponovo.
-- Cekanje 10ms ce znaciti drugu vrednost koju vraca 'getTickCount' i samim tim drugi broj, koji bi trebalo da je unikatan,
-- a ako ne radimo istu stvar opet.
local function _igrac_se_povezao()
    local str_for_code = getPlayerSerial(source) or getPlayerIP(source)
    if not str_for_code then
        kickPlayer(source, "Server nije uspeo da pristupi Vašem serial-u ni IP adresi.")
        return
    end

    local code = kreiraj_auth_code(str_for_code)
    
    if not active_codes[code] then
        setTimer(aktiviraj_auth_code, 5000, 1, source, code)
        return
    end


    local function pokusaj_ponovo()
        local code = kreiraj_auth_code(str_for_code)
        if not active_codes[code] then
            aktiviraj_auth_code(source, code)
            killTimer(sourceTimer)
        end
    end
    setTimer(pokusaj_ponovo, 10, 0)

end
addEventHandler("onPlayerJoin", root, _igrac_se_povezao)





function auth_user(code, igrac_info)
    local igrac = active_codes[code]
    if not igrac then
        return {false, "Neuspešan login. Rekonektujte se na server. Ako se problem nastavi kontaktirajte administraciju."}
    end

    active_codes[code] = nil

    triggerEvent("igracSistem:igracUlogovan", igrac, igrac_info)
    triggerClientEvent("igracSistem:authGotov", igrac)

    return {true, "Ok"}

end

local function _igrac_diskonektovan()
    active_codes[source] = nil
end
addEventHandler("onPlayerQuit", resourceRoot, _igrac_diskonektovan)