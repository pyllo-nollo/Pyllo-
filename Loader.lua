--// pyllo hub | DETECTOR DE OVO + FARM

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

local ovoDetectado = nil
local roubando = false

local FarmAtivo = false
local MelhoresOvos = {}
local OvoPrioritario = nil

local PALAVRAS_OVO = {
    "egg",
    "ovo"
}

local PALAVRAS_IGNORAR = {
    "eggbutton",
    "eggbutton",
    "eggui",
}

local COR_ROSA = Color3.fromRGB(255, 105, 180)
local ROSA_CLARO = Color3.fromRGB(255, 182, 220)
local FUNDO = Color3.fromRGB(15, 18, 25)
local FUNDO_BOTAO = Color3.fromRGB(35, 40, 52)

--==================================================
-- GUI PRINCIPAL
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "pylloHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(270, 185)
Main.Position = UDim2.new(0.5, -135, 0.5, -92)
Main.BackgroundColor3 = FUNDO
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 4)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = COR_ROSA
Stroke.Thickness = 1.5
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
TopCorner.CornerRadius = UDim.new(0, 4)
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
-- BOTÃO FECHAR
--==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(25, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 4)
CloseButton.BackgroundColor3 = FUNDO_BOTAO
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextSize = 11
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Top

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = COR_ROSA
CloseStroke.Thickness = 1
CloseStroke.Parent = CloseButton

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
-- IDENTIFICAR OVOS
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
-- LER VALORES E ATRIBUTOS
--==================================================

local function obterValor(obj, nomes)

    if not obj then
        return nil
    end

    for _, nome in ipairs(nomes) do

        local atributo = obj:GetAttribute(nome)

        if atributo ~= nil then
            return atributo
        end

        local filho = obj:FindFirstChild(nome, true)

        if filho and (
            filho:IsA("StringValue")
            or filho:IsA("NumberValue")
            or filho:IsA("IntValue")
            or filho:IsA("ValueBase")
        ) then

            local sucesso, valor = pcall(function()
                return filho.Value
            end)

            if sucesso and valor ~= nil then
                return valor
            end
        end
    end

    return nil
end

--==================================================
-- CONVERTER INCOME
--==================================================

local function converterIncome(valor)

    if typeof(valor) == "number" then
        return valor
    end

    if valor == nil then
        return 0
    end

    local texto = tostring(valor)
        :gsub(",", "")
        :gsub("%s+", "")
        :upper()

    local numero, sufixo = texto:match(
        "^([%d%.]+)([KMBT]?)$"
    )

    numero = tonumber(numero)

    if not numero then
        return 0
    end

    local multiplicadores = {
        K = 1000,
        M = 1000000,
        B = 1000000000,
        T = 1000000000000
    }

    return numero * (multiplicadores[sufixo] or 1)
end

--==================================================
-- EXTRAIR INFORMAÇÕES DO OVO
--==================================================

local function escanearOvoOficial(ovo)

    local nomePet = obterValor(ovo, {
        "PetName",
        "Pet",
        "Pet_Name",
        "DisplayName",
        "CreatureName"
    }) or ovo.Name

    local raridade = obterValor(ovo, {
        "Rarity",
        "Raridade",
        "PetRarity",
        "Tier"
    }) or "Desconhecida"

    local income = obterValor(ovo, {
        "Income",
        "Multiplier",
        "MoneyPerSecond",
        "CashPerSecond",
        "Earnings",
        "Rate",
        "Value"
    }) or 0

    local incomeNumero = converterIncome(income)

    return {
        Instancia = ovo,
        Pet = tostring(nomePet),
        Raridade = tostring(raridade),
        Income = incomeNumero,
        Nome = ovo.Name
    }
end

--==================================================
-- INTERFACE FARM
--==================================================

local FarmPanel = Instance.new("Frame")
FarmPanel.Name = "FarmPanel"
FarmPanel.Size = UDim2.fromOffset(280, 290)
FarmPanel.Position = UDim2.new(0.5, 145, 0.5, -145)
FarmPanel.BackgroundColor3 = FUNDO
FarmPanel.BorderSizePixel = 0
FarmPanel.Visible = false
FarmPanel.Parent = ScreenGui

