-- TODO: Uveri se da radi kako treba.

--- Dobija gomilu evenata koje razlaze i trigger-uje lokalno.
-- @param events_data table: tabela sa podacima o primljenim eventima(kljuc event_name, vrednost event_argumenti).
local function _razlozi_evente(events_data)
    for event_name, event_data in pairs(events_data) do

        for k=1, #event_data do
            
            triggerEvent(event_name, event_data[k][1], select(2, unpack(event_data[k]) ))
        end
    end
end
addEvent("eventBuffer:eventsReceived", true)
addEventHandler("eventBuffer:eventsReceived", resourceRoot, _razlozi_evente)
