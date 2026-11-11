-- Crea el mapa (carpeta "Arena") SOLO si Workspace todavía no tiene uno.
-- Si copias la Arena a tu mundo y la editas en Studio, este script no hace nada.
--
-- Qué busca el juego en la Arena (por atributos, así puedes cambiar formas y colores):
--   Carril = número, Equipo = "Azul"/"Rojo"  -> zona de entrega donde empieza un puente
--                                               (el puente crece hacia su eje X rojo)
--   Monton = "Azul"/"Rojo"                   -> montón de bloques de ese equipo
--   Cofre = true                             -> cofre que se puede capturar
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Lighting = game:GetService("Lighting")

-- Cielo: nubes, bruma azul y colores un poco más vivos
local function buscarOCrear(padre, clase)
	local objeto = padre:FindFirstChildOfClass(clase)
	if not objeto then
		objeto = Instance.new(clase)
		objeto.Parent = padre
	end
	return objeto
end

local nubes = buscarOCrear(workspace.Terrain, "Clouds")
nubes.Cover = 0.6
nubes.Density = 0.7

local bruma = buscarOCrear(Lighting, "Atmosphere")
bruma.Density = 0.3
bruma.Offset = 0.2
bruma.Color = Color3.fromRGB(200, 220, 245)
bruma.Decay = Color3.fromRGB(110, 150, 200)
bruma.Glare = 0.2
bruma.Haze = 1

local colores = buscarOCrear(Lighting, "ColorCorrectionEffect")
colores.Saturation = 0.15
colores.Contrast = 0.05

if workspace:FindFirstChild("Arena") then
	return
end

local ALTO = 60 -- altura del suelo
local TAM = Config.TAM_BLOQUE
local MEDIO = 7 -- radio de cada plataforma del centro
local BORDE = MEDIO + Config.LARGO_PUENTE * TAM.X -- distancia del centro al borde de cada base
local FONDO_BASE = 40 -- profundidad de cada base
local SEPARACION_CARRILES = 24
local ANCHO_BASE = Config.CARRILES * SEPARACION_CARRILES
local BALDOSA = 8

local ROCA = Color3.fromRGB(118, 108, 98)
local ROCA_OSCURA = Color3.fromRGB(86, 80, 76)
local BLANCO = Color3.fromRGB(240, 240, 245)
local MADERA = Color3.fromRGB(150, 100, 60)
local DORADO = Color3.fromRGB(255, 200, 40)

local azar = Random.new(7) -- siempre el mismo "azar", así el mapa sale igual cada vez

local arena = Instance.new("Folder")
arena.Name = "Arena"

local function crearParte(propiedades)
	local parte = Instance.new("Part")
	parte.Anchored = true
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Material = Enum.Material.SmoothPlastic
	-- Forma y tamaño primero; la posición al final
	if propiedades.Shape then
		parte.Shape = propiedades.Shape
	end
	if propiedades.Size then
		parte.Size = propiedades.Size
	end
	for nombre, valor in pairs(propiedades) do
		if nombre ~= "Parent" and nombre ~= "Shape" and nombre ~= "Size" then
			parte[nombre] = valor
		end
	end
	parte.Parent = propiedades.Parent or arena
	return parte
end

-- Las partes de adorno no se pueden tocar (así no estorban al juego)
local function adorno(propiedades)
	propiedades.CanTouch = false
	return crearParte(propiedades)
end