local FarmCorner = Instance.new("UICorner")
FarmCorner.CornerRadius = UDim.new(0, 4)
FarmCorner.Parent = FarmPanel

local FarmStroke = Instance.new("UIStroke")
FarmStroke.Color = COR_ROSA
FarmStroke.Thickness = 1.5
FarmStroke.Parent = FarmPanel

local FarmTitle = Instance.new("TextLabel")
FarmTitle.Size = UDim2.new(1, -16, 0, 32)
FarmTitle.Position = UDim2.fromOffset(8, 4)
FarmTitle.BackgroundTransparency = 1
FarmTitle.Text = "FARM - MELHORES OVOS"
FarmTitle.TextColor3 = Color3.new(1, 1, 1)
FarmTitle.TextSize = 13
FarmTitle.Font = Enum.Font.GothamBold
FarmTitle.Parent = FarmPanel

local FarmStatus = Instance.new("TextLabel")
FarmStatus.Size = UDim2.new(1, -16, 0, 22)
FarmStatus.Position = UDim2.fromOffset(8, 35)
FarmStatus.BackgroundTransparency = 1
FarmStatus.Text = "Farm: OFF"
FarmStatus.TextColor3 = ROSA_CLARO
FarmStatus.TextSize = 12
FarmStatus.Font = Enum.Font.Gotham
FarmStatus.Parent = FarmPanel

local FarmToggle = Instance.new("TextButton")
FarmToggle.Size = UDim2.new(1, -16, 0, 32)
FarmToggle.Position = UDim2.fromOffset(8, 60)
FarmToggle.BackgroundColor3 = FUNDO_BOTAO
FarmToggle.BorderSizePixel = 0
FarmToggle.Text = "FARM OFF"
FarmToggle.TextColor3 = Color3.new(1, 1, 1)
FarmToggle.TextSize = 12
FarmToggle.Font = Enum.Font.GothamBold
FarmToggle.Parent = FarmPanel

local FarmToggleCorner = Instance.new("UICorner")
FarmToggleCorner.CornerRadius = UDim.new(0, 4)
FarmToggleCorner.Parent = FarmToggle

local FarmToggleStroke = Instance.new("UIStroke")
FarmToggleStroke.Color = COR_ROSA
FarmToggleStroke.Thickness = 1
FarmToggleStroke.Parent = FarmToggle

local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, -16, 0, 22)
ListTitle.Position = UDim2.fromOffset(8, 97)
ListTitle.BackgroundTransparency = 1
ListTitle.Text = "OVOS ENCONTRADOS"
ListTitle.TextColor3 = Color3.new(1, 1, 1)
ListTitle.TextSize = 11
ListTitle.Font = Enum.Font.GothamBold
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.Parent = FarmPanel

local EggList = Instance.new("ScrollingFrame")
EggList.Name = "EggList"
EggList.Size = UDim2.new(1, -16, 1, -126)
EggList.Position = UDim2.fromOffset(8, 120)
EggList.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
EggList.BorderSizePixel = 0
EggList.ScrollBarThickness = 4
EggList.CanvasSize = UDim2.new(0, 0, 0, 0)
EggList.Parent = FarmPanel

local EggListCorner = Instance.new("UICorner")
EggListCorner.CornerRadius = UDim.new(0, 4)
EggListCorner.Parent = EggList

local EggListLayout = Instance.new("UIListLayout")
EggListLayout.Padding = UDim.new(0, 4)
EggListLayout.SortOrder = Enum.SortOrder.LayoutOrder
EggListLayout.Parent = EggList

local EggListPadding = Instance.new("UIPadding")
EggListPadding.PaddingTop = UDim.new(0, 5)
EggListPadding.PaddingBottom = UDim.new(0, 5)
EggListPadding.PaddingLeft = UDim.new(0, 5)
EggListPadding.PaddingRight = UDim.new(0, 5)
EggListPadding.Parent = EggList

--==================================================
-- ATUALIZAR LISTA VISUAL
--==================================================

local function limparListaVisual()

    for _, filho in ipairs(EggList:GetChildren()) do

        if filho:IsA("TextLabel") then
            filho:Destroy()
        end
    end
