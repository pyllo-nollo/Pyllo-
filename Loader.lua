--// pyllo hub | DETECTOR DE OVO
--// Detecta antes de virar Tool/inventário

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Player = Players.LocalPlayer

--==================================================
-- CONFIGURAÇÃO
--==================================================

local TEMPO_ANTES = 0.3
local TEMPO_NA_BASE = 0.1
local ALTURA_BASE = 7

local BotAtivo = false
local Teleportando = false

local ovoDetectado = nil
local roubando = false

local PALAVRAS_OVO = {
    "egg",
    "ovo"
}

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "pylloHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(260, 135)
Main.Position = UDim2.new(0.5, -130, 0.5, -67)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 120, 255)
Stroke.Thickness = 1
Stroke.Parent = Main

--==================================================
-- TOPO
--==================================================

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 34)
Top.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
Top.BorderSizePixel = 0
Top.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = Top

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.fromOffset(9, 0)
Title.BackgroundTransparency = 1
Title.Text = "pyllo hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

--==================================================
-- FECHAR
--==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(25, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 4)
CloseButton.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 11
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Top

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = CloseButton

--==================================================
-- ENCONTRAR BASE
--==================================================

local function FindBaseSpawn()

    local Base = workspace:FindFirstChild("Base", true)

    if Base then

        if Base:IsA("SpawnLocation") then
            return Base
        end

        if Base:IsA("Model") then

            local Spawn = Base:FindFirstChildWhichIsA(
                "SpawnLocation",
                true
            )

            if Spawn then
                return Spawn
            end
        end

        if Base:IsA("BasePart") then
            return Base
        end
    end

    local Spawns = {}

    for _, Obj in ipairs(workspace:GetDescendants()) do

        if Obj:IsA("SpawnLocation") then
            table.insert(Spawns, Obj)
        end
    end

    if #Spawns == 1 then
        return Spawns[1]
    end

    for _, Spawn in ipairs(Spawns) do

        local Nome = string.lower(Spawn.Name)

        if Nome:find("base")
        or Nome:find("spawn")
        or Nome:find("home") then

            return Spawn
        end
    end

    warn("pyllo hub: Ponto da Base não encontrado!")

    return nil
end

--==================================================
-- TELEPORTAR PARA BASE
--==================================================

local function TeleportToBase()

    if not BotAtivo then
        return
    end

    if Teleportando then
        return
    end

    Teleportando = true

    local Point = FindBaseSpawn()

    if not Point then
        Teleportando = false
        return
    end

    local Character = Player.Character

    if not Character then
        Teleportando = false
        return
    end

    local Root = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if not Root or not Humanoid then
        Teleportando = false
        return
    end

    local PosicaoOriginal = Root.CFrame

    task.wait(TEMPO_ANTES)

    if not BotAtivo then
        Teleportando = false
        return
    end

    if not Root.Parent then
        Teleportando = false
        return
    end

    local NovaPosicao =
        Point.CFrame + Vector3.new(0, ALTURA_BASE, 0)

    Humanoid:SetStateEnabled(
        Enum.HumanoidStateType.FallingDown,
        false
    )

    Humanoid:SetStateEnabled(
        Enum.HumanoidStateType.Freefall,
        false
    )

    Humanoid:SetStateEnabled(
        Enum.HumanoidStateType.Ragdoll,
        false
    )

    Humanoid.PlatformStand = true

    Root.CFrame = NovaPosicao
    Root.AssemblyLinearVelocity = Vector3.zero
    Root.AssemblyAngularVelocity = Vector3.zero

    print("pyllo hub: chegou na Base")

    local TempoInicio = tick()

    while tick() - TempoInicio < TEMPO_NA_BASE do

        if not Root or not Root.Parent then
            break
        end

        Root.CFrame = NovaPosicao
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero

        task.wait()
    end

    if Root and Root.Parent then

        Root.CFrame = PosicaoOriginal
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end

    if Humanoid and Humanoid.Parent then

        Humanoid:SetStateEnabled(
            Enum.HumanoidStateType.FallingDown,
            true
        )

        Humanoid:SetStateEnabled(
            Enum.HumanoidStateType.Freefall,
            true
        )

        Humanoid:SetStateEnabled(
            Enum.HumanoidStateType.Ragdoll,
            true
        )

        Humanoid.PlatformStand = false
    end

    Teleportando = false

    print("pyllo hub: voltou para posição original")
