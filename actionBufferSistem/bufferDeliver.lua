--[[
    Ovaj resurs omogucava da se radnje koje se cesto ponavljaju u kratkom vremenskom intervalu grupisu u jednu.
    Npr. ako resur trazi informacije iz .xml fajl i dobijemo nekoliko takvih zahteva u roku od 50ms,
    umesto da otvorimo-procitamo-zatvorima fajl onoliko puta koliko smo puta dobili zahtev,
    bolje je da sacekamo neko vreme (vremeCekanja) i iz jednog otvaranja ocitamo informacije za sve resurse koji ih cekaju
]]

--

local FUNC_BUFF_CLASS_PATH = "functionBufferClass.lua"

function sendFunctionBufferConstruct()
    local file = fileExists(FUNC_BUFF_CLASS_PATH) and fileOpen(FUNC_BUFF_CLASS_PATH) or error("Fatalna greska. Nije pronadjen fajl ".. CLASS_PATH)

    local fileData = fileRead(file, fileGetSize(file))

    fileClose(file)
    
    return fileData
end