end

local function atualizarListaVisual()

    limparListaVisual()

    if #MelhoresOvos == 0 then

        local vazio = Instance.new("TextLabel")
        vazio.Size = UDim2.new(1, -4, 0, 40)
        vazio.BackgroundTransparency = 1
        vazio.Text = "Nenhum ovo encontrado"
        vazio.TextColor3 = Color3.fromRGB(190, 190, 190)
        vazio.TextSize = 11
        vazio.Font = Enum.Font.Gotham
        vazio.Parent = EggList

        EggList.CanvasSize = UDim2.new(0, 0, 0, 45)

        FarmStatus.Text = FarmAtivo
            and "Farm: ON | Procurando..."
            or "Farm: OFF"

        return
    end

    for indice, dados in ipairs(MelhoresOvos) do

        local linha = Instance.new("TextLabel")
        linha.Name = "Ovo_" .. indice
        linha.Size = UDim2.new(1, -4, 0, 48)
        linha.BackgroundColor3 = indice == 1
            and Color3.fromRGB(65, 30, 50)
            or Color3.fromRGB(25, 28, 36)

        linha.BorderSizePixel = 0
        linha.TextXAlignment = Enum.TextXAlignment.Left
        linha.TextYAlignment = Enum.TextYAlignment.Center
        linha.TextWrapped = true

        local incomeTexto = tostring(dados.Income)

        if dados.Income >= 1000000000 then
            incomeTexto = string.format(
                "%.2fB",
                dados.Income / 1000000000
            )
        elseif dados.Income >= 1000000 then
            incomeTexto = string.format(
                "%.2fM",
                dados.Income / 1000000
            )
        elseif dados.Income >= 1000 then
            incomeTexto = string.format(
                "%.2fK",
                dados.Income / 1000
            )
        end

        local prefixo = indice == 1
            and "[MELHOR] "
            or "[" .. indice .. "] "

        linha.Text = prefixo
            .. dados.Pet
            .. "\n"
            .. dados.Raridade
            .. " | Income: "
            .. incomeTexto

        linha.TextColor3 = Color3.new(1, 1, 1)
        linha.TextSize = 10
        linha.Font = Enum.Font.Gotham
        linha.LayoutOrder = indice
        linha.Parent = EggList

        local canto = Instance.new("UICorner")
        canto.CornerRadius = UDim.new(0, 3)
        canto.Parent = linha
    end

    EggList.CanvasSize = UDim2.new(
        0,
        0,
        0,
        EggListLayout.AbsoluteContentSize.Y + 12
    )

    if OvoPrioritario then
        FarmStatus.Text = "Melhor: " .. OvoPrioritario.Pet
    else
        FarmStatus.Text = "Farm: OFF"
    end
end

--==================================================
-- PROCURAR OVOS POR VÁRIOS MÉTODOS
--==================================================

local function adicionarCandidato(lista, vistos, obj)

    if not obj or not obj.Parent then
        return
    end

    if obj == Player.Character then
        return
    end

    if Player.Character and obj:IsDescendantOf(Player.Character) then
        return
    end

    if not (
        obj:IsA("Model")
        or obj:IsA("Tool")
        or obj:IsA("BasePart")
    ) then
        return
    end

    if not pareceOvo(obj) then
        return
    end

    if vistos[obj] then
        return
    end

    vistos[obj] = true

    local dados = escanearOvoOficial(obj)

    table.insert(lista, dados)
end

