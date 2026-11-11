-- Barra de la izquierda: monedas, nivel con su barra de experiencia y botones de Tienda y Perfil.
-- También muestra los "+2 🪙" cuando ganas algo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local crear, C = Interfaz.crear, Interfaz.COLOR
local player = Players.LocalPlayer

local Monedas = {}

function Monedas.iniciar(gui)
	local lateral = crear("Frame", {
		Name = "Lateral",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.new(0, 170, 0, 230),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	crear("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = lateral,
	})

	-- ===== Monedas =====
	local tarjetaMonedas = crear("Frame", {
		Name = "Monedas",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = C.fondo,
		BackgroundTransparency = 0.15,
		Parent = lateral,
	})
	Interfaz.redondear(tarjetaMonedas, 12)
	Interfaz.borde(tarjetaMonedas, C.dorado, 2)
	Interfaz.texto({
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 34, 1, 0),
		Text = "🪙",
		TextSize = 26,
		Parent = tarjetaMonedas,
	})
	local cantidadMonedas = Interfaz.texto({
		Position = UDim2.new(0, 46, 0, 0),
		Size = UDim2.new(1, -54, 1, 0),
		Font = Enum.Font.FredokaOne,
		Text = "0",
		TextSize = 26,
		TextColor3 = C.dorado,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tarjetaMonedas,
	})
	local escalaMonedas = crear("UIScale", { Parent = tarjetaMonedas })

	-- ===== Nivel y experiencia =====
	local tarjetaNivel = crear("Frame", {
		Name = "Nivel",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = C.fondo,
		BackgroundTransparency = 0.15,
		Parent = lateral,
	})
	Interfaz.redondear(tarjetaNivel, 12)
	local textoNivel = Interfaz.texto({
		Position = UDim2.new(0, 10, 0, 6),
		Size = UDim2.new(1, -20, 0, 20),
		Font = Enum.Font.FredokaOne,
		Text = "Nivel 1",
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tarjetaNivel,
	})
	local textoXP = Interfaz.texto({
		Position = UDim2.new(0, 10, 0, 6),
		Size = UDim2.new(1, -20, 0, 20),
		Text = "0 / 50",
		TextSize = 12,
		TextColor3 = C.suave,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = tarjetaNivel,
	})
	local barraXP = crear("Frame", {
		Position = UDim2.new(0, 10, 0, 32),
		Size = UDim2.new(1, -20, 0, 10),
		BackgroundColor3 = C.tarjeta,
		Parent = tarjetaNivel,
	})
	Interfaz.redondear(barraXP, 5)
	local rellenoXP = crear("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.morado,
		Parent = barraXP,
	})
	Interfaz.redondear(rellenoXP, 5)

	-- ===== Botones =====
	local function botonMenu(orden, texto, color, panel)
		local boton = Interfaz.boton({
			Name = panel,
			LayoutOrder = orden,
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = color,
			Text = texto,
			TextSize = 20,
			Parent = lateral,
		})
		boton.Activated:Connect(function()
			Interfaz.alternarPanel(panel)
		end)
	end
	botonMenu(3, "🛒 Tienda", C.verde, "Tienda")
	botonMenu(4, "📊 Perfil", C.morado, "Perfil")

	-- ===== Actualizar =====
	local ultimasMonedas = nil

	local function actualizar()
		local monedas = player:GetAttribute("Monedas") or 0
		local nivel = player:GetAttribute("Nivel") or 1
		local xp = player:GetAttribute("XP") or 0
		local necesaria = Config.xpParaNivel(nivel)

		cantidadMonedas.Text = tostring(monedas)
		textoNivel.Text = "Nivel " .. nivel
		textoXP.Text = xp .. " / " .. necesaria .. " XP"
		TweenService:Create(rellenoXP, TweenInfo.new(0.3), {
			Size = UDim2.fromScale(math.clamp(xp / necesaria, 0, 1), 1),
		}):Play()

		-- Saltito cuando suben las monedas
		if ultimasMonedas and monedas > ultimasMonedas then
			escalaMonedas.Scale = 1.12
			TweenService:Create(escalaMonedas, TweenInfo.new(0.25), { Scale = 1 }):Play()
		end
		ultimasMonedas = monedas
	end

	player.AttributeChanged:Connect(actualizar)
	actualizar()

	-- ===== "+2 🪙 Bloque" al lado de las monedas =====
	local notas = crear("Frame", {
		Name = "Notas",
		Position = UDim2.new(0, 190, 0.5, -115),
		Size = UDim2.new(0, 220, 0, 160),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	crear("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notas,
	})
	local orden = 0

	local function mostrarNota(monedas, motivo)
		orden += 1
		local nota = Interfaz.texto({
			LayoutOrder = orden,
			Size = UDim2.new(1, 0, 0, 24),
			Font = Enum.Font.FredokaOne,
			Text = "+" .. monedas .. " 🪙  " .. (motivo or ""),
			TextSize = 20,
			TextColor3 = C.dorado,
			TextStrokeTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = notas,
		})
		-- Máximo 5 a la vez
		local hijos = {}
		for _, hijo in ipairs(notas:GetChildren()) do
			if hijo:IsA("TextLabel") then
				table.insert(hijos, hijo)
			end
		end
		if #hijos > 5 then
			table.sort(hijos, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			hijos[1]:Destroy()
		end

		task.delay(1.8, function()
			if nota.Parent then
				TweenService:Create(nota, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
				task.wait(0.5)
				nota:Destroy()
			end
		end)
	end

	task.spawn(function()
		ReplicatedStorage:WaitForChild("Recompensa").OnClientEvent:Connect(mostrarNota)
	end)
end

return Monedas
