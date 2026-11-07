local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local COLOR_FONDO = Color3.fromRGB(20, 24, 38)
local COLOR_AZUL = Color3.fromRGB(85, 170, 255)
local COLOR_DORADO = Color3.fromRGB(255, 200, 40)
local COLOR_TEXTO = Color3.fromRGB(235, 240, 255)
local COLOR_TEXTO_SUAVE = Color3.fromRGB(180, 190, 215)

local function crear(clase, propiedades)
	local objeto = Instance.new(clase)
	for nombre, valor in pairs(propiedades) do
		if nombre ~= "Parent" then
			objeto[nombre] = valor
		end
	end
	objeto.Parent = propiedades.Parent
	return objeto
end

local gui = crear("ScreenGui", {
	Name = "HUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local panel = crear("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.new(0.9, 0, 0, 76),
	BackgroundColor3 = COLOR_FONDO,
	BackgroundTransparency = 0.2,
	Parent = gui,
})
crear("UISizeConstraint", { MaxSize = Vector2.new(420, math.huge), Parent = panel })
crear("UICorner", { CornerRadius = UDim.new(0, 12), Parent = panel })
crear("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.85, Thickness = 1.5, Parent = panel })

crear("TextLabel", {
	Name = "Titulo",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 8),
	Size = UDim2.new(0.5, -14, 0, 22),
	Font = Enum.Font.FredokaOne,
	Text = "PUENTE",
	TextSize = 20,
	TextColor3 = COLOR_TEXTO,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = panel,
})

local contador = crear("TextLabel", {
	Name = "Contador",
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0.5, -14, 0, 22),
	Font = Enum.Font.FredokaOne,
	Text = "0 / 0",
	TextSize = 20,
	TextColor3 = COLOR_TEXTO,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = panel,
})

local barraFondo = crear("Frame", {
	Name = "Barra",
	Position = UDim2.new(0, 14, 0, 36),
	Size = UDim2.new(1, -28, 0, 12),
	BackgroundColor3 = Color3.fromRGB(50, 56, 80),
	Parent = panel,
})
crear("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barraFondo })

local barraRelleno = crear("Frame", {
	Name = "Relleno",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = COLOR_AZUL,
	Parent = barraFondo,
})
crear("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barraRelleno })

local estadoTexto = crear("TextLabel", {
	Name = "Estado",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 52),
	Size = UDim2.new(1, -28, 0, 18),
	Font = Enum.Font.GothamMedium,
	Text = "",
	TextSize = 14,
	TextColor3 = COLOR_TEXTO_SUAVE,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = panel,
})

local aviso = crear("TextLabel", {
	Name = "Aviso",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.new(0.9, 0, 0, 80),
	BackgroundTransparency = 1,
	Font = Enum.Font.FredokaOne,
	Text = "",
	TextSize = 34,
	TextWrapped = true,
	TextColor3 = COLOR_DORADO,
	TextTransparency = 1,
	TextStrokeTransparency = 1,
	Parent = gui,
})
local escalaAviso = crear("UIScale", { Parent = aviso })

local ayuda = crear("TextLabel", {
	Name = "Ayuda",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.new(0.6, 0, 0, 40),
	BackgroundColor3 = COLOR_FONDO,
	BackgroundTransparency = 0.25,
	Font = Enum.Font.GothamBold,
	Text = "",
	TextSize = 16,
	TextWrapped = true,
	TextColor3 = COLOR_TEXTO,
	Parent = gui,
})
crear("UISizeConstraint", { MaxSize = Vector2.new(460, math.huge), Parent = ayuda })
crear("UICorner", { CornerRadius = UDim.new(0, 10), Parent = ayuda })
crear("UIPadding", {
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
	Parent = ayuda,
})

local function leer(nombre, valorPorDefecto)
	local valor = ReplicatedStorage:GetAttribute(nombre)
	if valor == nil then
		return valorPorDefecto
	end
	return valor
end

local function llevaBloque()
	local character = player.Character
	return character ~= nil and character:FindFirstChild("CarriedBlock") ~= nil
end

local function actualizarAyuda()
	local estado = leer("Estado", "Construyendo")

	if estado == "Cruzando" and leer("HayMeta", false) then
		ayuda.Text = "¡Corre por el puente hasta la META!"
	elseif estado ~= "Construyendo" then
		ayuda.Text = "¡Bien hecho! Pronto empieza otra ronda"
	elseif llevaBloque() then
		ayuda.Text = "¡Tienes un bloque! Llévalo al puente para hacerlo crecer"
	else
		ayuda.Text = "Toca un cubito para recogerlo"
	end
end

local function actualizarPanel()
	local estado = leer("Estado", "Construyendo")
	local progreso = leer("Progreso", 0)
	local objetivo = leer("Objetivo", 0)
	local ronda = leer("Ronda", 1)
	local tiempo = leer("TiempoRestante", 0)

	contador.Text = progreso .. " / " .. objetivo

	local fraccion = 0
	if objetivo > 0 then
		fraccion = math.clamp(progreso / objetivo, 0, 1)
	end
	TweenService:Create(barraRelleno, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(fraccion, 1),
	}):Play()

	if estado == "Cruzando" then
		barraRelleno.BackgroundColor3 = COLOR_DORADO
		if leer("HayMeta", false) then
			estadoTexto.Text = "¡Puente listo! Crucen a la meta · " .. tiempo .. "s"
		else
			estadoTexto.Text = "¡Puente listo! Siguiente ronda en " .. tiempo .. "s"
		end
	else
		barraRelleno.BackgroundColor3 = COLOR_AZUL
		estadoTexto.Text = "Ronda " .. ronda .. " · Lleven bloques al puente"
	end

	actualizarAyuda()