local function recarregarListaDoMapa()

    local listaTemporaria = {}
    local vistos = {}

    -- MÉTODO 1: PASTAS CONHECIDAS

    local nomesPastas = {
        "DroppedEggs",
        "Eggs",
        "Dropped_Eggs",
        "EggFolder",
        "EggModels",
        "Pets",
        "DroppedItems"
    }

    for _, nomePasta in ipairs(nomesPastas) do

        local pasta = workspace:FindFirstChild(nomePasta, true)

        if pasta then

            for _, obj in ipairs(pasta:GetDescendants()) do
                adicionarCandidato(listaTemporaria, vistos, obj)
            end

            adicionarCandidato(listaTemporaria, vistos, pasta)
        end
    end

    -- MÉTODO 2: VARREDURA GERAL DO MAPA

    for _, obj in ipairs(workspace:GetDescendants()) do
        adicionarCandidato(listaTemporaria, vistos, obj)
    end

    -- MÉTODO 3: ATRIBUTOS QUE IDENTIFICAM UM PET

    for _, obj in ipairs(workspace:GetDescendants()) do

        if obj:IsA("Model") or obj:IsA("Tool") then

            local pet = obterValor(obj, {
                "PetName",
                "Pet",
                "Pet_Name",
                "DisplayName",
                "CreatureName"
            })

            local income = obterValor(obj, {
                "Income",
                "Multiplier",
                "MoneyPerSecond",
                "CashPerSecond",
                "Earnings",
                "Rate"
            })

            if pet ~= nil or income ~= nil then
                adicionarCandidato(listaTemporaria, vistos, obj)
            end
        end
    end

    -- MÉTODO 4: EVITAR REPETIR OVOS COM A MESMA INSTÂNCIA

    local listaFinal = {}
    local instanciasIncluidas = {}

    for _, dados in ipairs(listaTemporaria) do

        if not instanciasIncluidas[dados.Instancia] then

            instanciasIncluidas[dados.Instancia] = true

            table.insert(listaFinal, dados)
        end
    end

    -- MAIOR INCOME PRIMEIRO

    table.sort(listaFinal, function(a, b)

        if a.Income == b.Income then
            return a.Pet:lower() < b.Pet:lower()
        end

        return a.Income > b.Income
    end)

    MelhoresOvos = listaFinal
    OvoPrioritario = MelhoresOvos[1]

    _G.MelhoresOvosAtivos = MelhoresOvos

    atualizarListaVisual()
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

            print("OVO DETECTADO!")
            print("Motivo:", motivo)
            print("Objeto:", obj:GetFullName())

            task.spawn(function()
                TeleportToBase()
            end)
        end
    end
end

--==================================================
-- BOTÃO FARM
--==================================================

FarmToggle.MouseButton1Click:Connect(function()

    FarmAtivo = not FarmAtivo

    if FarmAtivo then

        FarmToggle.Text = "FARM ON"
        FarmToggle.BackgroundColor3 = Color3.fromRGB(90, 35, 65)

        print("pyllo hub: FARM ATIVADO")

        recarregarListaDoMapa()

    else

        FarmToggle.Text = "FARM OFF"
        FarmToggle.BackgroundColor3 = FUNDO_BOTAO

        print("pyllo hub: FARM DESATIVADO")
    end
end)

--==================================================
-- BOTÃO CATEGORIA FARM
--==================================================

local FarmCategoryButton = Instance.new("TextButton")
FarmCategoryButton.Name = "FarmCategoryButton"
FarmCategoryButton.Size = UDim2.new(1, -16, 0, 38)
FarmCategoryButton.Position = UDim2.fromOffset(8, 91)
FarmCategoryButton.BackgroundColor3 = FUNDO_BOTAO
FarmCategoryButton.BorderSizePixel = 0
FarmCategoryButton.Text = "FARM"
FarmCategoryButton.TextColor3 = Color3.new(1, 1, 1)
FarmCategoryButton.TextSize = 13
FarmCategoryButton.Font = Enum.Font.GothamBold
FarmCategoryButton.Parent = Main

local FarmCategoryCorner = Instance.new("UICorner")
FarmCategoryCorner.CornerRadius = UDim.new(0, 4)
FarmCategoryCorner.Parent = FarmCategoryButton

local FarmCategoryStroke = Instance.new("UIStroke")
FarmCategoryStroke.Color = COR_ROSA
FarmCategoryStroke.Thickness = 1
FarmCategoryStroke.Parent = FarmCategoryButton

