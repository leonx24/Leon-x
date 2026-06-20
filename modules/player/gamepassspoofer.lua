-- Leon X | GamepassSpoofer
-- Hooks MarketplaceService to spoof gamepass/asset ownership
-- Game thinks you own ALL gamepasses — works on games with weak security

local GamepassSpoofer = {}
GamepassSpoofer.Name    = "GamepassSpoofer"
GamepassSpoofer.Enabled = false

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local lp                 = Players.LocalPlayer

local originalOwnsGP    = nil
local originalOwnsAsset = nil
local originalPromptGP  = nil
local hookSupported     = true

-- Check if executor supports required functions
local function checkExecutorSupport()
    if not hookfunction then
        warn("[Leon X] GamepassSpoofer: hookfunction not available")
        return false
    end
    if not newcclosure then
        warn("[Leon X] GamepassSpoofer: newcclosure not available")
        return false
    end
    return true
end

function GamepassSpoofer:Enable()
    if self.Enabled then return end

    if not checkExecutorSupport() then
        hookSupported = false
        print("[Leon X] GamepassSpoofer: Executor doesn't support required hooks")
        return
    end

    self.Enabled = true

    -- Hook UserOwnsGamePassAsync — always return true
    pcall(function()
        originalOwnsGP = hookfunction(
            MarketplaceService.UserOwnsGamePassAsync,
            newcclosure(function(self, userId, gamePassId)
                -- Only spoof for local player
                if userId == lp.UserId then
                    return true
                end
                -- Pass through for other players
                return originalOwnsGP(self, userId, gamePassId)
            end)
        )
    end)

    -- Hook PlayerOwnsAsset — always return true for local player
    pcall(function()
        originalOwnsAsset = hookfunction(
            MarketplaceService.PlayerOwnsAsset,
            newcclosure(function(self, player, assetId)
                if player == lp then
                    return true
                end
                return originalOwnsAsset(self, player, assetId)
            end)
        )
    end)

    -- Hook PromptGamePassPurchase to silently ignore purchase prompts
    pcall(function()
        originalPromptGP = hookfunction(
            MarketplaceService.PromptGamePassPurchase,
            newcclosure(function(self, player, gamePassId)
                if player == lp then
                    return  -- silently ignore
                end
                return originalPromptGP(self, player, gamePassId)
            end)
        )
    end)

    print("[Leon X] GamepassSpoofer: Enabled — spoofing gamepass ownership")
end

function GamepassSpoofer:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    -- Restore original functions
    pcall(function()
        if originalOwnsGP then
            hookfunction(MarketplaceService.UserOwnsGamePassAsync, originalOwnsGP)
            originalOwnsGP = nil
        end
    end)

    pcall(function()
        if originalOwnsAsset then
            hookfunction(MarketplaceService.PlayerOwnsAsset, originalOwnsAsset)
            originalOwnsAsset = nil
        end
    end)

    pcall(function()
        if originalPromptGP then
            hookfunction(MarketplaceService.PromptGamePassPurchase, originalPromptGP)
            originalPromptGP = nil
        end
    end)

    print("[Leon X] GamepassSpoofer: Disabled — restored original functions")
end

function GamepassSpoofer:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function GamepassSpoofer:IsSupported()
    return hookSupported
end

return GamepassSpoofer