end

for _, nombre in ipairs({ "Estado", "Progreso", "Objetivo", "Ronda", "TiempoRestante", "HayMeta" }) do
	ReplicatedStorage:GetAttributeChangedSignal(nombre):Connect(actualizarPanel)
end
actualizarPanel()

local function alAparecer(character)
	character.ChildAdded:Connect(function(hijo)
		if hijo.Name == "CarriedBlock" then
			actualizarAyuda()
		end
	end)
	character.ChildRemoved:Connect(function(hijo)
		if hijo.Name == "CarriedBlock" then
			actualizarAyuda()
		end
	end)
	actualizarAyuda()
end

player.CharacterAdded:Connect(alAparecer)
if player.Character then
	alAparecer(player.Character)
end

local numeroAviso = 0

local function mostrarAviso(texto, color)
	numeroAviso += 1
	local esteAviso = numeroAviso

	aviso.Text = texto
	aviso.TextColor3 = color or COLOR_DORADO
	aviso.TextTransparency = 0
	aviso.TextStrokeTransparency = 0.3
	escalaAviso.Scale = 0.6
	TweenService:Create(escalaAviso, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	task.delay(3, function()
		if esteAviso ~= numeroAviso then
			return -- llegó otro mensaje después, ese se encarga
		end
		TweenService:Create(aviso, TweenInfo.new(0.6), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)
end

task.spawn(function()
	local mensaje = ReplicatedStorage:WaitForChild("Mensaje")
	mensaje.OnClientEvent:Connect(mostrarAviso)
end)

-- Los cubitos giran solo en la pantalla de cada jugador; en el servidor no se mueven.
task.spawn(function()
	local cubitos = workspace:WaitForChild("Cubitos")

	-- Claves débiles: los cubitos borrados no se quedan guardados en memoria
	local posicionOriginal = setmetatable({}, { __mode = "k" })
	local activos = {}

	local function agregar(cubito)
		if cubito:IsA("BasePart") and cubito.Anchored then
			if not posicionOriginal[cubito] then
				posicionOriginal[cubito] = cubito.CFrame
			end
			activos[cubito] = true
		end
	end

	for _, cubito in ipairs(cubitos:GetChildren()) do
		agregar(cubito)
	end
	cubitos.ChildAdded:Connect(agregar)
	cubitos.ChildRemoved:Connect(function(cubito)
		activos[cubito] = nil
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for cubito in pairs(activos) do
			local base = posicionOriginal[cubito]
			if base then
				cubito.CFrame = base * CFrame.new(0, math.sin(t * 2) * 0.4, 0) * CFrame.Angles(0, t * 1.5, 0)
			end
		end
	end)
end)