FarmCategoryButton.MouseButton1Click:Connect(function()

    FarmPanel.Visible = not FarmPanel.Visible

    if FarmPanel.Visible then
        recarregarListaDoMapa()
    end
end)

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

    print("ROUBO INICIADO!")
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
            detectar(obj, "Objeto no Character")
        end

        if obj:IsA("Tool") and pareceOvo(obj) then
            detectar(obj, "Tool")
        end

        if obj:IsA("Weld")
        or obj:IsA("WeldConstraint")
        or obj:IsA("Motor6D") then

            if obj.Part0 then
                detectar(obj.Part0, "Objeto conectado por Weld")
            end

            if obj.Part1 then
                detectar(obj.Part1, "Objeto conectado por Weld")
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

        detectar(obj, "Objeto adicionado ao Character")

        local atual = obj.Parent

        for i = 1, 5 do

            if not atual then
                break
            end

            detectar(atual, "Parent de objeto novo")

            atual = atual.Parent
        end
    end)

    character.DescendantRemoving:Connect(function(obj)

        if obj == ovoDetectado then

            print("OVO SAIU DO CHARACTER")

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
-- ATUALIZAÇÃO AUTOMÁTICA DO FARM
--==================================================

task.spawn(function()

    while true do

        if FarmAtivo then
            recarregarListaDoMapa()
        end

        task.wait(1)
    end
end)

--==================================================
-- VERIFICAÇÃO CONTÍNUA DO DETECTOR ORIGINAL
--==================================================

task.spawn(function()

    while true do

        if BotAtivo then

            procurarNoCharacter()

            local backpack =
                Player:FindFirstChildOfClass("Backpack")

            if backpack then

                for _, obj in ipairs(backpack:GetChildren()) do

                    if obj:IsA("Tool") and pareceOvo(obj) then

                        detectar(obj, "Tool no Backpack")

                        print("OVO CHEGOU AO INVENTÁRIO!")
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
BostButton.BackgroundColor3 = Color3.fromRGB(0, 100, 210)
BostButton.BorderSizePixel = 0
BostButton.Text = "PARA BOTS"
BostButton.TextColor3 = Color3.new(1, 1, 1)
BostButton.TextSize = 13
BostButton.Font = Enum.Font.GothamBold
BostButton.Parent = Main

local BostCorner = Instance.new("UICorner")
BostCorner.CornerRadius = UDim.new(0, 4)
BostCorner.Parent = BostButton

local BostStroke = Instance.new("UIStroke")
BostStroke.Color = COR_ROSA
BostStroke.Thickness = 1
BostStroke.Parent = BostButton

BostButton.MouseButton1Click:Connect(function()

    BotAtivo = not BotAtivo

    if BotAtivo then

        BostButton.Text = "PARA BOTS"
        BostButton.BackgroundColor3 = Color3.fromRGB(0, 100, 210)

        print("pyllo hub: BOT LIGADO")

    else

        BostButton.Text = "BOT DESLIGADO"
        BostButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)

        ovoDetectado = nil
        roubando = false

        print("pyllo hub: BOT DESLIGADO")
    end
end)

--==================================================
-- BOLINHA ROSA-CLARO
--==================================================

local OpenButton = Instance.new("TextButton")

OpenButton.Name = "Reabrir"
OpenButton.Size = UDim2.fromOffset(52, 52)
OpenButton.Position = UDim2.fromOffset(15, 180)
OpenButton.BackgroundColor3 = ROSA_CLARO
OpenButton.BorderSizePixel = 0
OpenButton.Text = "pyllo"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 16
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = COR_ROSA
OpenStroke.Thickness = 1.5
OpenStroke.Parent = OpenButton

--==================================================
-- FECHAR / REABRIR
--==================================================

CloseButton.MouseButton1Click:Connect(function()

    Main.Visible = false
    FarmPanel.Visible = false
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

    if Input.UserInputType == Enum.UserInputType.MouseButton1
    or Input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = Input.Position
        StartPos = Main.Position

        Input.Changed:Connect(function()

            if Input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if not Dragging then
        return
    end

    if Input.UserInputType == Enum.UserInputType.MouseMovement
    or Input.UserInputType == Enum.UserInputType.Touch then

        local Delta = Input.Position - DragStart

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

_G.MelhoresOvosAtivos = {}

print("pyllo hub carregado!")
print("Bot começa DESLIGADO.")
print("Detector de ovo carregado.")
print("Categoria FARM carregada.")
print("Lista ordenada por Income quando disponível.")
print("Teleporte: 0.2s antes.")
print("Base: 0.1s.")
