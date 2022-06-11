local ASYNC_FILE_PATH = "async.lua"

function init()
    local file = fileExists(ASYNC_FILE_PATH) and fileOpen(ASYNC_FILE_PATH) or error("Fatalna greška. Nije pronadjen fajl ".. ASYNC_FILE_PATH)

    local file_data = fileRead(file, fileGetSize(file))

    fileClose(file)
    
    return file_data
end
