-- Leon X | Icon Loader
-- Fetches Lucide icons from GitHub and provides helper functions

local Icons = {}
Icons._cache = nil
Icons._loaded = false

local BASE_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"

-- Load the icon table from GitHub
function Icons:Load()
    if self._loaded and self._cache then return self._cache end
    
    local ok, result = pcall(function()
        local src = game:HttpGet(BASE_URL .. "?t=" .. tostring(os.time()), true)
        if not src or #src < 10 then error("empty response") end
        local fn, err = loadstring(src)
        if not fn then error("loadstring failed: " .. tostring(err)) end
        return fn()
    end)
    
    if ok and type(result) == "table" then
        self._cache = result
        self._loaded = true
        return result
    else
        warn("[LeonX-Icons] Failed to load icons: " .. tostring(result))
        self._cache = {}
        self._loaded = true
        return {}
    end
end

-- Get an icon asset ID by name
-- Returns rbxassetid string or nil
function Icons.get(name)
    if not name or name == "" then return nil end
    if not Icons._cache then Icons:Load() end
    return Icons._cache and Icons._cache[name] or nil
end

-- Create an ImageLabel with the given icon
-- Returns the ImageLabel instance, or nil if icon not found
function Icons.image(parent, name, size, color, zindex)
    local assetId = Icons.get(name)
    if not assetId then return nil end
    
    size = size or 18
    color = color or Color3.fromRGB(255, 255, 255)
    zindex = zindex or 1
    
    local img = Instance.new("ImageLabel")
    img.Name = "Icon_" .. name
    img.Size = UDim2.fromOffset(size, size)
    img.BackgroundTransparency = 1
    img.BorderSizePixel = 0
    img.Image = assetId
    img.ImageColor3 = color
    img.ScaleType = Enum.ScaleType.Fit
    img.ZIndex = zindex
    
    if parent then
        img.Parent = parent
    end
    
    return img
end

-- Create an icon button (ImageButton)
function Icons.button(parent, name, size, color, zindex)
    local assetId = Icons.get(name)
    if not assetId then return nil end
    
    size = size or 18
    color = color or Color3.fromRGB(255, 255, 255)
    zindex = zindex or 1
    
    local btn = Instance.new("ImageButton")
    btn.Name = "IconBtn_" .. name
    btn.Size = UDim2.fromOffset(size, size)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Image = assetId
    btn.ImageColor3 = color
    btn.ScaleType = Enum.ScaleType.Fit
    btn.AutoButtonColor = false
    btn.ZIndex = zindex
    
    if parent then
        btn.Parent = parent
    end
    
    return btn
end

return Icons
