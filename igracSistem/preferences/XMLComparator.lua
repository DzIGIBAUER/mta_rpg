Comparator = {}
Comparator.__index = Comparator

-- koji atribut je unikatan za koji XML node
-- tj. po cemu gledamo da li se potreban node nalazi u fajlu
local UNIQUE_ATTR = {
    ["bind"] = "functionName"
}



-- ovaj objekat ce uciniti da userNode ima iste node-ove kao serverNode ali ce sacuvati atribute userNode node-ova ako vec postoje i
-- dodati one koji fale
function Comparator.new()
    local self = setmetatable({}, Comparator)

    return self
end


function Comparator:compareAndFix(userNode, serverNode, izbrisiNepotrebne, rekruzija)

    if rekruzija then
        local userNodeChildren = xmlNodeGetChildren(userNode)
        local serverNodeChildren = xmlNodeGetChildren(serverNode)
        for _, n in ipairs(serverNodeChildren) do

            local nodeToCheck = self._getCorrespondingNodes(userNodeChildren, n)
            
            if nodeToCheck then
                self:compareAndFix(nodeToCheck, n, izbrisiNepotrebne, rekruzija)
            else
                self:copy(n, userNode, true)
            end
        end
    end

    if izbrisiNepotrebne then
        self._removeDuplicates(userNode, serverNode)
    end

    self._fix(userNode, serverNode)
end

function Comparator._removeDuplicates(userNode, serverNode)
    local potrebniNodovi = {--[[ bind: {count: 5, {fname1, fname2} } ]]}
    
    for _, n in ipairs( xmlNodeGetChildren(serverNode) ) do
        local nodeName = xmlNodeGetName(n)

        if not potrebniNodovi[nodeName] then
            potrebniNodovi[nodeName] = { count = 0 }
        end

        if UNIQUE_ATTR[nodeName] then
            table.insert(potrebniNodovi[nodeName], xmlNodeGetAttribute(n, UNIQUE_ATTR[nodeName]) )
        else
            potrebniNodovi[nodeName].count = potrebniNodovi[nodeName].count + 1
        end
    end

    for _, n in ipairs( xmlNodeGetChildren(userNode) ) do
        local nodeName = xmlNodeGetName(n)

        if potrebniNodovi[nodeName] then
            if UNIQUE_ATTR[nodeName] then
                local uAttr = xmlNodeGetAttribute(n, UNIQUE_ATTR[nodeName])
                local nasao = false
                for _, potrebniUAttr in ipairs( potrebniNodovi[nodeName] ) do
                    if potrebniUAttr == uAttr then
                        potrebniNodovi[nodeName][uAttr] = nil
                        nasao = true
                        break
                    end
                end
                if not nasao then xmlDestroyNode(n) end
            else
                local preostalo = potrebniNodovi[nodeName].count - 1
                potrebniNodovi[nodeName].count = (preostalo > 0 and preostalo) or nil
            end
        else
            xmlDestroyNode(n)
        end
    end
end


-- dat mu je array-a nodova i node po kom koristeci se UNIQUE_ATTR-om treba da nadje da li node postoji u array-u ili vraca nil
function Comparator._getCorrespondingNodes(nodeArray, node)
    local moguciNodovi = {}

    -- node-ovi sa istim imenom
    for _, n in ipairs(nodeArray) do
        if xmlNodeGetName(n) == xmlNodeGetName(node) then
            moguciNodovi[#moguciNodovi+1] = n
        end
    end


    local unikatniAtribut = UNIQUE_ATTR[xmlNodeGetName(node)]

    -- nema nodova uopste, a kamoli sa unikatnim atributom
    if #moguciNodovi == 0 then
        return nil
    end
    
    -- ako dati node nema unikatni atribut onda ne mozemo da znamo koji od node-ova iz array-a je par
    if not unikatniAtribut then
        return moguciNodovi[1]
    end

    -- nadjemo node koji ima unikatni atribut kao node sa kojim uporedjujemo
    for _, n in ipairs(moguciNodovi) do
        
        if xmlNodeGetAttribute(n, unikatniAtribut) == xmlNodeGetAttribute(node, unikatniAtribut) then
            return n
        end

    end
end

function Comparator._fix(node1, node2)

    -- namestamo ime
    xmlNodeSetName(node1, xmlNodeGetName(node2))

    --proveravamo atribute
    for attr, value in pairs(xmlNodeGetAttributes(node2)) do
        -- ako node1 nema atribut kao node2 kopiramo ga iz node2 u node1
        if not xmlNodeGetAttribute(node1, attr) then
            xmlNodeSetAttribute(node1, attr, value)
        end
    end


    -- proveravamo vrednost
    local standardValue = xmlNodeGetValue(node2)
    
    -- ako postoji standardna vrednost i node value ne sme da bude prazan string
    if #standardValue ~= 0 and not xmlNodeGetAttribute(node2, "allowEmpty") then
        -- ako je node1 vrednost prazna a znamo da ne sme da bude 
        if #xmlNodeGetValue(node1) == 0 then
            xmlNodeSetValue(node1, standardValue)
        end
    end
end

function Comparator:copy(nodeToCopy, where, rekruzija)
    local newNode = xmlCreateChild(where, xmlNodeGetName(nodeToCopy))

    -- kopiramo atribute
    for attr, value in pairs(xmlNodeGetAttributes(nodeToCopy)) do
        xmlNodeSetAttribute(newNode, attr, value)
    end

    xmlNodeSetValue(newNode, xmlNodeGetValue(nodeToCopy))

    if rekruzija then
        for _, childNode in ipairs(xmlNodeGetChildren(nodeToCopy)) do
            self:copy(childNode, newNode, true)
        end
    end
end