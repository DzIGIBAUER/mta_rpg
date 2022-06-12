--[[
    Ukoliko je fajl sa podacima igraca nepostojeci, unisten ili igrac zeli da obnovi podesavanja,
    zatrazicemo od servera kopiju fajla
]]


standardne_postavke = nil -- xml string sa standardnim postavkama
local comparator_mngr = Comparator.new()

local callback = nil-- funkcija koju treba da pozovema kada obnovimo user preferences
local callback_args = nil -- argumenti koje treba proslediti callback-u

local x_paths = {
    ["binds"] = {binds=0}
}

--- Osvezice postavke igraca. Pogledaj XmlComparator (comparator_mngr) za vise informacija.
-- @param args table: Tabela sa mogucim poljima: callback, callback_arguments i target_node.
--  target_node string: Od kog node-a treba krenuti osvezavanje prema 'x_paths' tabeli sa vrha, 'nil' za osvezavanje celog fajla.
--  callback[opt] function: Funkcija koju treba da pozovemo nakon sto osvezimo postavke igraca.
--  callback_arguments[opt] table: Sta proslediti toj funkciji.
function obnovi_user_preferences(args)
    callback = args.callback
    callback_args = args.callback_arguments

    if not standardne_postavke then
        triggerServerEvent("igracSistem:clientTraziStandardnePostavke", resourceRoot, args.target_node)
    else
        osvezi_postavke(standardne_postavke, args.target_node)
    end
end

--- Osvezava postavke korisnika u XML fajlu pomocu XmlComparator-a, koristeci standardni XML fajl sa servera,
-- koji se client-u salje jednom i cuva u memoriji kao string.
-- Ako korisnik nema XML fajl on se pravi, i osvezavanje je moguce zapoveti od 'target_node'-a iz 'x_paths' tabele.
-- Ako do node-a koji se nalazi na 'x_path' ne mozemo doci bice obnovljeno sve do njega pa zatim i on.
-- @param file_data string: XML fajl sa servera kao string.
-- @param[opt] target_node string: kljuc kojim uzimamo 'x_path' iz 'x_paths' tabele
local function osvezi_postavke(file_data, target_node)
    standardne_postavke = file_data
    x_path = x_paths[target_node]

    local user_xml_root = xmlLoadFile(FILE_PATH)
    local user_target_node = user_xml_root

    if user_xml_root then
        local server_user_target_node = xmlLoadString(file_data)

        if x_path then
            for node_name, index in pairs(x_path) do
                nasao = xmlFindChild(user_target_node, node_name, index)
                if not nasao then
                    break
                end
                
                user_target_node = nasao
                server_user_target_node = xmlFindChild(server_user_target_node, node_name, index)
            end
        end

        comparator_mngr:compare_and_fix(user_target_node, server_user_target_node, true, true)

        xmlSaveFile(user_xml_root)
        xmlUnloadFile(user_target_node)

        xmlUnloadFile(server_user_target_node)
    else
        if fileExists(FILE_PATH) then fileDelete(FILE_PATH) end

        local file = fileCreate(FILE_PATH)
        fileWrite(file, file_data)
        fileClose(file)
    end


    triggerEvent(
        "igracSistem:notifikacija",
        localPlayer,
        "uspesno",
        "Osvežene postavke",
        "Fajl sa vašim postavkama je uspesno osvežen"
    )

    if callback then
        callback(unpack{args})

        callback = nil
        args = nil
    end

end
addEvent("igracSistem:serverPosaloStandardnePostavke", true)
addEventHandler("igracSistem:serverPosaloStandardnePostavke", resourceRoot, osvezi_postavke)
