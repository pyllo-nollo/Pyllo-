-- AFKNILLO 10/10 (fixed v3)
-- Paste and execute once. It re-executes itself on every server change.

local SRC = [====[
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

local SOURCE = ... -- this script's own code, passed in by the loader below

-- ===== CONFIG =====
local CONFIG = {
    INTERVAL = 60,      -- seconds between pulses
    AUTO_REJOIN = true, -- rejoin if disconnected
    HIDE_AFTER = 8,     -- seconds until the text becomes discreet
}

-- ===== DUPLICATE GUARD =====
local env = (getgenv and getgenv()) or _G
if env.Afknillo == game.JobId then return end
env.Afknillo = game.JobId

-- ===== STATE =====
local active = true
local paused = false
local state = "starting" -- starting | on | error | paused | reconnecting
local lastPulse = os.clock()
local showUntil = os.clock() + CONFIG.HIDE_AFTER
local connections = {}

-- ===== RE-EXECUTE AFTER EVERY TELEPORT/REJOIN =====
pcall(function()
    local q = queue_on_teleport or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    if q and SOURCE then
        -- pick a long-bracket level that does NOT appear inside the source,
        -- otherwise the wrapper would close too early and break
        local eq = "="
        while SOURCE:find("]" .. eq .. "]", 1, true)
           or SOURCE:find("[" .. eq .. "[", 1, true) do
            eq = eq .. "="
        end
        local open, close = "[" .. eq .. "[", "]" .. eq .. "]"
        q("local S=" .. open .. SOURCE .. close .. " local f=loadstring(S) if f then f(S) end")
    end
end)

-- ===== INTERFACE =====
local gui, btn
local guiOk, guiErr = pcall(function()
    local parent
    pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not parent then parent = player:WaitForChild("PlayerGui") end

    local old = parent:FindFirstChild("Afknillo")
    if old then old:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "Afknillo"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = parent

    btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(260, 22)
    btn.Position = UDim2.new(0, 6, 0, 6)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextStrokeTransparency = 0.5
    btn.Text = "afknillo starting..."
    btn.TextColor3 = Color3.fromRGB(255, 220, 80)
    btn.Parent = gui
end)

if not guiOk then
    env.Afknillo = nil
    warn("[AFKNILLO] Interface error:", guiErr)
    return
end

local function shutdown()
    if not active then return end
    active = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    if gui then gui:Destroy() end
    env.Afknillo = nil
end

-- ===== PULSE (main method + fallback) =====
local function mainMethod()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end

local function fallbackMethod()
    -- only "moves" the mouse to where it already is (no click, no character movement)
    local vim = game:GetService("VirtualInputManager")
    local pos = UIS:GetMouseLocation()
    vim:SendMouseMoveEvent(pos.X, pos.Y, game)
end

local function pulse()
    if not active or paused or state == "reconnecting" then return end
    local ok = pcall(mainMethod)
    if not ok then ok = pcall(fallbackMethod) end
    if ok then
        lastPulse = os.clock()
        state = "on"
    else
        state = "error"
    end
end

-- disable the default idle kick, if the executor supports it
pcall(function()
    if getconnections then
        for _, c in ipairs(getconnections(player.Idled)) do
            if c.Disable then c:Disable() end
        end
    end
end)

table.insert(connections, player.Idled:Connect(pulse))

-- ===== AUTO REJOIN =====
local rejoining = false
local function rejoin()
    if rejoining or not CONFIG.AUTO_REJOIN or not active then return end
    rejoining = true
    state = "reconnecting"
    showUntil = math.huge
    task.spawn(function()
        local attempt = 0
        while active do
            attempt += 1
            pcall(function()
                if attempt % 2 == 1 then
                    -- odd attempts: try the same server first
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
                else
                    -- even attempts: any server of the same game
                    TeleportService:Teleport(game.PlaceId, player)
                end
            end)
            task.wait(15) -- if it didn't work, try again
        end
    end)
end

-- detect the error/disconnect screen
task.spawn(function()
    pcall(function()
        local prompt = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 10)
        local overlay = prompt and prompt:WaitForChild("promptOverlay", 10)
        if overlay then
            table.insert(connections, overlay.ChildAdded:Connect(function(obj)
                if obj.Name == "ErrorPrompt" then
                    task.wait(1)
                    rejoin()
                end
            end))
        end
    end)
end)

pcall(function()
    table.insert(connections, GuiService.ErrorMessageChanged:Connect(function()
        local msg = ""
        pcall(function() msg = GuiService:GetErrorMessage() end)
        if msg ~= "" then
            task.wait(1)
            rejoin()
        end
    end))
end)

-- ===== TAP THE TEXT: PAUSE / RESUME =====
table.insert(connections, btn.MouseButton1Click:Connect(function()
    paused = not paused
    state = paused and "paused" or "on"
    showUntil = os.clock() + CONFIG.HIDE_AFTER
    if not paused then pulse() end
end))

-- ===== UPDATE THE TEXT =====
local function fmt(s)
    s = math.floor(s)
    return string.format("%d:%02d", s // 60, s % 60)
end

task.spawn(function()
    while active do
        if not gui or not gui.Parent then shutdown() break end

        if state == "starting" then
            btn.Text = "afknillo starting..."
            btn.TextColor3 = Color3.fromRGB(255, 220, 80)
        elseif state == "on" then
            btn.Text = "afknillo on • " .. fmt(os.clock() - lastPulse)
            btn.TextColor3 = Color3.fromRGB(80, 255, 120)
        elseif state == "paused" then
            btn.Text = "afknillo paused"
            btn.TextColor3 = Color3.fromRGB(255, 220, 80)
        elseif state == "reconnecting" then
            btn.Text = "afknillo disconnected, reconnecting..."
            btn.TextColor3 = Color3.fromRGB(255, 70, 70)
        else
            btn.Text = "afknillo error"
            btn.TextColor3 = Color3.fromRGB(255, 70, 70)
        end

        -- discreet when everything is fine; visible when it's not
        local highlight = (state ~= "on") or (os.clock() < showUntil)
        btn.TextTransparency = highlight and 0 or 0.6
        btn.TextStrokeTransparency = highlight and 0.5 or 0.85

        task.wait(1)
    end
end)

-- ===== PERIODIC PULSE =====
task.spawn(function()
    pulse() -- initial test
    while active do
        task.wait(CONFIG.INTERVAL)
        pulse()
    end
end)

print("[AFKNILLO] Running.")
]====]

local f, e = loadstring(SRC)
if f then
    f(SRC)
else
    warn("[AFKNILLO] Load error:", e)
end
