Comparator = {}
Comparator.__index = Comparator

--- koji atribut je unikatan za koji XML node,
-- tj. po cemu gledamo da li se potreban node nalazi u fajlu
local UNIQUE_ATTR = {
    ["bind"] = "functionName"
}


function Comparator.new()
    local self = setmetatable({}, Comparator)

    return self
end


--- Ucinice da 'user_node' ima sve potrebne node-ove koje odredjuej 'server_node',
-- nedirajuci vec postojece node-ove sa izmenjenim atributima, kako bi igrac mogao
-- da ih uredjuje bez stvaranja konfuzije u ovoj metodi.
-- @param user_node xmlnode: Xml Node korisnika koje proveravamo.
-- @param server_node xmlnode: Xml Node odakle kopiramo nedostajuce nodoe-ove.
-- @param[opt] izbrisi_nepotrebne bool: Da li da izbrisemo node-ove koji su visak ili da ih ostavimo.
-- @param[opt] rekruzija bool: Da li da primenimo ovu metodu i na decu 'user_node'-a, ako ih ima.
function Comparator:compare_and_fix(user_node, server_node, izbrisi_nepotrebne, rekruzija)

    if rekruzija then
        local user_node_children = xmlNodeGetChildren(user_node)
        local server_node_children = xmlNodeGetChildren(server_node)
        for _, n in ipairs(server_node_children) do

            local node_to_check = self.get_corresponding_nodes(user_node_children, n)
            
            if node_to_check then
                self:compare_and_fix(node_to_check, n, izbrisi_nepotrebne, rekruzija)
            else
                self:copy(n, user_node, true)
            end
        end

    end

    if izbrisi_nepotrebne then
        self.remove_duplicates(user_node, server_node)
    end

    self.fix(user_node, server_node)
end

--- Izbrisace suvisne node-ove iz 'user_node' koristeci 'server_node' kao nacin provere
-- da li je odredjeni node suvisan.
-- Ako node nema unikatan atribut 'count' ce biti inkrementovan, u suprotnom samo ce biti dodat u tabelu.-
-- @param user_node xmlnode: odalke sklanjamo suvisne node-ove.
-- @param server_node xmlnode: koje xmlnode nam govori koji node-ovi nisu visak.
function Comparator.remove_duplicates(user_node, server_node)
    local potrebni_nodovi = {--[[ bind: {count: 5, {u_arrt1, u_attr2} } ]]}
    
    for _, n in ipairs( xmlNodeGetChildren(server_node) ) do
        local node_name = xmlNodeGetName(n)

        if not potrebni_nodovi[node_name] then
            potrebni_nodovi[node_name] = { count = 0 }
        end

        if UNIQUE_ATTR[node_name] then
            table.insert(potrebni_nodovi[node_name], xmlNodeGetAttribute(n, UNIQUE_ATTR[node_name]) )
        else
            potrebni_nodovi[node_name].count = potrebni_nodovi[node_name].count + 1
        end
    end

    for _, n in ipairs( xmlNodeGetChildren(user_node) ) do
        local node_name = xmlNodeGetName(n)

        if potrebni_nodovi[node_name] then
            if UNIQUE_ATTR[node_name] then
                local u_attr = xmlNodeGetAttribute(n, UNIQUE_ATTR[node_name])
                local nasao = false
                for _, potrebniu_attr in ipairs( potrebni_nodovi[node_name] ) do
                    if potrebniu_attr == u_attr then
                        potrebni_nodovi[node_name][u_attr] = nil
                        nasao = true
                        break
                    end
                end
                if not nasao then xmlDestroyNode(n) end

            else
                local preostalo = potrebni_nodovi[node_name].count - 1
                potrebni_nodovi[node_name].count = (preostalo > 0 and preostalo) or nil
            end

        else
            xmlDestroyNode(n)
        end
    end
end


--- Dat mu je array-a nodova i node po kom koristeci se UNIQUE_ATTR-om
-- treba da nadje da li node postoji u tabeli ili vraca nil.
-- @param nodes table: Tabela iz koje trazimo node koji se najvise podudara sa 'node'.
-- @param node xmlnode: Koji node trazimo u 'nodes'.
function Comparator.get_corresponding_nodes(nodes, node)
    local moguci_nodovi = {}

    -- node-ovi sa istim imenom
    for _, n in ipairs(nodes) do
        if xmlNodeGetName(n) == xmlNodeGetName(node) then
            moguci_nodovi[#moguci_nodovi+1] = n
        end
    end


    local unikatni_atribut = UNIQUE_ATTR[xmlNodeGetName(node)]

    -- nema nodova uopste, a kamoli sa unikatnim atributom
    if #moguci_nodovi == 0 then
        return nil
    end
    
    -- ako dati node nema unikatni atribut onda ne mozemo da znamo koji od node-ova iz array-a je par
    if not unikatni_atribut then
        return moguci_nodovi[1]
    end

    -- nadjemo node koji ima unikatni atribut kao node sa kojim uporedjujemo
    for _, n in ipairs(moguci_nodovi) do
        
        if xmlNodeGetAttribute(n, unikatni_atribut) == xmlNodeGetAttribute(node, unikatni_atribut) then
            return n
        end

    end
end

--- Popravice 'node1' tako da ima sve potrebne atribute i vrednost kao 'node2',
-- ali nece dirati vec postojece atribute ako su izmenjeni, sem ako u pitanju
-- nije unikatni atribut.
-- @param node1 xmlnode: node koji popravljamo.
-- @param node2 xmlnode: node koji predstavlja ispravan node.
function Comparator.fix(node1, node2)

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

--- Kopira 'node_to_copy' da bude dete 'target_node'-a.
-- @param node_to_copy xmlnode: koji node kopiramo.
-- @param target_node xmlnode: koji node ce biti roditelj node-a koji kopiramo.
-- @param[opt] rekruzija bool: da li koristimo ovu metodu i na deci 'node_to_copy',
-- sve dok ne kopiramo sve niz hijerarhiju.
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