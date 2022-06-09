local _active = {}

local _async_element_root = createElement("AsyncRoot")

--- [[ INVOKE ]]
local function _dbQuery_callback(handle, co_ref)
    coroutine.resume(deref(co_ref), handle)
end

local function _dbQuery_invoke(_async_obj, co, func, args)
    table.insert(args, 1, _dbQuery_callback)
    table.insert(args, 2, {ref(co)})
    func(unpack(args))
end


local function _triggerEvent_invoke(async_obj, _co, func, args)
    args[#args+1] = async_obj

    func(unpack(args))
end

local _invoke = {
    [dbQuery] = _dbQuery_invoke,
    [triggerEvent] = _triggerEvent_invoke,
    [triggerClientEvent] = _triggerEvent_invoke,
    [triggerLatentClientEvent] = _triggerEvent_invoke
}
------------------


--- [[ AWAIT ]]
local _await = {}

function _await:__call(args)
    local co = coroutine.running()
    assert(co, "Await može biti pozvan samo unutar async funkcije.")

    local async_element = _active[co]
    assert(async_element, "Nije pronađen async element u tabeli pod ključem coroutine.")

    local func = args[1]
    assert(type(func) == "function", "Await nije dobio funkciju kao prvi argument.")

    local func_args = { select(2, unpack(args)) }


    local invoke_func = _invoke[func]
    assert(invoke_func, "Nije dodata async implementacija ove funkcije.")

    invoke_func(async_element, co, func, func_args)
    return coroutine.yield()
end

local await = setmetatable({}, _await)
------------------


--- [[ ASYNC ]]
local _async = {}

function _async:__call(args)
    local func = args[1]
    assert(type(func) == "function", "Async nije dobio funkciju kao prvi argument.")

    return function(...)
        local function _wrapper_function(...)
            func(...)
            local co = coroutine.running()
            destroyElement(_active[co])
            _active[co] = nil
        end

        local async_element = createElement("Async")
        setElementParent(async_element, _async_element_root)

        local co = coroutine.create(_wrapper_function)

        _active[co] = async_element

        coroutine.resume(co, ...)
    end
end

local async = setmetatable({}, _async)
------------------

--- [[ RESOLVE ]]
local function _resolve(async_element, ...)
    assert(isElement(async_element) and getElementType(async_element) == "Async", "Očekivan Async element kao prvi argument resolve funkcije.")

    --- Ako smo na serveru.
    if not localPlayer then
        --- Ako je event sa client-a.
        if client then
            triggerClientEvent(client, "AsyncSistem:resolved", async_element, ...)
        --- Ako je event sa servera.
        else
            triggerEvent("AsyncSistem:resolved", async_element, ...)
        end
    --- Ako smo na client-u.
    else
        --- Ako je event sa servera.
        if not isElementLocal(async_element) then
            triggerServerEvent("AsyncSistem:resolved", async_element, ...)
        --- Ako je event sa client-a.
        else
            triggerEvent("AsyncSistem:resolved", async_element, ...)
        end
    end

end

local function _call_resolved(...)
    for co, async_element in pairs(_active) do
        if async_element == source then
            setTimer(function(...) coroutine.resume(co, ...) end, 1, 1, ...)
        end
    end
end
addEvent("AsyncSistem:resolved", true)
addEventHandler("AsyncSistem:resolved", _async_element_root, _call_resolved)
------------------

--- [[ AEH WRAPPER ]]
local _addEventHandler = addEventHandler
local function addEventHandler(event_name, attached_to, function_handler, get_propagated, priority)
    local function _wrapper_function(...)
        local args = {...}

        local async_element = args[#args]

        if not isElement(async_element) or getElementType(async_element) ~= "Async" then
            function_handler(unpack(args))
            return
        end

        local resolve = function(...) _resolve(async_element, ...) end
        args[#args] = nil

        local new_env = {resolve = resolve}
        setmetatable(new_env, {__index = _G})
        setfenv(function_handler, new_env)

        function_handler(unpack(args))
    end

    if not _addEventHandler(event_name, attached_to, _wrapper_function, get_propagated, priority) then
        return false 
    end

end
------------------