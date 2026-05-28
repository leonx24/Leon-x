
local Notifications = {}

function Notifications:Send(data)
    local title = data.Title or "Leon X"
    local text = data.Text or ""
    local duration = data.Duration or 3

    print(title .. " : " .. text)

    -- nanti disini UI notification
end

return Notifications
