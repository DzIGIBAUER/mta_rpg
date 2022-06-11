local FILE_PATHS = {
    "event/handler.lua"
}


function init()
    local data = {}

    for i, fp in ipairs(FILE_PATHS) do
        local file = fileExists(fp) and fileOpen(fp) or error("Fatalna greška. Nije pronadjen fajl ".. fp)

        data[i] = fileRead(file, fileGetSize(file))

        fileClose(file)
    end
    
    return table.concat(data, "\n")
end
