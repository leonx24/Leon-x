local Fly = {}

Fly.Name = "Fly"
Fly.Enabled = false

function Fly:Enable()
    self.Enabled = true

    print("Fly Enabled")
end

function Fly:Disable()
    self.Enabled = false

    print("Fly Disabled")
end

function Fly:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

return Fly
