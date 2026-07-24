-- Leon X | Discord Webhook Logger
-- Utility module to post game logs and notifications to a Discord Webhook URL

local WebhookLogger = {}
WebhookLogger.Name    = "WebhookLogger"
WebhookLogger.Enabled = false
WebhookLogger.Url     = ""

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local lp          = Players.LocalPlayer

local function getRequestFunc()
    if request then return request end
    if http_request then return http_request end
    if syn and syn.request then return syn.request end
    if httprequest then return httprequest end
    return nil
end

function WebhookLogger:SetUrl(url)
    self.Url = tostring(url or "")
end

function WebhookLogger:Send(title, description, color, fields)
    if not self.Url or self.Url == "" or not self.Url:find("discord") then
        return false, "Invalid or empty Webhook URL"
    end

    local payload = {
        username = "Leon X Logger",
        avatar_url = "https://raw.githubusercontent.com/leonx24/Leon-x/main/assets/logo.png",
        embeds = {
            {
                title       = title or "Leon X Event",
                description = description or "",
                color       = color or 0x829bd2,
                fields      = fields or {},
                footer      = {
                    text = "Player: " .. lp.Name .. " (" .. tostring(lp.UserId) .. ")"
                },
                timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    local jsonPayload
    local ok, err = pcall(function()
        jsonPayload = HttpService:JSONEncode(payload)
    end)
    if not ok then return false, err end

    local reqFunc = getRequestFunc()
    if reqFunc then
        local success, res = pcall(function()
            return reqFunc({
                Url     = self.Url,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = jsonPayload
            })
        end)
        return success, res
    else
        local success, res = pcall(function()
            return game:HttpPost(self.Url, jsonPayload, false, "application/json")
        end)
        return success, res
    end
end

function WebhookLogger:Enable()
    self.Enabled = true
end

function WebhookLogger:Disable()
    self.Enabled = false
end

function WebhookLogger:Toggle()
    self.Enabled = not self.Enabled
end

return WebhookLogger