end

--==================================================
-- DETECTOR
--==================================================

local function pareceOvo(obj)

    if not obj then
        return false
    end

    local nome = string.lower(obj.Name or "")

    for _, palavra in ipairs(PALAVRAS_OVO) do

        if string.find(nome, palavra, 1, true) then
            return true
        end
    end

    return false
end

--==================================================
-- DETECTAR OVO
--==================================================

local function detectar(obj, motivo)

    if not BotAtivo then
        return
    end

    if not obj then
        return
    end

    if pareceOvo(obj) then

        if ovoDetectado ~= obj then

            ovoDetectado = obj
            roubando = true

            print("🥚 OVO DETECTADO!")
            print("Motivo:", motivo)
            print("Objeto:", obj:GetFullName())

            task.spawn(function()
                TeleportToBase()
            end)
        end
    end
end

--==================================================
-- PROXIMITY PROMPT
--==================================================

ProximityPromptService.PromptTriggered:Connect(function(
    prompt,
    player
)

    if player ~= Player then
        return
    end

    if not BotAtivo then
        return
    end

    local parent = prompt.Parent

    if pareceOvo(prompt) then
        detectar(prompt, "Prompt")
    end

    detectar(parent, "Parent do Prompt")

    local atual = parent

    for i = 1, 6 do

        if not atual then
            break
        end

        detectar(
            atual,
            "Objeto acima do Prompt"
        )

        atual = atual.Parent
    end

    roubando = true

    print("🖐️ ROUBO INICIADO!")
end)

--==================================================
-- PROCURAR NO CHARACTER
--==================================================

local function procurarNoCharacter()

    if not BotAtivo then
        return
    end

    local character = Player.Character

    if not character then
        return
    end

    for _, obj in ipairs(character:GetDescendants()) do

        if pareceOvo(obj) then
            detectar(
                obj,
                "Objeto no Character"
            )
        end

        if obj:IsA("Tool") and pareceOvo(obj) then

            detectar(
                obj,
                "Tool"
            )
        end

        if obj:IsA("Weld")
        or obj:IsA("WeldConstraint")
        or obj:IsA("Motor6D") then

            if obj.Part0 then
                detectar(
                    obj.Part0,
                    "Objeto conectado por Weld"
                )
            end

            if obj.Part1 then
                detectar(
                    obj.Part1,
                    "Objeto conectado por Weld"
                )
            end
        end
    end
end

--==================================================
-- CHARACTER
--==================================================

local function conectarCharacter(character)

    character.DescendantAdded:Connect(function(obj)

        task.wait()

        if not BotAtivo then
            return
        end

        if not obj:IsDescendantOf(character) then
            return
        end

        detectar(
            obj,
            "Objeto adicionado ao Character"
        )

        local atual = obj.Parent

        for i = 1, 5 do

            if not atual then
                break
            end

            detectar(
                atual,
                "Parent de objeto novo"
            )

            atual = atual.Parent
        end
    end)

    character.DescendantRemoving:Connect(function(obj)

        if obj == ovoDetectado then

            print("🥚 OVO SAIU DO CHARACTER")

            ovoDetectado = nil
            roubando = false
        end
    end)
end

if Player.Character then
    conectarCharacter(Player.Character)
end

Player.CharacterAdded:Connect(conectarCharacter)

--==================================================
-- VERIFICAÇÃO CONTÍNUA
--==================================================

