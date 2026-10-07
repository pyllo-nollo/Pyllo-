--// pyllo hub | DETECTOR DE OVO
--// Clica para Teleportar
--// 0.2s antes | 0.1s na Base

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

--==================================================
-- VARIÁVEIS
--==================================================

local BotAtivo = false
local Teleportando = false
local ovoDetectado = false
local roubando = false

local PALAVRAS_OVO = {
    "egg",
    "ovo"
}

--==================================================
-- DETECTAR OVO
--==================================================

local function NomeTemOvo(nome)
    if not nome then
        return false
    end

    nome = string.lower(tostring(nome))

    for _, palavra in ipairs(PALAVRAS_OVO) do
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

        if obj:IsA("BasePart") then
            local nome = string.lower(obj.Name)

            if string.find(nome, "base", 1, true)
            or string.find(nome, "safe", 1, true)
            or string.find(nome, "lobby", 1, true)
            or string.find(nome, "spawn", 1, true) then

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

    if not BotAtivo then
        return
    end

    local character = Player.Character
    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local base = EncontrarBase()

    if not base then
        warn("pyllo hub: Ponto da Base não encontrado!")
        return
    end

    Teleportando = true

    local posicaoOriginal = root.CFrame

    task.wait(TEMPO_ANTES)

    if not BotAtivo or not root.Parent then
        Teleportando = false
        return
    end

    root.CFrame = base.CFrame + Vector3.new(0, ALTURA_BASE, 0)

    print("pyllo hub: chegou na Base")

    task.wait(TEMPO_NA_BASE)

    if root.Parent then
        root.CFrame = posicaoOriginal
    end

    print("pyllo hub: voltou para posição original")

    Teleportando = false
end

--==================================================
-- DETECTOR
--==================================================

local function DetectarObjeto(obj, motivo)
    if not BotAtivo then
        return
    end

    if not obj then
        return
    end

    if not NomeTemOvo(obj.Name) then
        return
    end

    if ovoDetectado then
        return
    end

    ovoDetectado = true

    print("OVO DETECTADO!")
    print("Motivo:", motivo)
    print("Objeto:", obj:GetFullName())

    task.spawn(TeleportToBase)
end

--==================================================
-- PROXIMITY PROMPT
--==================================================

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, jogador)

    if jogador ~= Player then
        return
    end

    if not BotAtivo then
        return
    end

    if NomeTemOvo(prompt.Name)
    or NomeTemOvo(prompt.ObjectText)
    or NomeTemOvo(prompt.ActionText) then

        roubando = true

        print("ROUBO INICIADO!")

        -- Teleporta sem esperar o ovo aparecer no inventário
        task.spawn(function()

            task.wait(0.05)

            if roubando and BotAtivo and not ovoDetectado then
                ovoDetectado = true

                print("OVO DETECTADO!")
                print("Motivo: ProximityPrompt")

                TeleportToBase()
            end
        end)
    end
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, jogador)

    if jogador ~= Player then
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
            DetectarObjeto(obj, "Character")
        end

        if obj:IsA("Tool") and NomeTemOvo(obj.Name) then
            DetectarObjeto(obj, "Tool")
        end

        if obj:IsA("Weld")
        or obj:IsA("WeldConstraint")
        or obj:IsA("Motor6D") then

            local parte0 = obj.Part0
            local parte1 = obj.Part1

            if parte0 and NomeTemOvo(parte0.Name) then
                DetectarObjeto(parte0, "Weld")
            end

            if parte1 and NomeTemOvo(parte1.Name) then
                DetectarObjeto(parte1, "Weld")
            end
        end
    end)

    character.DescendantRemoving:Connect(function(obj)

        if not NomeTemOvo(obj.Name) then
            return
        end

        print("OVO SAIU DO CHARACTER")

        task.delay(0.05, function()

            local backpack = Player:FindFirstChildOfClass("Backpack")

            if not backpack then
                return
            end

            for _, item in ipairs(backpack:GetChildren()) do

                if item:IsA("Tool")
                and NomeTemOvo(item.Name) then

                    print("OVO CHEGOU AO INVENTÁRIO!")

                    if not ovoDetectado then
                        ovoDetectado = true
                        TeleportToBase()
                    end

                    break
                end
            end
        end)
    end)
