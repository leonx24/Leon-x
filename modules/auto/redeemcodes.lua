-- Leon X | Auto Redeem Codes
-- Automatically tries to redeem game codes via common remote patterns
-- Supports auto-detection from GUIs, workspace signs, and common patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer

local RedeemCodes = {}
RedeemCodes.Name = "RedeemCodes"
RedeemCodes.Enabled = false
RedeemCodes.Codes = {} -- list of codes to try
RedeemCodes.Results = {} -- { code = "success"|"failed"|"already"|"unknown" }
RedeemCodes.AutoDetectEnabled = true

-- Common remote names used for code redemption
local REMOTE_PATTERNS = {
    "RedeemCode", "redeemCode", "Redeem", "redeem",
    "EnterCode", "enterCode", "Code", "code",
    "ClaimCode", "claimCode", "UseCode", "useCode",
    "ApplyCode", "applyCode", "SubmitCode", "submitCode",
    "PromoCode", "promoCode", "GiftCode", "giftCode",
    "RedeemPromo", "redeemPromo", "ActivateCode", "activateCode"
}

-- Common folder locations for remotes
local REMOTE_LOCATIONS = {
    "Remotes", "RemoteEvents", "RemoteFunctions", "Events",
    "Network", "Networking", "Functions", "API", "Communication",
    "PlayerData", "GameData", "Main", "Server"
}