-- Un cilindro "de pie" (en Roblox los cilindros están acostados sobre el eje X)
local function cilindro(nombre, alto, diametro, posicion, color, material)
	return crearParte({
		Name = nombre,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(alto, diametro, diametro),
		CFrame = CFrame.new(posicion) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function crearCartel(adornee, texto, color, alto)
	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.new(0, 160, 0, 40)
	cartel.StudsOffset = Vector3.new(0, alto or 4, 0)
	cartel.MaxDistance = 120
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

local function zCarril(i)
	return (i - (Config.CARRILES + 1) / 2) * SEPARACION_CARRILES
end

-- Baranda entre dos puntos del suelo: postes cada ~6 studs y dos barras
local function baranda(desde, hasta, color)
	local largo = (hasta - desde).Magnitude
	if largo < 1 then
		return
	end
	local postes = math.max(1, math.round(largo / 6))
	for i = 0, postes do
		adorno({
			Name = "Poste",
			Size = Vector3.new(0.8, 3.6, 0.8),
			Position = desde:Lerp(hasta, i / postes) + Vector3.new(0, 1.8, 0),
			Color = color,
		})
	end
	for _, altura in ipairs({ 1.6, 3.4 }) do
		local medio = (desde + hasta) / 2 + Vector3.new(0, altura, 0)
		adorno({
			Name = "Barra",
			Size = Vector3.new(0.5, 0.5, largo),
			CFrame = CFrame.lookAt(medio, hasta + Vector3.new(0, altura, 0)),
			Color = BLANCO,
		})
	end
end

-- Faro con luz, a los lados de cada puente
local function faro(posicion, color)
	adorno({
		Name = "Faro",
		Size = Vector3.new(1.4, 6, 1.4),
		Position = posicion + Vector3.new(0, 3, 0),
		Color = BLANCO,
	})
	local luz = adorno({
		Name = "Luz",
		Size = Vector3.new(1.8, 1.2, 1.8),
		Position = posicion + Vector3.new(0, 6.6, 0),
		Color = color,
		Material = Enum.Material.Neon,
	})
	local brillo = Instance.new("PointLight")
	brillo.Color = color
	brillo.Range = 12
	brillo.Brightness = 1.5
	brillo.Parent = luz
end

-- Isla flotante: capas de roca cada vez más pequeñas hacia abajo, y algunas piedras sueltas
local function roca(centro, ancho, fondo)
	local y = ALTO - 1
	local capas = {
		{ alto = 6, achica = 0 },
		{ alto = 7, achica = 0.2 },
		{ alto = 7, achica = 0.42 },
		{ alto = 6, achica = 0.62 },
		{ alto = 5, achica = 0.8 },
	}
	for i, capa in ipairs(capas) do
		y -= capa.alto / 2
		adorno({
			Name = "Roca",
			Size = Vector3.new(ancho * (1 - capa.achica) - 1, capa.alto, fondo * (1 - capa.achica) - 1),
			Position = Vector3.new(centro.X, y, centro.Z),
			Color = i % 2 == 0 and ROCA_OSCURA or ROCA,
			Material = Enum.Material.Slate,
		})
		y -= capa.alto / 2
	end

	for _ = 1, 10 do
		local tam = azar:NextNumber(2, 5)
		adorno({
			Name = "Piedra",
			Size = Vector3.new(tam, tam, tam),
			Position = centro + Vector3.new(
				azar:NextNumber(-ancho / 2, ancho / 2) * 0.8,
				azar:NextNumber(-22, -4) + ALTO - centro.Y,
				(azar:NextInteger(0, 1) * 2 - 1) * azar:NextNumber(fondo * 0.25, fondo * 0.45)
			),
			Orientation = Vector3.new(azar:NextNumber(0, 90), azar:NextNumber(0, 90), 0),
			Color = ROCA,
			Material = Enum.Material.Slate,
		})
	end
end

-- lado = -1 para la base de la izquierda, 1 para la de la derecha
local function crearBase(datosEquipo, lado)
	local nombre = datosEquipo.nombre
	local color = datosEquipo.color.Color
	local oscuro = color:Lerp(Color3.new(0, 0, 0), 0.3)
	local centroX = lado * (BORDE + FONDO_BASE / 2)
	local xFrente = lado * BORDE
	local xFondo = lado * (BORDE + FONDO_BASE)

	roca(Vector3.new(centroX, ALTO, 0), FONDO_BASE, ANCHO_BASE)

	-- Borde blanco y suelo de baldosas de dos tonos
	adorno({
		Name = "Borde",
		Size = Vector3.new(FONDO_BASE + 1.2, 1.4, ANCHO_BASE + 1.2),
		Position = Vector3.new(centroX, ALTO - 0.8, 0),
		Color = BLANCO,
	})
	for a = 1, FONDO_BASE // BALDOSA do
		for b = 1, ANCHO_BASE // BALDOSA do
			crearParte({
				Name = "Suelo",
				Size = Vector3.new(BALDOSA, 1, BALDOSA),
				Position = Vector3.new(
					centroX - FONDO_BASE / 2 + BALDOSA * (a - 0.5),
					ALTO - 0.5,
					-ANCHO_BASE / 2 + BALDOSA * (b - 0.5)
				),
				Color = color:Lerp(BLANCO, (a + b) % 2 == 0 and 0.5 or 0.6),
				CanTouch = false,
			})
		end
	end

	-- Barandas: atrás, a los lados y adelante (con huecos para los puentes)
	local mitad = ANCHO_BASE / 2 - 0.5
	local xFrenteB = xFrente + lado * 0.5
	local xFondoB = xFondo - lado * 0.5
	baranda(Vector3.new(xFondoB, ALTO, -mitad), Vector3.new(xFondoB, ALTO, mitad), oscuro)
	baranda(Vector3.new(xFrenteB, ALTO, -mitad), Vector3.new(xFondoB, ALTO, -mitad), oscuro)
	baranda(Vector3.new(xFrenteB, ALTO, mitad), Vector3.new(xFondoB, ALTO, mitad), oscuro)

	local hueco = TAM.Z / 2 + 0.8
	local zDesde = -mitad
	for i = 1, Config.CARRILES do
		local z = zCarril(i)
		baranda(Vector3.new(xFrenteB, ALTO, zDesde), Vector3.new(xFrenteB, ALTO, z - hueco), oscuro)
		faro(Vector3.new(xFrenteB, ALTO, z - hueco - 0.7), color)
		faro(Vector3.new(xFrenteB, ALTO, z + hueco + 0.7), color)
		zDesde = z + hueco
	end
	baranda(Vector3.new(xFrenteB, ALTO, zDesde), Vector3.new(xFrenteB, ALTO, mitad), oscuro)

	-- Banderas en las esquinas de atrás
	for _, zLado in ipairs({ -1, 1 }) do
		local base = Vector3.new(xFondo - lado * 3, ALTO, zLado * (ANCHO_BASE / 2 - 3))
		adorno({
			Name = "Mastil",
			Size = Vector3.new(0.8, 18, 0.8),
			Position = base + Vector3.new(0, 9, 0),
			Color = BLANCO,
		})
		adorno({
			Name = "Bandera",
			Size = Vector3.new(0.2, 4, 7),
			Position = base + Vector3.new(0, 15.5, -zLado * 4),
			Color = color,
			CanCollide = false,
		})
	end

	-- Donde aparecen los jugadores del equipo
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn" .. nombre
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(xFondo - lado * 9, ALTO + 0.5, 0)
	spawn.Color = BLANCO
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TeamColor = datosEquipo.color
	spawn.Neutral = false
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 3 -- segundos con escudo al aparecer
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = arena
	adorno({
		Name = "AroSpawn",
		Size = Vector3.new(11, 0.8, 11),
		Position = spawn.Position - Vector3.new(0, 0.2, 0),
		Color = color,
		Material = Enum.Material.Neon,
	})

	-- Montones de bloques: una caja de madera con cubitos encima
	for _, zMonton in ipairs({ -SEPARACION_CARRILES / 2, SEPARACION_CARRILES / 2 }) do
		local monton = crearParte({
			Name = "Monton" .. nombre,
			Size = Vector3.new(6, 3, 6),
			Position = Vector3.new(xFondo - lado * 20, ALTO + 1.5, zMonton),
			Color = MADERA,
			Material = Enum.Material.WoodPlanks,
		})
		monton:SetAttribute("Monton", nombre)
		crearCartel(monton, "BLOQUES", Color3.new(1, 1, 1), 6)

		local desfases = {
			Vector3.new(-1.3, 2.5, -1.3),
			Vector3.new(1.3, 2.5, -1.3),
			Vector3.new(-1.3, 2.5, 1.3),
			Vector3.new(1.3, 2.5, 1.3),
			Vector3.new(0, 4.5, 0),
		}
		for i, desfase in ipairs(desfases) do
			adorno({
				Name = "Cubito",
				Size = Vector3.new(2.2, 2, 2.2),
				Position = monton.Position + desfase,
				Color = color:Lerp(BLANCO, i % 2 == 0 and 0.25 or 0),
				CanCollide = false,
			})
		end
	end

	-- Puesto de la tienda: mostrador, dos postes y un toldo del color del equipo
	local zTienda = -SEPARACION_CARRILES + 2
	local mostrador = crearParte({
		Name = "Tienda",
		Size = Vector3.new(3, 3.5, 8),
		Position = Vector3.new(xFondo - lado * 7, ALTO + 1.75, zTienda),
		Color = MADERA,
		Material = Enum.Material.WoodPlanks,
	})
	for _, zPoste in ipairs({ -3.6, 3.6 }) do
		adorno({
			Name = "PosteTienda",
			Size = Vector3.new(0.6, 8, 0.6),
			Position = Vector3.new(xFondo - lado * 4, ALTO + 4, zTienda + zPoste),
			Color = BLANCO,
		})
	end
	for franja = 0, 3 do
		adorno({
			Name = "Toldo",
			Size = Vector3.new(6, 0.5, 2.25),
			Position = Vector3.new(xFondo - lado * 6, ALTO + 8.2, zTienda - 3.4 + franja * 2.25),
			Color = franja % 2 == 0 and color or BLANCO,
		})
	end
	crearCartel(mostrador, "🛒 TIENDA", Color3.new(1, 1, 1), 8)

	local aviso = Instance.new("ProximityPrompt")
	aviso.Name = "AbrirTienda" -- la pantalla del jugador busca este nombre
	aviso.ActionText = "Abrir tienda"
	aviso.ObjectText = "Tienda"
	aviso.HoldDuration = 0
	aviso.MaxActivationDistance = 10
	aviso.RequiresLineOfSight = false
	aviso.Parent = mostrador

	-- Zonas de entrega, una por carril. Se giran para que su eje X apunte al centro.
	for i = 1, Config.CARRILES do
		local giro = lado == -1 and 0 or math.pi
		local zona = crearParte({
			Name = "Entrega" .. nombre .. i,
			Size = Vector3.new(TAM.X, 0.2, TAM.Z),
			CFrame = CFrame.new(lado * (BORDE + TAM.X / 2), ALTO + 0.1, zCarril(i)) * CFrame.Angles(0, giro, 0),
			Color = Color3.fromRGB(255, 215, 60),
			Material = Enum.Material.Neon,
		})
		zona:SetAttribute("Carril", i)
		zona:SetAttribute("Equipo", nombre)
		crearCartel(zona, "Trae bloques", Color3.fromRGB(255, 230, 120), 3)
	end
end

local function crearCofre(z)
	local cofre = crearParte({
		Name = "Cofre",
		Size = Vector3.new(4, 2.2, 3),
		Position = Vector3.new(0, ALTO + 1.1, z),
		Color = MADERA,
		Material = Enum.Material.WoodPlanks,
	})
	cofre:SetAttribute("Cofre", true)

	local tapa = adorno({
		Name = "Tapa",
		Size = Vector3.new(4.3, 1, 3.3),
		Position = cofre.Position + Vector3.new(0, 1.6, 0),
		Color = DORADO,
		Parent = cofre,
	})
	local luz = Instance.new("PointLight")
	luz.Range = 14
	luz.Brightness = 2
	luz.Parent = tapa

	for _, x in ipairs({ -1.4, 1.4 }) do
		adorno({
			Name = "Franja",
			Size = Vector3.new(0.4, 2.3, 3.1),
			Position = cofre.Position + Vector3.new(x, 0, 0),
			Color = DORADO,
			Parent = cofre,
		})
	end
	adorno({
		Name = "Cerradura",
		Size = Vector3.new(0.8, 1, 3.2),
		Position = cofre.Position + Vector3.new(0, 0.7, 0),
		Color = Color3.fromRGB(60, 60, 70),
		Parent = cofre,
	})

	-- Haz de luz que sube del cofre cuando tiene dueño (se ve desde lejos)
	adorno({
		Name = "Haz",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(60, 2, 2),
		CFrame = CFrame.new(cofre.Position + Vector3.new(0, 32, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Parent = cofre,
	})

	crearCartel(cofre, "COFRE", DORADO, 5)
end

-- Base de cada equipo
crearBase(Config.EQUIPOS[1], -1)
crearBase(Config.EQUIPOS[2], 1)

-- Plataformas redondas del centro, cada una con su cofre
for i = 1, Config.CARRILES do
	local z = zCarril(i)
	cilindro("Plataforma", 1, MEDIO * 2, Vector3.new(0, ALTO - 0.5, z), Color3.fromRGB(215, 215, 222))
	cilindro("BordePlataforma", 1.4, MEDIO * 2 + 1, Vector3.new(0, ALTO - 0.9, z), BLANCO)
	cilindro("RocaCentro", 5, MEDIO * 2 - 1, Vector3.new(0, ALTO - 4, z), ROCA, Enum.Material.Slate)
	cilindro("RocaCentro", 5, MEDIO * 2 - 5, Vector3.new(0, ALTO - 9, z), ROCA_OSCURA, Enum.Material.Slate)
	cilindro("RocaCentro", 4, MEDIO * 2 - 9, Vector3.new(0, ALTO - 13.5, z), ROCA, Enum.Material.Slate)
	crearCofre(z)
end

-- Islitas sueltas de adorno, lejos de los puentes
for _ = 1, 8 do
	local tam = azar:NextNumber(4, 9)
	adorno({
		Name = "Islita",
		Size = Vector3.new(tam, tam * 0.7, tam),
		Position = Vector3.new(
			azar:NextNumber(-BORDE, BORDE),
			azar:NextNumber(ALTO - 35, ALTO - 15),
			(azar:NextInteger(0, 1) * 2 - 1) * azar:NextNumber(ANCHO_BASE / 2 + 10, ANCHO_BASE / 2 + 40)
		),
		Orientation = Vector3.new(0, azar:NextNumber(0, 90), 0),
		Color = ROCA,
		Material = Enum.Material.Slate,
	})
end

-- Va al final porque el script Juego espera esta carpeta para arrancar
arena.Parent = workspace
