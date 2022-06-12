Buffer = {}
Buffer.__index = Buffer

--- Stvara novi Buffer objekat preko kojeg mozemo da grupisemo vise radnji u jednu (vidi meta.xml).
-- @param vreme_cekanja int: Koliko cekati pre nego sto pokrenemo 'handler_function'.
-- @param element_type string: Tip elementa koji ce buffer cuvati. https://wiki.multitheftauto.com/wiki/Element
-- @param[opt] handler_function function: Funkcija koja ce biti pozvana nakon 'vreme_cekanja'
-- i kojoj ce biti prosledjeni elementi
-- @return Buffer
function Buffer.new(vreme_cekanja, element_type, handler_function)
    local self = setmetatable({}, Buffer)
    
    self._elementi = {}
    self.vreme_cekanja = vreme_cekanja
    self.element_type = element_type
    self.handler_function = handler_function

    -- self.last_timer je Timer element ili nil
    self.last_timer = nil
    self.handler_func_aktivna = false

    return self
end

--- Pokrece 'handler_function' i prosledjuje elemente, nakon cega ih brise ako su procesuirani.
-- 'handler_function' ce vratiti 'true' ako je sve u redu, nakon cega ce elmenti biti obrisni.
-- 'false' ako elemnti nisu procesuirani i 'table' ako treba izbrisati samo neke elmente, odredjen u toj tabeli.
function Buffer:run_function()
    if not self:is_handler_set() then
        return error("Handler funkcija nije podesena. ".. getResourceName(resource))
    end

    self.last_timer = nil

    self.handler_func_aktivna = true
    local za_brisanje = self.handler_function(self._elementi)
    self.handler_func_aktivna = false

    if type(za_brisanje) == "table" then
        for ek=1, #self._elemnti do
            for k=1, #za_brisanje do
                if self._elementi[ek] == za_brisanje[k] then
                    self._elementi[ek] = nil
                    break
                end
            end
        end

    elseif za_brisanje then
        for k=1, #self._elementi do
            self._elementi[k] = nil
        end
    end
end

--- Na silu pokrece 'handler_function', ako vec nije i prekidajuci timer ako je namesten
function Buffer:force_run()

    if self.handler_func_aktivna then return end

    
    if self.last_timer then
        killTimer(self.last_timer)
        self.last_timer = nil
    end

    self:run_function()
end


function Buffer:set_handler(handler_function)
    self.handler_function = handler_function

end

function Buffer:is_handler_set()
    if self.handler_function then return true else return false end
end



function Buffer:pokreni_timer()
    self.last_timer = setTimer(function()
        self:run_function()

    end, self.vreme_cekanja, 1)
end

--- Pokrece timer za pokretanje 'handler_function' ako timer vec nije pokrenut
function Buffer:pokreni_po_potrebi()
    if not self:is_handler_set() then
        return outputDebugString("Elementi su dodati ali handler nije namesten, odlaze se")
    end

    if not self.last_timer then
        self:pokreni_timer()
    end
end


--- Dodaje element u listu elemenata koji su prosledjeni 'handler_function' kada je pokrenuta.
-- Element mora da bude odredjenog 'element_type'.
-- @param element element: Element koju dodajemo.
-- @param[opt] pokreni bool: Da li treba da zakazemo pokretanje 'handler_function' nakon dodavanja elementa.
function Buffer:append_element(element, pokreni)
    if getElementType(element) ~= self.element_type then
        return error(string.format('Greska, ocekivan element sa tipom "%s", a dobijen "%s"', self.element_type, getElementType(element) or "nepoznat"))
    end

    table.insert(self._elementi, element)
    
    if pokreni then
        self:pokreni_po_potrebi()
    end
end