local Toggle = {}

function Toggle:Create(parent, data)
    local callback = data.Callback or function() end

    local enabled = false

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,0,0,32)
    button.Text = data.Name or "Toggle"
    button.Parent = parent

    button.MouseButton1Click:Connect(function()
        enabled = not enabled

        callback(enabled)
    end)

    return button
end

return Toggle
