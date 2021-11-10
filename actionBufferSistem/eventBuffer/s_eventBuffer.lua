local _vremeCekanja = 300
-- kljuc: {sendTo, eventName}
local _eventiData = {}
local _timer = nil

local next = next


local function _pokreniSlanje()

    for stEn, evData in pairs(_eventiData) do
        local sendTo = stEn[1] or root
        local eventName = stEn[2]
        triggerClientEvent(sendTo, "bufferedEvent", resourceRoot, {[eventName] = evData})
    end

    for eventName, _ in pairs(_eventiData) do
        _eventiData[eventName] = nil
    end
    _timer = nil
end


function posaljiClientEvent(sendTo, eventName, ...)
    if next(_eventiData) == nil  or (next(_eventiData) ~= nil and _timer == nil) then

        _timer = setTimer(_pokreniSlanje, _vremeCekanja, 1)
    end

    local key = {sendTo, eventName}

    if not _eventiData[key] then
        _eventiData[key] = {}
    end

    local evData = _eventiData[key]
    
    evData[#evData+1] = {...}
end