local function findCodeRemotes()
    local found = {}
    
    -- Search in common locations
    for _, locName in ipairs(REMOTE_LOCATIONS) do
        local folder = ReplicatedStorage:FindFirstChild(locName)
        if folder then
            for _, pattern in ipairs(REMOTE_PATTERNS) do
                local remote = folder:FindFirstChild(pattern)
                if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                    found[#found + 1] = { remote = remote, path = locName .. "." .. pattern }
                end
            end
        end
    end
    
    -- Also search directly in ReplicatedStorage
    for _, pattern in ipairs(REMOTE_PATTERNS) do
        local remote = ReplicatedStorage:FindFirstChild(pattern)
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
            found[#found + 1] = { remote = remote, path = pattern }
        end
    end
    
    -- Search recursively with depth limit
    local function searchRecursive(parent, depth, path)
        if depth > 3 then return end
        for _, child in ipairs(parent:GetChildren()) do
            local childPath = path .. "." .. child.Name
            for _, pattern in ipairs(REMOTE_PATTERNS) do
                if child.Name:lower() == pattern:lower() then
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                        found[#found + 1] = { remote = child, path = childPath }
                    end
                end
            end
            if child:IsA("Folder") or child:IsA("ModuleScript") then
                searchRecursive(child, depth + 1, childPath)
            end
        end
    end
    
    searchRecursive(ReplicatedStorage, 0, "ReplicatedStorage")
    
    return found
end

local function tryRedeemCode(remote, code)
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(code)
            return "fired"
        elseif remote:IsA("RemoteFunction") then
            local response = remote:InvokeServer(code)
            return response
        end
    end)
    
    if success then
        -- Try to interpret the result
        if type(result) == "string" then
            local lower = result:lower()
            if lower:find("success") or lower:find("redeemed") or lower:find("claimed") then
                return "success"
            elseif lower:find("already") or lower:find("used") then
                return "already"
            elseif lower:find("invalid") or lower:find("expired") or lower:find("failed") then
                return "failed"
            end
        elseif type(result) == "boolean" then
            return result and "success" or "failed"
        elseif type(result) == "table" then
            -- Some games return structured responses
            if result.success == true or result.Success == true then
                return "success"
            elseif result.already or result.Already then
                return "already"
            end
        end
        -- Assume success if no error and we got a response
        return result == "fired" and "unknown" or "success"
    end
    
    return "failed"
end

-- ── Auto-Detection Functions ────────────────────────────────────────────────

-- Common code patterns to try
local COMMON_CODES = {
    -- Release/Update codes
    "RELEASE", "UPDATE", "NEWUPDATE", "NEWCODE", "CODE",
    "SORRY", "THANKYOU", "THANKS", "WELCOME",
    -- Milestone codes
    "100K", "500K", "1M", "10K", "50K", "25K",
    "100KLIKES", "50KLIKES", "10KLIKES",
    -- Event codes
    "HALLOWEEN", "CHRISTMAS", "NEWYEAR", "EASTER",
    "SUMMER", "WINTER", "SPRING", "FALL",
    -- Free stuff
    "FREE", "FREE100", "FREEGEMS", "FREEREWARDS",
    "GIFT", "REWARD", "BONUS", "CLAIM",
    -- Game-specific patterns
    "JOIN", "PLAY", "START", "BEGIN",
}

-- Check if text looks like a code
local function looksLikeCode(text)
    if not text or type(text) ~= "string" then return false end
    text = text:match("^%s*(.-)%s*$") -- trim
    if text == "" then return false end
    
    -- Codes are usually:
    -- - All caps or mixed case
    -- - Alphanumeric (letters and numbers)
    -- - 3-20 characters
    -- - No spaces (or underscores)
    
    local len = #text
    if len < 3 or len > 25 then return false end
    
    -- Must contain letters
    if not text:match("[a-zA-Z]") then return false end
    
    -- Should be mostly alphanumeric (allow underscores and hyphens)
    if not text:match("^[a-zA-Z0-9_-]+$") then return false end
    
    -- Skip common non-code words
    local skipWords = {
        "the", "and", "for", "you", "are", "was", "were", "been",
        "click", "button", "text", "label", "frame", "gui", "script",
        "true", "false", "nil", "yes", "no", "ok", "cancel"
    }
    local lower = text:lower()
    for _, word in ipairs(skipWords) do
        if lower == word then return false end
    end
    
    return true
end

-- Scan GUIs for code-like text
local function scanGUIsForCodes()
    local found = {}
    
    local function scanInstance(instance)
        pcall(function()
            -- Check TextLabels and TextButtons
            if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
                local text = instance.Text
                if text and looksLikeCode(text) then
                    found[text] = true
                end
                
                -- Also check if text contains "CODE:" or similar patterns
                if text then
                    local codeMatch = text:match("[Cc][Oo][Dd][Ee][:;%s]+([a-zA-Z0-9_-]+)")
                    if codeMatch and looksLikeCode(codeMatch) then
                        found[codeMatch] = true
                    end
                end
            end
        end)
        
        -- Recurse into children
        for _, child in ipairs(instance:GetChildren()) do
            scanInstance(child)
        end
    end
    
    -- Scan player GUI
    pcall(function()
        local playerGui = lp:FindFirstChild("PlayerGui")
        if playerGui then
            scanInstance(playerGui)
        end
    end)
    
    -- Scan StarterGui
    pcall(function()
        scanInstance(StarterGui)
    end)
    
    return found
end

-- Scan workspace for signs/billboards with codes
local function scanWorkspaceForCodes()
    local found = {}
    
    local function scanInstance(instance, depth)
        if depth > 5 then return end
        
        pcall(function()
            -- Check SurfaceGuis (signs, billboards)
            if instance:IsA("SurfaceGui") then
                for _, child in ipairs(instance:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        local text = child.Text
                        if text and looksLikeCode(text) then
                            found[text] = true
                        end
                        
                        -- Check for "CODE:" pattern
                        if text then
                            local codeMatch = text:match("[Cc][Oo][Dd][Ee][:;%s]+([a-zA-Z0-9_-]+)")
                            if codeMatch and looksLikeCode(codeMatch) then
                                found[codeMatch] = true
                            end
                            -- Also try "USE CODE" pattern
                            local useCodeMatch = text:match("[Uu][Ss][Ee]%s+[Cc][Oo][Dd][Ee][:;%s]+([a-zA-Z0-9_-]+)")
                            if useCodeMatch and looksLikeCode(useCodeMatch) then
                                found[useCodeMatch] = true
                            end
                        end
                    end
                end
            end
            
            -- Check BillboardGuis
            if instance:IsA("BillboardGui") then
                for _, child in ipairs(instance:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        local text = child.Text
                        if text then
                            local codeMatch = text:match("[Cc][Oo][Dd][Ee][:;%s]+([a-zA-Z0-9_-]+)")
                            if codeMatch and looksLikeCode(codeMatch) then
                                found[codeMatch] = true
                            end
                        end
                    end
                end
            end
        end)
        
        -- Recurse
        for _, child in ipairs(instance:GetChildren()) do
            scanInstance(child, depth + 1)
        end
    end
    
    pcall(function()
        scanInstance(workspace, 0)
    end)
    
    return found
end

-- Generate common code variations
local function generateCommonCodes()
    local codes = {}
    for _, code in ipairs(COMMON_CODES) do
        codes[code] = true
    end
    
    -- Try some year-based codes
    local year = os.date("%Y")
    codes[year] = true
    codes["NEW" .. year] = true
    codes[year .. "CODE"] = true
    
    return codes
end

-- Main auto-detect function
function RedeemCodes:AutoDetect()
    print("[Leon X] RedeemCodes: Auto-detecting codes from game...")
    
    local allCodes = {}
    
    -- Scan GUIs
    local guiCodes = scanGUIsForCodes()
    for code in pairs(guiCodes) do
        allCodes[code] = "gui"
        print("[Leon X] RedeemCodes: Found in GUI: " .. code)
    end
    
    -- Scan workspace
    local workspaceCodes = scanWorkspaceForCodes()
    for code in pairs(workspaceCodes) do
        allCodes[code] = "workspace"
        print("[Leon X] RedeemCodes: Found on sign: " .. code)
    end
    
    -- Add common codes
    if self.AutoDetectEnabled then
        local commonCodes = generateCommonCodes()
        for code in pairs(commonCodes) do
            if not allCodes[code] then
                allCodes[code] = "common"
            end
        end
        print("[Leon X] RedeemCodes: Added " .. #COMMON_CODES .. " common code patterns")
    end
    
    -- Convert to array
    local codesArray = {}
    for code, source in pairs(allCodes) do
        codesArray[#codesArray + 1] = { code = code, source = source }
    end
    
    -- Sort by source priority (gui > workspace > common)
    table.sort(codesArray, function(a, b)
        local priority = { gui = 1, workspace = 2, common = 3 }
        return (priority[a.source] or 99) < (priority[b.source] or 99)
    end)
    
    -- Extract just the codes
    self.Codes = {}
    for _, item in ipairs(codesArray) do
        self.Codes[#self.Codes + 1] = item.code
    end
    
    print("[Leon X] RedeemCodes: Auto-detected " .. #self.Codes .. " total codes")
    return self.Codes
end

function RedeemCodes:Enable()
    self.Enabled = true
    self.Results = {}
    
    -- Auto-detect if no codes loaded
    if #self.Codes == 0 then
        print("[Leon X] RedeemCodes: No codes provided, running auto-detect...")
        self:AutoDetect()
        if #self.Codes == 0 then
            print("[Leon X] RedeemCodes: No codes found")
            self.Enabled = false
            return
        end
    end
    
    -- Find code redemption remotes
    local remotes = findCodeRemotes()
    if #remotes == 0 then
        print("[Leon X] RedeemCodes: No code redemption remotes found")
        print("[Leon X] RedeemCodes: This game may not have a code system, or it uses a different method")
        for _, code in ipairs(self.Codes) do
            self.Results[code] = "no_remote"
        end
        return
    end
    
    print("[Leon X] RedeemCodes: Found " .. #remotes .. " potential remote(s)")
    
    -- Try each code with each remote
    for _, code in ipairs(self.Codes) do
        local codeResult = "failed"
        
        for _, remoteData in ipairs(remotes) do
            local result = tryRedeemCode(remoteData.remote, code)
            print("[Leon X] RedeemCodes: Code '" .. code .. "' via " .. remoteData.path .. " = " .. tostring(result))
            
            if result == "success" then
                codeResult = "success"
                break
            elseif result == "already" then
                codeResult = "already"
            elseif result == "unknown" and codeResult ~= "success" then
                codeResult = "unknown"
            end
            
            task.wait(0.1) -- Small delay between attempts
        end
        
        self.Results[code] = codeResult
        task.wait(0.2) -- Delay between codes
    end
    
    self.Enabled = false -- Auto-disable after completion
    print("[Leon X] RedeemCodes: Completed. Results available via :GetResults()")
end

function RedeemCodes:Disable()
    self.Enabled = false
end

function RedeemCodes:SetCodes(codes)
    if type(codes) == "table" then
        self.Codes = codes
    elseif type(codes) == "string" then
        -- Parse comma or newline separated codes
        self.Codes = {}
        for code in codes:gmatch("[^,%s]+") do
            code = code:match("^%s*(.-)%s*$") -- trim whitespace
            if code ~= "" then
                self.Codes[#self.Codes + 1] = code
            end
        end
    end
end

function RedeemCodes:GetResults()
    return self.Results
end

function RedeemCodes:GetSummary()
    local summary = {
        success = 0,
        failed = 0,
        already = 0,
        unknown = 0,
        no_remote = 0
    }
    
    for code, result in pairs(self.Results) do
        if summary[result] then
            summary[result] = summary[result] + 1
        end
    end
    
    return summary
end

function RedeemCodes:ScanRemotes()
    -- Utility to scan and print found remotes (for debugging)
    local remotes = findCodeRemotes()
    print("[Leon X] RedeemCodes: Scan found " .. #remotes .. " remote(s):")
    for _, data in ipairs(remotes) do
        print("  - " .. data.path .. " (" .. data.remote.ClassName .. ")")
    end
    return remotes
end

return RedeemCodes
