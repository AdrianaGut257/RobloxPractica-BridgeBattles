-- Montones de bloques, llevar un bloque en la mano y hacer crecer / romper los puentes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ayudantes = require(script.Parent.Ayudantes)
local Datos = require(script.Parent.Datos)

local Puentes = {}
Puentes.activo = false -- el script Juego lo activa durante la ronda

local carriles = {} -- { inicio = Part, equipo = "Azul", bloques = { Part, ... } }
local carrilDeBloque = {} -- bloque del puente -> su carril

-- Los bloques del puente van en su propia carpeta, separados del mapa
local carpeta = workspace:FindFirstChild("Puentes")
if not carpeta then
	carpeta = Instance.new("Folder")
	carpeta.Name = "Puentes"
	carpeta.Parent = workspace
end
carpeta:ClearAllChildren()

-- Los bloques que lleva un jugador, de abajo hacia arriba
local function bloquesLlevados(character)
	local lista = {}
	for _, hijo in ipairs(character:GetChildren()) do
		if hijo.Name == "CarriedBlock" then
			table.insert(lista, hijo)
		end
	end
	return lista
end

-- Llena la pila de bloques en la mano hasta "capacidad"
local function llenarBloques(character, color, capacidad)
	-- R15 tiene "RightHand"; R6 tiene "Right Arm"
	local mano = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not mano then
		return
	end

	for i = #bloquesLlevados(character) + 1, capacidad do
		local bloque = Instance.new("Part")
		bloque.Name = "CarriedBlock"
		bloque.Size = Vector3.new(1.6, 1.6, 1.6)
		bloque.Color = color:Lerp(Color3.new(1, 1, 1), i % 2 == 0 and 0.25 or 0)
		bloque.Material = Enum.Material.SmoothPlastic
		bloque.CanCollide = false
		bloque.Massless = true -- para que no haga más lento al jugador
		bloque.CFrame = mano.CFrame * CFrame.new(0, (i - 1) * 1.65, -1) -- uno encima del otro

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = mano
		weld.Part1 = bloque
		weld.Parent = bloque

		bloque.Parent = character
	end
end

local entregar -- se define más abajo; agregarBloque la necesita antes

local function agregarBloque(carril)
	local k = #carril.bloques + 1
	local inicio = carril.inicio
	local tam = Config.TAM_BLOQUE
	local datosEquipo = Config.buscarEquipo(carril.equipo)

	-- El puente crece hacia el eje X (rojo) de la zona de entrega
	local destino = inicio.CFrame * CFrame.new(tam.X * k, -(inicio.Size.Y + tam.Y) / 2, 0)

	local bloque = Instance.new("Part")
	bloque.Name = "Bloque" .. k
	bloque.Size = tam
	bloque.Anchored = true
	bloque.Material = Enum.Material.SmoothPlastic
	bloque.TopSurface = Enum.SurfaceType.Smooth
	bloque.BottomSurface = Enum.SurfaceType.Smooth
	bloque.Color = datosEquipo.color.Color:Lerp(Color3.new(1, 1, 1), k % 2 == 0 and 0.25 or 0)
	bloque:SetAttribute("Equipo", carril.equipo)

	bloque.CFrame = destino * CFrame.new(0, 4, 0)
	bloque.Transparency = 0.6
	bloque.Parent = carpeta
	TweenService:Create(bloque, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = destino,
		Transparency = 0,
	}):Play()

	bloque.Touched:Connect(function(hit)
		entregar(hit, carril)
	end)

	table.insert(carril.bloques, bloque)
	carrilDeBloque[bloque] = carril
end

entregar = function(hit, carril)
	if not Puentes.activo or #carril.bloques >= Config.LARGO_PUENTE then
		return
	end

	local character, player = Ayudantes.jugadorDe(hit)
	if not player or Ayudantes.equipoDe(player) ~= carril.equipo then
		return
	end

	-- Entrega todos los bloques que lleva (los que quepan en el puente)
	local llevados = bloquesLlevados(character)
	local cantidad = math.min(#llevados, Config.LARGO_PUENTE - #carril.bloques)
	if cantidad == 0 then
		return
	end
	for i = #llevados, #llevados - cantidad + 1, -1 do
		llevados[i]:Destroy() -- primero los de arriba
	end

	for _ = 1, cantidad do
		agregarBloque(carril)
	end
	Datos.recompensar(player, "Bloque", cantidad)

	if #carril.bloques == Config.LARGO_PUENTE then
		local datosEquipo = Config.buscarEquipo(carril.equipo)
		Ayudantes.avisarTodos("¡El equipo " .. carril.equipo .. " llegó al centro!", datosEquipo.color.Color)
	end
end

-- Quita los bloques desde "indice" hasta la punta. Los quitados se caen.
local function romperDesde(carril, indice)
	for i = #carril.bloques, indice, -1 do
		local bloque = table.remove(carril.bloques, i)
		carrilDeBloque[bloque] = nil

		bloque.Anchored = false
		bloque.CanCollide = false
		bloque.CanTouch = false
		bloque.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), 18, math.random(-12, 12))
		Debris:AddItem(bloque, 3)
	end
end

-- Lo usa el lanzacohetes. Devuelve true si rompió algo.
function Puentes.romperBloque(parte, equipoAtacante)
	local carril = carrilDeBloque[parte]
	if not carril or carril.equipo == equipoAtacante then
		return false -- no es un bloque de puente, o es de tu propio equipo
	end
	local indice = table.find(carril.bloques, parte)
	if indice then
		romperDesde(carril, indice)
		return true
	end
	return false
end

function Puentes.reiniciar()
	for _, carril in ipairs(carriles) do
		for _, bloque in ipairs(carril.bloques) do
			carrilDeBloque[bloque] = nil
			bloque:Destroy()
		end
		carril.bloques = {}
	end
end

-- Busca en el mapa las zonas de entrega (atributo "Carril") y los montones (atributo "Monton")
function Puentes.iniciar(arena)
	for _, parte in ipairs(arena:GetDescendants()) do
		if not parte:IsA("BasePart") then
			continue
		end

		if parte:GetAttribute("Carril") then
			local carril = { inicio = parte, equipo = parte:GetAttribute("Equipo"), bloques = {} }
			table.insert(carriles, carril)
			parte.Touched:Connect(function(hit)
				entregar(hit, carril)
			end)
		end

		local equipoMonton = parte:GetAttribute("Monton")
		if equipoMonton then
			parte.Touched:Connect(function(hit)
				local character, player = Ayudantes.jugadorDe(hit)
				if not player or Ayudantes.equipoDe(player) ~= equipoMonton then
					return
				end
				local capacidad = Config.valorMejora("Capacidad", Datos.nivelMejora(player, "Capacidad"))
				llenarBloques(character, Config.buscarEquipo(equipoMonton).color.Color, capacidad)
			end)
		end
	end

	if #carriles == 0 then
		warn("[Puentes] No encontré zonas de entrega (partes con el atributo 'Carril') en el mapa.")
	end
end

return Puentes
