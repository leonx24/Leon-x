local Modules = {}

function Modules:Register(module)
    Modules[module.Name] = module
end

function Modules:Get(name)
    return Modules[name]
end

function Modules:Enable(name)
    local module = Modules[name]

    if module and module.Enable then
        module:Enable()
    end
end

function Modules:Disable(name)
    local module = Modules[name]

    if module and module.Disable then
        module:Disable()
    end
end

function Modules:Toggle(name)
    local module = Modules[name]

    if not module then
        return
    end

    if module.Enabled then
        module:Disable()
    else
        module:Enable()
    end
end

return Modules