task.spawn(function()

    while true do

        if BotAtivo then

            procurarNoCharacter()

            local backpack =
                Player:FindFirstChildOfClass("Backpack")

            if backpack then

                for _, obj in ipairs(
                    backpack:GetChildren()
                ) do

                    if obj:IsA("Tool")
                    and pareceOvo(obj) then

                        detectar(
                            obj,
                            "Tool no Backpack"
                        )

                        print(
                            "🟢 OVO CHEGOU AO INVENTÁRIO!"
                        )
                    end
                end
            end
        end

        task.wait(0.1)
    end
end)

--==================================================
-- BOTÃO LIGAR / DESLIGAR
--==================================================

local BostButton = Instance.new("TextButton")

BostButton.Size = UDim2.new(1, -16, 0, 38)
BostButton.Position = UDim2.fromOffset(8, 47)
BostButton.BackgroundColor3 =
    Color3.fromRGB(0, 100, 210)

BostButton.BorderSizePixel = 0
BostButton.Text = "☑️ PARA BOTS"
BostButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

BostButton.TextSize = 13
BostButton.Font = Enum.Font.GothamBold
BostButton.Parent = Main

local BostCorner = Instance.new("UICorner")
BostCorner.CornerRadius = UDim.new(0, 8)
BostCorner.Parent = BostButton

BostButton.MouseButton1Click:Connect(function()

    BotAtivo = not BotAtivo

    if BotAtivo then

        BostButton.Text = "☑️ PARA BOTS"

        BostButton.BackgroundColor3 =
            Color3.fromRGB(0, 100, 210)

        print("pyllo hub: BOT LIGADO")

    else

        BostButton.Text = "⛔ BOT DESLIGADO"

        BostButton.BackgroundColor3 =
            Color3.fromRGB(70, 70, 80)

        ovoDetectado = nil
        roubando = false

        print("pyllo hub: BOT DESLIGADO")
    end
end)

--==================================================
-- BOLINHA ☆
--==================================================

local OpenButton = Instance.new("TextButton")

OpenButton.Name = "Reabrir"
OpenButton.Size = UDim2.fromOffset(52, 52)
OpenButton.Position = UDim2.fromOffset(15, 180)

OpenButton.BackgroundColor3 =
    Color3.fromRGB(10, 10, 18)

OpenButton.BorderSizePixel = 0

OpenButton.Text = "☆"
OpenButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

OpenButton.TextSize = 28
OpenButton.Font = Enum.Font.GothamBold

OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(0, 120, 255)
OpenStroke.Thickness = 1
OpenStroke.Parent = OpenButton

--==================================================
-- FECHAR / REABRIR
--==================================================

CloseButton.MouseButton1Click:Connect(function()

    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()

    Main.Visible = true
    OpenButton.Visible = false
end)

--==================================================
-- ARRASTAR
--==================================================

local Dragging = false
local DragStart
local StartPos

Top.InputBegan:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1
    or Input.UserInputType ==
        Enum.UserInputType.Touch then

        Dragging = true
        DragStart = Input.Position
        StartPos = Main.Position

        Input.Changed:Connect(function()

            if Input.UserInputState ==
                Enum.UserInputState.End then

                Dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if not Dragging then
        return
    end

    if Input.UserInputType ==
        Enum.UserInputType.MouseMovement
    or Input.UserInputType ==
        Enum.UserInputType.Touch then

        local Delta =
            Input.Position - DragStart

        Main.Position = UDim2.new(
            StartPos.X.Scale,
            StartPos.X.Offset + Delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + Delta.Y
        )
    end
end)

--==================================================
-- INÍCIO
--==================================================

print("pyllo hub carregado!")
print("Bot começa DESLIGADO.")
print("Clique em ☑️ PARA BOTS para ligar.")
print("Detector de ovo carregado.")
print("Teleporte: 0.3s antes.")
print("Base: 0.1s.")



