local _vremeCekanja = 300
-- kljuc: eventName
local _eventiData = {}
local _timer = nil

local next = next

local function _pokreniSlanje()
    triggerServerEvent("bufferedEvent", resourceRoot, _eventiData)

    for eventName, _ in pairs(_eventiData) do
        _eventiData[eventName] = nil
    end
    _timer = nil
end


function posaljiServerEvent(eventName, ...)
    if next(_eventiData) == nil  or (next(_eventiData) ~= nil and _timer == nil) then

        _timer = setTimer(_pokreniSlanje, _vremeCekanja, 1)
    end

    if not _eventiData[eventName] then
        _eventiData[eventName] = {}
    end

    local evData = _eventiData[eventName]
    
    evData[#evData+1] = {...}
end
