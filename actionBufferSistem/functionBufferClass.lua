Buffer = {}
Buffer.__index = Buffer

function Buffer.new(vremeCekanja, elementType, handlerFunction)
    local self = setmetatable({}, Buffer)
    
    self._elementi = {}
    self._vremeCekanja = vremeCekanja
    self._elementType = elementType
    self._handlerFunction = handlerFunction

    -- ako je _lastTimer nil nema tajmera i handlerFunkcija nije aktivna
    -- ako je false nema tajmera ali je handlerFunkcija aktivna
    -- ako je Timer objekat onda je pokretanje handlerFunkcije zakazano
    self._lastTimer = nil

    return self
end


function Buffer:_runFunction()
    if not self:isHandlerSet() then
        return error("Handler funkcija nije podesena. " + getResourceName(resource))
    end

    self._lastTimer = false
    self._handlerFunction(self._elementi)

    self._elementi = {}
    self._lastTimer = nil
end

-- na silu pokrece funkciju iako nije proslo self._vremeCekanja
function Buffer:forceRun()

    if self._lastTimer == false then return end
    
    if self._lastTimer then
        killTimer(self._lastTimer)
        self._lastTimer = nil
    end

    self:_runFunction()
end



function Buffer:setHandler(handlerFunction)
    self._handlerFunction = handlerFunction

end

function Buffer:isHandlerSet()
    if self._handlerFunction then return true else return false end
end



function Buffer:_pokreniTimer()
    -- ovde zovemo anon funkciju kako bi nil-ovali promenljivu gde je bio timer
    -- https://wiki.multitheftauto.com/wiki/IsTimer
    self._lastTimer = setTimer(function()
        self:_runFunction()

    end, self._vremeCekanja, 1)
end

function Buffer:_pokreniPoPotrebi()
    if next(self._elementi) == nil then

        self:_pokreniTimer()
    end
end



function Buffer:appendElement(element)
    if getElementType(element) ~= self._elementType then
        return error(string.format("Greska, ocekivan element sa tipom \"%s\" a dobijen \"%s\".", self._elementType, getElementType(element) or "nepoznat"))
    end

    self:_pokreniPoPotrebi()
    table.insert(self._elementi, element)
end