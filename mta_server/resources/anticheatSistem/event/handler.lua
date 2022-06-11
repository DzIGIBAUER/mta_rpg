
function validate_event(args)
    for var, zeljeni_tip in pairs(args) do
        local tip = (isElement(var) and getElementType(var)) or type(var)
        
        if tip ~= zeljeni_tip then
            error(("Loš argument za event (%s očekivan, dobijen %s(%s))"):format(zeljeni_tip, tip, var), 2)
        end
    end
end
