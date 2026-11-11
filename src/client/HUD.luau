-- Marcador de cofres, tiempo, tu equipo, texto de ayuda y avisos grandes en el centro.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local crear, C = Interfaz.crear, Interfaz.COLOR
local player = Players.LocalPlayer

local HUD = {}

local function leer(nombre, valorPorDefecto)
	local valor = ReplicatedStorage:GetAttribute(nombre)
	if valor == nil then
		return valorPorDefecto
	end
	return valor
end

local function contarBloques()
	local character = player.Character
	local cantidad = 0
	if character then
		for _, hijo in ipairs(character:GetChildren()) do
			if hijo.Name == "CarriedBlock" then
				cantidad += 1
			end
		end
	end
	return cantidad
end

function HUD.iniciar(gui)
	-- ===== Marcador arriba =====
	local marcador = crear("Frame", {
		Name = "Marcador",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.new(0, 340, 0, 56),
		BackgroundColor3 = C.fondo,
		BackgroundTransparency = 0.2,
		Parent = gui,
	})
	Interfaz.redondear(marcador, 12)

	local cajasEquipo = {}
	for i, datos in ipairs(Config.EQUIPOS) do
		local caja = crear("Frame", {
			Name = datos.nombre,
			AnchorPoint = Vector2.new(i == 1 and 0 or 1, 0.5),
			Position = UDim2.new(i == 1 and 0 or 1, i == 1 and 6 or -6, 0.5, 0),
			Size = UDim2.new(0, 110, 1, -12),
			BackgroundColor3 = datos.color.Color,
			Parent = marcador,
		})
		Interfaz.redondear(caja, 8)
		Interfaz.texto({
			Size = UDim2.new(1, 0, 0.45, 0),
			Text = string.upper(datos.nombre),
			TextSize = 13,
			Parent = caja,
		})
		cajasEquipo[datos.nombre] = Interfaz.texto({
			Name = "Cofres",
			Position = UDim2.new(0, 0, 0.4, 0),
			Size = UDim2.new(1, 0, 0.6, 0),
			Font = Enum.Font.FredokaOne,
			Text = "0",
			TextSize = 22,
			Parent = caja,
		})
	end

	local tiempoTexto = Interfaz.texto({
		Name = "Tiempo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 100, 1, 0),
		Font = Enum.Font.FredokaOne,
		Text = "0:00",
		TextSize = 26,
		Parent = marcador,
	})

	local miEquipoTexto = Interfaz.texto({
		Name = "MiEquipo",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.new(0, 300, 0, 22),
		Text = "",
		TextStrokeTransparency = 0.4,
		Parent = gui,
	})

	-- ===== Ayuda abajo (encima de la barra de herramientas) =====
	local ayuda = crear("TextLabel", {
		Name = "Ayuda",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -90),
		Size = UDim2.new(0.6, 0, 0, 40),
		BackgroundColor3 = C.fondo,
		BackgroundTransparency = 0.25,
		Font = Enum.Font.GothamBold,
		Text = "",
		TextSize = 15,
		TextWrapped = true,
		TextColor3 = C.texto,
		Parent = gui,
	})
	crear("UISizeConstraint", { MaxSize = Vector2.new(480, math.huge), Parent = ayuda })
	Interfaz.redondear(ayuda, 10)
	crear("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = ayuda })

	local function actualizarAyuda()
		local bloques = contarBloques()
		local character = player.Character
		if leer("Estado", "Jugando") == "Fin" then
			ayuda.Text = "Fin de la ronda. ¡Ya empieza otra!"
		elseif character and character:FindFirstChild("Lanzacohetes") then
			ayuda.Text = "Haz clic para disparar: elimina rivales y rompe sus puentes"
		elseif bloques > 0 then
			ayuda.Text = "Llevas " .. bloques .. (bloques == 1 and " bloque" or " bloques")
				.. ": llévalos a la zona amarilla o camina sobre tu puente"
		else
			ayuda.Text = "Toca una caja de BLOQUES de tu base · Pulsa 1 para el lanzacohetes"
		end
	end

	local function actualizarMarcador()
		for nombre, etiqueta in pairs(cajasEquipo) do
			etiqueta.Text = leer("Cofres_" .. nombre, 0) .. " / " .. leer("TotalCofres", 0)
		end
		local segundos = leer("TiempoRestante", 0)
		tiempoTexto.Text = string.format("%d:%02d", segundos // 60, segundos % 60)
		actualizarAyuda()
	end

	local function actualizarMiEquipo()
		if player.Team then
			miEquipoTexto.Text = "Tu equipo: " .. string.upper(player.Team.Name)
			miEquipoTexto.TextColor3 = player.Team.TeamColor.Color
		else
			miEquipoTexto.Text = ""
		end
	end

	ReplicatedStorage.AttributeChanged:Connect(actualizarMarcador)
	player:GetPropertyChangedSignal("Team"):Connect(actualizarMiEquipo)
	actualizarMarcador()
	actualizarMiEquipo()

	local function alAparecer(character)
		character.ChildAdded:Connect(actualizarAyuda)
		character.ChildRemoved:Connect(actualizarAyuda)
		actualizarAyuda()
	end
	player.CharacterAdded:Connect(alAparecer)
	if player.Character then
		alAparecer(player.Character)
	end

	-- ===== Avisos grandes en el centro =====
	local aviso = Interfaz.texto({
		Name = "Aviso",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.9, 0, 0, 80),
		Font = Enum.Font.FredokaOne,
		Text = "",
		TextSize = 34,
		TextWrapped = true,
		TextColor3 = C.dorado,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Parent = gui,
	})
	local escalaAviso = crear("UIScale", { Parent = aviso })
	local numeroAviso = 0

	local function mostrarAviso(texto, color)
		numeroAviso += 1
		local esteAviso = numeroAviso

		aviso.Text = texto
		aviso.TextColor3 = color or C.dorado
		aviso.TextTransparency = 0
		aviso.TextStrokeTransparency = 0.3
		escalaAviso.Scale = 0.6
		TweenService:Create(escalaAviso, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()

		task.delay(3, function()
			if esteAviso ~= numeroAviso then
				return -- llegó otro aviso después, ese se encarga
			end
			TweenService:Create(aviso, TweenInfo.new(0.6), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end)
	end

	task.spawn(function()
		ReplicatedStorage:WaitForChild("Mensaje").OnClientEvent:Connect(mostrarAviso)
	end)
end

return HUD
