local vreme_cekanja = 300

-- key {send_to, event_name}
local event_buffer = {}
local timer = nil

local next = next

--- Salje sve evente koji su se skupili za 'vreme_cekanja' i skanja ih iz 'event_buffer'
-- @return nil.
local function pokreni_slanje()
    for st_en, event_data in pairs(event_buffer) do
        local send_to = st_en[1] or root
        local event_name = st_en[2]
        triggerClientEvent(send_to, "eventBuffer:eventsReceived", resourceRoot, {[event_name] = event_data})
    end

    for event_name, _ in pairs(event_buffer) do
        event_buffer[event_name] = nil
    end
    timer = nil
end

--- Dodaje event u 'event_buffer' sa svim ostalim argumentima i pamti kome je event namenjen.
-- Event ce, zajedno sa svi ostalim dodatim u medjuvremenu, biti poslat kada prodje 'vreme_cekanja'.
-- @param send_to element/table: Za koga je namenje event.
-- @param event_name string: Ime eventa koji ce biti poslat.
-- @param[opt] ... any: Argumenti koji ce biti prosledjeni uz event.
function posalji_client_event(send_to, event_name, ...)
    if next(event_buffer) == nil  or (next(event_buffer) ~= nil and timer == nil) then

        timer = setTimer(pokreni_slanje, vreme_cekanja, 1)
    end

    local key = {send_to, event_name}

    if not event_buffer[key] then
        event_buffer[key] = {}
    end

    local event_data = event_buffer[key]
    
    event_data[#event_data+1] = {...}
end
