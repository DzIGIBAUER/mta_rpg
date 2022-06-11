-- https://wiki.multitheftauto.com/wiki/FileExists
local FUNC_BUFF_CLASS_PATH = "functionBuffer/function_buffer_class.lua"

--- Salje functionBufferClass.lua kao string resursu koji pozove ovu funkciju.
-- Resurs ce taj string da ucita sa loadstring kako bi koristii ovaj resurs sa samo jednim pozivom exportovane funkcije
-- @return string: functionBufferClass.lua kod.
function init()
    local file = fileExists(FUNC_BUFF_CLASS_PATH) and fileOpen(FUNC_BUFF_CLASS_PATH) or error("Fatalna greška. Nije pronadjen fajl ".. FUNC_BUFF_CLASS_PATH)

    local file_data = fileRead(file, fileGetSize(file))

    fileClose(file)
    
    return file_data
end 
