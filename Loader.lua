-- ============================================================================
-- 1. IDENTIFICAÇÃO DO DIRETÓRIO DE OVOS DO JOGO
-- ============================================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- O script tenta achar a pasta de ovos automática do jogo. 
-- Jogos como Steal An Egg costumam usar nomes como "EggSpawns", "Eggs" ou "Spawners".
local PastaOvos = Workspace:FindFirstChild("EggSpawns") or Workspace:FindFirstChild("Eggs") or Workspace:FindFirstChild("DroppedEggs")

if not PastaOvos then
    -- Se o jogo salvar os ovos soltos direto no Workspace, usamos o próprio Workspace
    PastaOvos = Workspace
end

-- ============================================================================
-- 2. CRIAÇÃO DA INTERFACE GRÁFICA (UI) DO LINNO HUB SIMPLIFICADO
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LinnoHub_StealAnEgg"
ScreenGui.ResetOnSpawn = false
-- Deleta a interface antiga se você reexecutar o script
if PlayerGui:FindFirstChild("LinnoHub_StealAnEgg") then
    PlayerGui.LinnoHub_StealAnEgg:Destroy()
end
ScreenGui.Parent = PlayerGui

-- Painel Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 330, 0, 380)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Você pode arrastar a janela pela tela
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "🥚 STEAL AN EGG - PET DETECTOR"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- Lista com Scroll
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -20, 1, -60)
ScrollContainer.Position = UDim2.new(0, 10, 0, 55)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollContainer.ScrollBarThickness = 4
ScrollContainer.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ScrollContainer
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end)

-- ============================================================================
-- 3. LÓGICA DE DETECÇÃO, EXTRAÇÃO DE DADOS E TELEPORTE
-- ============================================================================
local function CriarLinhaNaLista(ovo)
    -- Filtro de segurança: Garante que estamos pegando apenas os modelos de OVOS do jogo
    if not (ovo:IsA("Model") or ovo:IsA("BasePart")) then return end
    if not string.find(string.lower(ovo.Name), "egg") and not ovo:FindFirstChild("Egg") then return end

    -- Tenta capturar o preço/status do Ovo direto dos atributos que o jogo salva nele
    local statusValor = ovo:GetAttribute("Multiplier") or ovo:GetAttribute("Cash") or ovo:GetAttribute("Value") or "Base"
    local nomeOvo = ovo.Name:gsub("Egg", ""):gsub("_", " ")

    -- Criando o card do item na lista
    local Card = Instance.new("Frame")
    Card.Name = ovo.Name .. "_Card"
    Card.Size = UDim2.new(1, -4, 0, 65)
    Card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Card.Parent = ScrollContainer

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 6)
    CardCorner.Parent = Card

    -- Miniatura/Foto do Pet ou do Ovo (Usa o Viewport nativo do Roblox para focar no modelo)
    local Viewport = Instance.new("ViewportFrame")
    Viewport.Size = UDim2.new(0, 55, 0, 55)
    Viewport.Position = UDim2.new(0, 5, 0, 5)
    Viewport.BackgroundTransparency = 1
    Viewport.Parent = Card

    -- Clona o modelo do ovo para mostrar a foto dele girando em tempo real na lista
    local OvoClone = ovo:Clone()
    if OvoClone:IsA("Model") then
        OvoClone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
    elseif OvoClone:IsA("BasePart") then
        OvoClone.CFrame = CFrame.new(0, 0, 0)
    end
    OvoClone.Parent = Viewport

    -- Câmera do Viewport para focar no ovo
    local Cam = Instance.new("Camera")
    Cam.CFrame = CFrame.new(Vector3.new(0, 0, 4), Vector3.new(0, 0, 0))
    Viewport.CurrentCamera = Cam
    Cam.Parent = Viewport

    -- Texto: Nome do Ovo/Pet
    local TextNome = Instance.new("TextLabel")
    TextNome.Size = UDim2.new(0, 160, 0, 25)
    TextNome.Position = UDim2.new(0, 68, 0, 8)
    TextNome.BackgroundTransparency = 1
    TextNome.Text = nomeOvo
    TextNome.TextColor3 = Color3.fromRGB(255, 215, 0)
    TextNome.Font = Enum.Font.SourceSansBold
    TextNome.TextSize = 15
    TextNome.TextXAlignment = Enum.TextXAlignment.Left
    TextNome.Parent = Card

    -- Texto: Quanto ele multiplica/Dá
    local TextValor = Instance.new("TextLabel")
    TextValor.Size = UDim2.new(0, 160, 0, 20)
    TextValor.Position = UDim2.new(0, 68, 0, 30)
    TextValor.BackgroundTransparency = 1
    TextValor.Text = "Ganho: +" .. tostring(statusValor)
    TextValor.TextColor3 = Color3.fromRGB(120, 255, 120)
    TextValor.Font = Enum.Font.SourceSans
    TextValor.TextSize = 13
    TextValor.TextXAlignment = Enum.TextXAlignment.Left
    TextValor.Parent = Card

    -- Botão de Teleporte automático até o Ovo
    local TeleportBtn = Instance.new("TextButton")
    TeleportBtn.Size = UDim2.new(0, 65, 0, 45)
    TeleportBtn.Position = UDim2.new(1, -72, 0, 10)
    TeleportBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
    TeleportBtn.Text = "ROUBAR"
    TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TeleportBtn.Font = Enum.Font.SourceSansBold
    TeleportBtn.TextSize = 13
    TeleportBtn.Parent = Card

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = TeleportBtn

    -- Executa o teleporte ao clicar
    TeleportBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local root = char or char:FindFirstChild("HumanoidRootPart")
        
        if root then
            -- Teleporta exatamente em cima do ovo para coletar instantaneamente
            if ovo:IsA("Model") and ovo.PrimaryPart then
                root.HumanoidRootPart.CFrame = ovo.PrimaryPart.CFrame + Vector3.new(0, 2, 0)
            elseif ovo:IsA("BasePart") then
                root.HumanoidRootPart.CFrame = ovo.CFrame + Vector3.new(0, 2, 0)
            end
        end
    end)

    -- Remove o item da lista se alguém roubar o ovo do mapa
    ovo.AncestryChanged:Connect(function()
        if not ovo:IsDescendantOf(game) then
            Card:Destroy()
        end
    end)
end

-- ============================================================================
-- 4. ATIVAÇÃO DO MONITORAMENTO EM TEMPO REAL
-- ============================================================================
-- Monitora novos spawns
PastaOvos.ChildAdded:Connect(function(novoObjeto)
    task.wait(0.2) -- Tempo para o jogo carregar os dados internos do ovo
    CriarLinhaNaLista(novoObjeto)
end)

-- Carrega os ovos que já estão no mapa assim que você injeta o script
for _, objetoAtivo in pairs(PastaOvos:GetChildren()) do
    CriarLinhaNaLista(objetoAtivo)
end