end

--==================================================
-- CHARACTER ATUAL
--==================================================

if Player.Character then
    MonitorarCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(character)

    ovoDetectado = false
    roubando = false
    Teleportando = false

    MonitorarCharacter(character)
end)

--==================================================
-- BACKPACK
--==================================================

local function MonitorarBackpack(backpack)

    backpack.ChildAdded:Connect(function(obj)

        if not BotAtivo then
            return
        end

        if obj:IsA("Tool")
        and NomeTemOvo(obj.Name) then

            print("OVO CHEGOU AO INVENTÁRIO!")

            if not ovoDetectado then
                ovoDetectado = true
                TeleportToBase()
            end
        end
    end)
end

local backpack = Player:FindFirstChildOfClass("Backpack")

if backpack then
    MonitorarBackpack(backpack)
end

Player.ChildAdded:Connect(function(obj)

    if obj:IsA("Backpack") then
        MonitorarBackpack(obj)
    end
end)

--==================================================
-- GUI
--==================================================

local PlayerGui = Player:WaitForChild("PlayerGui")

local antiga = PlayerGui:FindFirstChild("pylloHub")

if antiga then
    antiga:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "pylloHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

--==================================================
-- HUB
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 135)
Main.Position = UDim2.new(0.5, -130, 0.5, -67)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 5)
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
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "pyllo hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--==================================================
-- FECHAR
--==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 3)
CloseButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = Color3.fromRGB(255, 105, 180)
CloseStroke.Thickness = 1
CloseStroke.Parent = CloseButton

--==================================================
-- BOTÃO
--==================================================

local BostButton = Instance.new("TextButton")
BostButton.Name = "BotButton"
BostButton.Size = UDim2.new(0, 220, 0, 50)
BostButton.Position = UDim2.new(0.5, -110, 0, 55)
BostButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
BostButton.BorderSizePixel = 0
BostButton.Text = "BOT OFF"
BostButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BostButton.TextSize = 17
BostButton.Font = Enum.Font.GothamBold
BostButton.Parent = Main

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 5)
ButtonCorner.Parent = BostButton

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Color = Color3.fromRGB(255, 105, 180)
ButtonStroke.Thickness = 1.5
ButtonStroke.Parent = BostButton

--==================================================
-- BOLINHA PYLLО
--==================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 65, 0, 65)
OpenButton.Position = UDim2.new(0, 20, 0.5, -32)
OpenButton.BackgroundColor3 = Color3.fromRGB(255, 170, 210)
OpenButton.BorderSizePixel = 0
OpenButton.Text = "pyllo"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 14
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
-- ARRASTAR
--==================================================

local Arrastando = false
local PosicaoInicial
local PosicaoDoMouse

Title.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        Arrastando = true
        PosicaoInicial = Main.Position
        PosicaoDoMouse = input.Position
    end
end)

Title.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        Arrastando = false
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if not Arrastando then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - PosicaoDoMouse

        Main.Position = UDim2.new(
            PosicaoInicial.X.Scale,
            PosicaoInicial.X.Offset + delta.X,
            PosicaoInicial.Y.Scale,
            PosicaoInicial.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- LIGAR / DESLIGAR
--==================================================

BostButton.MouseButton1Click:Connect(function()

    BotAtivo = not BotAtivo

    if BotAtivo then

        BostButton.Text = "BOT ON"

        ovoDetectado = false
        roubando = false

        print("pyllo hub: BOT LIGADO")

    else

        BostButton.Text = "BOT OFF"

        ovoDetectado = false
        roubando = false

        print("pyllo hub: BOT DESLIGADO")
    end
end)

--==================================================
-- FECHAR HUB
--==================================================

CloseButton.MouseButton1Click:Connect(function()

    Main.Visible = false
    OpenButton.Visible = true
end)

--==================================================
-- ABRIR HUB
--==================================================

OpenButton.MouseButton1Click:Connect(function()

    Main.Visible = true
    OpenButton.Visible = false
end)

--==================================================
-- FINAL
--==================================================

print("pyllo hub carregado!")
print("Bot começa DESLIGADO.")
print("Detector de ovo carregado.")
print("Teleporte: 0.2s antes.")
print("Base: 0.1s.")
