-- eventi sa servera i clienta se razlazu na isti nacin
local function _razloziEvente(eventData)
    -- ako je poslato sa servera kljuc nije "eventName" nego {sendTo, eventName}
    for eventName, evData in pairs(eventData) do

        for k=1, #evData do
            
            triggerEvent(eventName, evData[k][1], select(2, unpack(evData[k]) ))
        end
    end
end
addEvent("bufferedEvent", true)
addEventHandler("bufferedEvent", resourceRoot, _razloziEvente)
