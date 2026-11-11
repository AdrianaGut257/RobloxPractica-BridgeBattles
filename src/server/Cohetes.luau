-- Lanzacohetes: elimina jugadores del otro equipo y rompe sus puentes.
-- El cliente solo dice "disparé hacia aquí"; el servidor hace todo lo demás.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ayudantes = require(script.Parent.Ayudantes)
local Puentes = require(script.Parent.Puentes)
local Datos = require(script.Parent.Datos)

local Cohetes = {}

local NOMBRE_HERRAMIENTA = "Lanzacohetes"
local ultimoDisparo = {}

local function crearHerramienta()
	local herramienta = Instance.new("Tool")
	herramienta.Name = NOMBRE_HERRAMIENTA
	herramienta.ToolTip = "Haz clic para disparar"
	herramienta.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 0.8, 4)
	handle.Color = Color3.fromRGB(60, 65, 75)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = herramienta

	return herramienta
end

local function explotar(tirador, posicion)
	local radio = Config.valorMejora("Explosion", Datos.nivelMejora(tirador, "Explosion"))

	local explosion = Instance.new("Explosion")
	explosion.Position = posicion
	explosion.BlastRadius = radio
	explosion.BlastPressure = 0 -- solo para que se vea; el daño lo hacemos nosotros
	explosion.DestroyJointRadiusPercent = 0
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Parent = workspace

	local equipo = Ayudantes.equipoDe(tirador)
	if not equipo then
		return
	end

	local yaGolpeados = {}
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicion, radio)) do
		-- ¿Es un jugador del otro equipo?
		local character, victima = Ayudantes.jugadorDe(parte)
		if victima and not yaGolpeados[victima] then
			yaGolpeados[victima] = true
			local esEnemigo = Ayudantes.equipoDe(victima) ~= equipo
			local protegido = character:FindFirstChildOfClass("ForceField") ~= nil
			if esEnemigo and not protegido then
				character:FindFirstChildOfClass("Humanoid").Health = 0
				Datos.recompensar(tirador, "Eliminacion")
				Ayudantes.avisar(tirador, "¡Eliminaste a " .. victima.DisplayName .. "!")
				Ayudantes.avisar(victima, tirador.DisplayName .. " te eliminó", Color3.fromRGB(255, 120, 120))
			end
		end

		-- ¿Es un bloque del puente enemigo?
		Puentes.romperBloque(parte, equipo)
	end
end

local function lanzar(tirador, origen, direccion)
	local datosEquipo = Config.buscarEquipo(Ayudantes.equipoDe(tirador))

	local cohete = Instance.new("Part")
	cohete.Name = "Cohete"
	cohete.Size = Vector3.new(0.6, 0.6, 2)
	cohete.Anchored = true
	cohete.CanCollide = false
	cohete.CanQuery = false
	cohete.CanTouch = false
	cohete.Material = Enum.Material.Neon
	cohete.Color = datosEquipo and datosEquipo.color.Color or Color3.new(1, 1, 1)
	cohete.CFrame = CFrame.lookAt(origen, origen + direccion)

	local fuego = Instance.new("Fire")
	fuego.Size = 2
	fuego.Heat = 0
	fuego.Parent = cohete
	cohete.Parent = workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { tirador.Character, cohete }

	local recorrido = 0
	local conexion
	conexion = RunService.Heartbeat:Connect(function(dt)
		local paso = Config.COHETE_VELOCIDAD * dt
		-- Miramos si en este paso choca con algo
		local choque = workspace:Raycast(cohete.Position, direccion * paso, params)

		if choque or recorrido > Config.COHETE_ALCANCE then
			conexion:Disconnect()
			cohete:Destroy()
			if choque then
				explotar(tirador, choque.Position)
			end
			return
		end

		recorrido += paso
		cohete.CFrame += direccion * paso
	end)
end

function Cohetes.iniciar()
	-- Lo que está en StarterPack se le da a cada jugador cada vez que aparece
	if not StarterPack:FindFirstChild(NOMBRE_HERRAMIENTA) then
		crearHerramienta().Parent = StarterPack
	end
	-- Los que ya estaban jugando antes de que esto corriera (pasa en Studio)
	for _, player in ipairs(Players:GetPlayers()) do
		local mochila = player:FindFirstChild("Backpack")
		if mochila and not mochila:FindFirstChild(NOMBRE_HERRAMIENTA) then
			crearHerramienta().Parent = mochila
		end
	end

	local disparar = Instance.new("RemoteEvent")
	disparar.Name = "Disparar"
	disparar.Parent = ReplicatedStorage

	disparar.OnServerEvent:Connect(function(player, objetivo)
		-- Nunca confíes en lo que manda el cliente: revisamos todo
		if typeof(objetivo) ~= "Vector3" then
			return
		end
		local character = player.Character
		local herramienta = character and character:FindFirstChild(NOMBRE_HERRAMIENTA)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not herramienta or not humanoid or humanoid.Health <= 0 then
			return
		end

		-- Tiempo de recarga. Damos 0.15 s de margen porque los mensajes por internet
		-- a veces llegan más juntos de lo que se enviaron.
		local ahora = os.clock()
		local espera = Config.valorMejora("Recarga", Datos.nivelMejora(player, "Recarga")) - 0.15
		if ultimoDisparo[player] and ahora - ultimoDisparo[player] < espera then
			return
		end

		local origen = herramienta.Handle.Position
		local distancia = (objetivo - origen).Magnitude
		if not (distancia > 0.5 and distancia < math.huge) then
			return
		end
		ultimoDisparo[player] = ahora

		local direccion = (objetivo - origen).Unit
		lanzar(player, origen + direccion * 2, direccion)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ultimoDisparo[player] = nil
	end)
end

return Cohetes
