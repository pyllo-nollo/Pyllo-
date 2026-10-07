--// pyllo hub | DETECTOR DE OVO
--// Detecta antes de virar Tool/inventário

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Player = Players.LocalPlayer

--==================================================
-- CONFIGURAÇÃO
--==================================================

local TEMPO_ANTES = 0.2
local TEMPO_NA_BASE = 0.1
local ALTURA_BASE = 7

local BotAtivo = false
local Teleportando = false
local ovoDetectado = false
local roubando = false

--==================================================
-- DETECTOR
--==================================================

local palavrasOvo = {
    "egg",
    "ovo"
}

local function NomeTemOvo(nome)
    if not nome then
        return false
    end

    nome = string.lower(tostring(nome))

    for _, palavra in ipairs(palavrasOvo) do
        if string.find(nome, palavra, 1, true) then
            return true
        end
    end

    return false
end

--==================================================
-- ENCONTRAR BASE
--==================================================

local function EncontrarBase()
    local character = Player.Character

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            return obj
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nome = string.lower(obj.Name)

            if (
                string.find(nome, "base", 1, true)
                or string.find(nome, "safe", 1, true)
                or string.find(nome, "lobby", 1, true)
                or string.find(nome, "spawn", 1, true)
            ) then
                if not character or not obj:IsDescendantOf(character) then
                    return obj
                end
            end
        end
    end

    return nil
end

--==================================================
-- TELEPORTE
--==================================================

local function TeleportToBase()
    if Teleportando then
        return
    end

    local character = Player.Character
    if not character then
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local base = EncontrarBase()
    if not base then
        return
    end

    Teleportando = true

    local posicaoOriginal = hrp.CFrame

    task.wait(TEMPO_ANTES)

    if not BotAtivo then
        Teleportando = false
        return
    end

    hrp.CFrame = base.CFrame + Vector3.new(0, ALTURA_BASE, 0)

    task.wait(TEMPO_NA_BASE)

    if hrp and hrp.Parent then
        hrp.CFrame = posicaoOriginal
    end

    Teleportando = false
end

--==================================================
-- DETECTAR OBJETO
--==================================================

local function DetectarObjeto(obj)
    if not BotAtivo then
        return
    end

    if ovoDetectado then
        return
    end

    if not obj then
        return
    end

    if NomeTemOvo(obj.Name) then
        ovoDetectado = true

        task.spawn(function()
            TeleportToBase()

            task.wait(0.2)
            ovoDetectado = false
        end)
    end
end

--==================================================
-- PROXIMITY PROMPT
--==================================================

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if player and player ~= Player then
        return
    end

    if not BotAtivo then
        return
    end

    local nomePrompt = prompt.Name or ""
    local objeto = prompt.Parent
    local nomeObjeto = objeto and objeto.Name or ""
    local textoAcao = prompt.ActionText or ""

    if NomeTemOvo(nomePrompt)
        or NomeTemOvo(nomeObjeto)
        or NomeTemOvo(textoAcao) then

        roubando = true

        print("ROUBO INICIADO!")

        task.wait(0.05)

        if roubando and BotAtivo and not ovoDetectado then
            ovoDetectado = true

            task.spawn(function()
                TeleportToBase()

                task.wait(0.2)
                ovoDetectado = false
            end)
        end
    end
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
    if player and player ~= Player then
        return
    end

    roubando = false
end)

--==================================================
-- MONITORAR CHARACTER
--==================================================

local function MonitorarCharacter(character)
    character.DescendantAdded:Connect(function(obj)
        if not BotAtivo then
            return
        end

        if NomeTemOvo(obj.Name) then
            DetectarObjeto(obj)
        end

        if obj:IsA("Tool") then
            if NomeTemOvo(obj.Name) then
                DetectarObjeto(obj)
            end
        end

        if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
            local parent = obj.Parent

            if parent and NomeTemOvo(parent.Name) then
                DetectarObjeto(parent)
            end
        end
    end)
end

if Player.Character then
    MonitorarCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(character)
    MonitorarCharacter(character)
end)

--==================================================
-- MONITORAR BACKPACK
--==================================================

local Backpack = Player:WaitForChild("Backpack")

Backpack.ChildAdded:Connect(function(obj)
    if not BotAtivo then
        return
    end

    if NomeTemOvo(obj.Name) then
        DetectarObjeto(obj)
    end
end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "pylloHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

--==================================================
-- PAINEL PRINCIPAL
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 135)
Main.Position = UDim2.new(0.5, -130, 0.5, -67)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 4)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 105, 180)
MainStroke.Thickness = 2
MainStroke.Parent = Main

--==================================================
-- TÍTULO
--==================================================

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 0, 35)
Title.Position = UDim2.new(0, 12, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "pyllo hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--==================================================
-- BOTÃO X
--==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -38, 0, 7)
CloseButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = Color3.fromRGB(255, 105, 180)
CloseStroke.Thickness = 1.5
CloseStroke.Parent = CloseButton

--==================================================
-- BOTÃO DO BOT
--==================================================

local BostButton = Instance.new("TextButton")
BostButton.Name = "BotButton"
BostButton.Size = UDim2.new(0, 220, 0, 50)
BostButton.Position = UDim2.new(0.5, -110, 0, 60)
BostButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
BostButton.BorderSizePixel = 0
BostButton.Text = "BOT OFF"
BostButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BostButton.TextSize = 18
BostButton.Font = Enum.Font.GothamBold
BostButton.Parent = Main

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 4)
ButtonCorner.Parent = BostButton

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Color = Color3.fromRGB(255, 105, 180)
ButtonStroke.Thickness = 1.5
ButtonStroke.Parent = BostButton

--==================================================
-- BOTÃO FLUTUANTE
--==================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 65, 0, 65)
OpenButton.Position = UDim2.new(0, 15, 0.5, -32)
OpenButton.BackgroundColor3 = Color3.fromRGB(255, 182, 220)
OpenButton.BorderSizePixel = 0
OpenButton.Text = "pyllo"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 17
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(255, 105, 180)
OpenStroke.Thickness = 2
OpenStroke.Parent = OpenButton

--==================================================
-- BOTÃO BOT
--==================================================

BostButton.MouseButton1Click:Connect(function()
    BotAtivo = not BotAtivo

    if BotAtivo then
        BostButton.Text = "BOT ON"
    else
        BostButton.Text = "BOT OFF"
        roubando = false
        ovoDetectado = false
    end
end)

--==================================================
-- FECHAR
--==================================================

CloseButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

--==================================================
-- ABRIR
--==================================================

OpenButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
end)

--==================================================
-- ARRASTAR PAINEL
--==================================================

local arrastando = false
local inicioMouse
local inicioPosicao

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        arrastando = true
        inicioMouse = input.Position
        inicioPosicao = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                arrastando = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not arrastando then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - inicioMouse

        Main.Position = UDim2.new(
            inicioPosicao.X.Scale,
            inicioPosicao.X.Offset + delta.X,
            inicioPosicao.Y.Scale,
            inicioPosicao.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- FINAL
--==================================================

print("pyllo hub carregado!")
print("Bot começa DESLIGADO.")
print("Detector de ovo carregado.")
print("Teleporte: 0.2s antes.")
print("Base: 0.1s.")
