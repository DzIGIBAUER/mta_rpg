local vreme_cekanja = 300
-- kljuc event_name
local event_buffer = {}
local timer = nil

local next = next

--- Salje sve evente koji su se skupili za 'vreme_cekanja' i sklanja ih iz 'event_buffer'
local function pokreni_slanje()
    triggerServerEvent("eventBuffer:eventsReceived", resourceRoot, event_buffer)

    for event_name, _ in pairs(event_buffer) do
        event_buffer[event_name] = nil
    end
    timer = nil
end

--- Dodaje event, koji je namenjen serveru, u 'event_buffer' sa svim ostalim argumentima.
-- Event ce, zajedno sa svi ostalim dodatim u medjuvremenu, biti poslat kada prodje 'vreme_cekanja'.
-- @param event_name string: Ime eventa koji ce biti poslat.
-- @param[opt] ... any: Argumenti koji ce biti prosledjeni uz event.
function posalji_server_event(event_name, ...)
    if next(event_buffer) == nil  or (next(event_buffer) ~= nil and timer == nil) then

        timer = setTimer(pokreni_slanje, vreme_cekanja, 1)
    end

    if not event_buffer[event_name] then
        event_buffer[event_name] = {}
    end

    local evData = event_buffer[event_name]
    
    evData[#evData+1] = {...}
end
