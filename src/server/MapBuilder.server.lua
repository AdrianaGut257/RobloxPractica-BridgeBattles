-- Crea un mapa de ejemplo SOLO si en Workspace no existen "Cubitos" ni "GrowingBlocks".
-- Si ya hiciste tu propio mapa en Studio, este script no hace nada.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local tieneCubitos = workspace:FindFirstChild("Cubitos") ~= nil
local tienePuente = workspace:FindFirstChild("GrowingBlocks") ~= nil

if tieneCubitos and tienePuente then
	return
end

if tieneCubitos or tienePuente then
	warn("[MapBuilder] Workspace tiene solo una de las carpetas 'Cubitos' / 'GrowingBlocks'. "
		.. "El juego necesita las dos.")
	return
end

local ALTO = 20 -- altura de las islas
local TAM = 2 -- tamaño de cada bloque del puente
local COLUMNAS = Config.MAPA_COLUMNAS
local BORDE_INICIO = 18 -- X donde termina la isla de inicio
local FIN_PUENTE = BORDE_INICIO + TAM + Config.LARGO_PUENTE * TAM -- X donde empieza la isla de la meta

local function crearParte(propiedades)
	local parte = Instance.new("Part")
	parte.Anchored = true
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	for nombre, valor in pairs(propiedades) do
		if nombre ~= "Parent" then
			parte[nombre] = valor
		end
	end
	parte.Parent = propiedades.Parent
	return parte
end

local function crearCartel(adornee, texto, color)
	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.new(0, 240, 0, 70)
	cartel.StudsOffset = Vector3.new(0, 6, 0)
	cartel.MaxDistance = 200
	cartel.Parent = adornee

	local etiqueta = Instance.new("TextLabel")
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.BackgroundTransparency = 1
	etiqueta.Font = Enum.Font.FredokaOne
	etiqueta.TextScaled = true
	etiqueta.Text = texto
	etiqueta.TextColor3 = color
	etiqueta.TextStrokeTransparency = 0.2
	etiqueta.Parent = cartel
end

local function crearIsla(nombre, xMin, xMax, padre)
	local ancho = xMax - xMin
	local centroX = (xMin + xMax) / 2

	local isla = Instance.new("Model")
	isla.Name = nombre

	crearParte({
		Name = "Tierra",
		Size = Vector3.new(ancho, ALTO - 1, 40),
		Position = Vector3.new(centroX, (ALTO - 1) / 2, 0),
		Color = Color3.fromRGB(120, 85, 55),
		Material = Enum.Material.Ground,
		Parent = isla,
	})
	crearParte({
		Name = "Pasto",
		Size = Vector3.new(ancho, 1, 40),
		Position = Vector3.new(centroX, ALTO - 0.5, 0),
		Color = Color3.fromRGB(85, 165, 75),
		Material = Enum.Material.Grass,
		Parent = isla,
	})

	isla.Parent = padre
	return isla
end

local mapa = Instance.new("Folder")
mapa.Name = "MapaEjemplo"

crearIsla("IslaInicio", -20, BORDE_INICIO, mapa)
crearIsla("IslaMeta", FIN_PUENTE, FIN_PUENTE + 30, mapa)

local lava = crearParte({
	Name = "Lava",
	Size = Vector3.new(512, 1, 512),
	Position = Vector3.new(0, 0.5, 0),
	Color = Color3.fromRGB(255, 90, 20),
	Material = Enum.Material.CrackedLava,
	Parent = mapa,
})
lava.Touched:Connect(function(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end)

local metaX = FIN_PUENTE + 18
crearParte({
	Name = Config.NOMBRE_META,
	Size = Vector3.new(10, 0.4, 10),
	Position = Vector3.new(metaX, ALTO + 0.2, 0),
	Color = Color3.fromRGB(160, 160, 170),
	Material = Enum.Material.SmoothPlastic,
	Parent = mapa,
})
local poste = crearParte({
	Name = "Poste",
	Size = Vector3.new(0.6, 12, 0.6),
	Position = Vector3.new(metaX + 6, ALTO + 6, 0),
	Color = Color3.fromRGB(240, 240, 240),
	Parent = mapa,
})
crearParte({
	Name = "Bandera",
	Size = Vector3.new(0.2, 3, 5),
	Position = Vector3.new(metaX + 6, ALTO + 10.5, 2.8),
	Color = Color3.fromRGB(230, 50, 50),
	CanCollide = false,
	Parent = mapa,
})
crearCartel(poste, "META", Color3.fromRGB(255, 220, 60))

local cartelPuente = crearParte({
	Name = "CartelPuente",
	Size = Vector3.new(1, 1, 1),
	Position = Vector3.new(BORDE_INICIO + TAM / 2, ALTO, 0),
	Transparency = 1,
	CanCollide = false,
	CanTouch = false,
	Parent = mapa,
})
crearCartel(cartelPuente, "PUENTE\nTrae los cubitos aquí", Color3.fromRGB(120, 200, 255))

if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(-12, ALTO + 0.5, 0)
	spawn.Color = Color3.fromRGB(240, 240, 240)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = mapa
end

mapa.Parent = workspace

local cubitos = Instance.new("Folder")
cubitos.Name = "Cubitos"

local posiciones = {
	Vector2.new(-14, -12), Vector2.new(-6, -14), Vector2.new(4, -12), Vector2.new(12, -6),
	Vector2.new(-16, 6), Vector2.new(-4, 10), Vector2.new(6, 14), Vector2.new(12, 8),
}
local colores = {
	Color3.fromRGB(85, 170, 255), Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 85, 127),
	Color3.fromRGB(85, 230, 120), Color3.fromRGB(170, 100, 255), Color3.fromRGB(255, 230, 70),
}

for i, posicion in ipairs(posiciones) do
	crearParte({
		Name = "Cubito" .. i,
		Size = Vector3.new(2, 2, 2),
		Position = Vector3.new(posicion.X, ALTO + 1.5, posicion.Y),
		Color = colores[(i - 1) % #colores + 1],
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = cubitos,
	})
end

cubitos.Parent = workspace

-- Va al final porque BridgeBuilder espera esta carpeta para arrancar.
local puente = Instance.new("Folder")
puente.Name = "GrowingBlocks"

for i = 1, COLUMNAS do
	local z = (i - (COLUMNAS + 1) / 2) * TAM
	crearParte({
		Name = Config.PREFIJO_COLUMNA .. i,
		Size = Vector3.new(TAM, TAM, TAM),
		Position = Vector3.new(BORDE_INICIO + TAM / 2, ALTO - TAM / 2, z),
		Color = Color3.fromRGB(40, 110, 220),
		Material = Enum.Material.SmoothPlastic,
		Parent = puente,
	})
end

puente.Parent = workspace
