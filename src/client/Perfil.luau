-- Panel de perfil: tu nivel, experiencia y todas tus estadísticas (se guardan entre partidas).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local crear, C = Interfaz.crear, Interfaz.COLOR
local player = Players.LocalPlayer

local Perfil = {}

local function dato(nombre)
	return player:GetAttribute(nombre) or 0
end

-- Cada estadística: título, icono y cómo calcular su valor
local ESTADISTICAS = {
	{ titulo = "Victorias", icono = "🏆", valor = function()
		return dato("Victorias")
	end },
	{ titulo = "Partidas", icono = "🎮", valor = function()
		return dato("Partidas")
	end },
	{ titulo = "% de victorias", icono = "📈", valor = function()
		local partidas = dato("Partidas")
		if partidas == 0 then
			return "-"
		end
		return math.floor(dato("Victorias") / partidas * 100 + 0.5) .. "%"
	end },
	{ titulo = "Bloques puestos", icono = "🧱", valor = function()
		return dato("Bloques")
	end },
	{ titulo = "Eliminaciones", icono = "💥", valor = function()
		return dato("Eliminaciones")
	end },
	{ titulo = "Cofres capturados", icono = "📦", valor = function()
		return dato("Cofres")
	end },
}

function Perfil.iniciar(gui)
	local _, contenido = Interfaz.crearPanel(gui, "Perfil", "📊 PERFIL")

	-- ===== Nivel arriba =====
	local cabecera = crear("Frame", {
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = C.tarjeta,
		Parent = contenido,
	})
	Interfaz.redondear(cabecera, 12)

	Interfaz.texto({
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -28, 0, 24),
		Text = player.DisplayName,
		TextSize = 16,
		TextColor3 = C.suave,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = cabecera,
	})
	local nivelTexto = Interfaz.texto({
		Position = UDim2.new(0, 14, 0, 6),
		Size = UDim2.new(1, -28, 0, 30),
		Font = Enum.Font.FredokaOne,
		Text = "",
		TextSize = 26,
		TextColor3 = C.morado,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = cabecera,
	})
	local barra = crear("Frame", {
		Position = UDim2.new(0, 14, 0, 44),
		Size = UDim2.new(1, -28, 0, 16),
		BackgroundColor3 = C.fondo,
		Parent = cabecera,
	})
	Interfaz.redondear(barra, 8)
	local relleno = crear("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.morado,
		Parent = barra,
	})
	Interfaz.redondear(relleno, 8)
	local xpTexto = Interfaz.texto({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextSize = 12,
		ZIndex = 2,
		Parent = barra,
	})

	-- ===== Cuadrícula de estadísticas =====
	local cuadricula = crear("Frame", {
		Position = UDim2.new(0, 0, 0, 86),
		Size = UDim2.new(1, 0, 1, -86),
		BackgroundTransparency = 1,
		Parent = contenido,
	})
	crear("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -7, 0.5, -5),
		CellPadding = UDim2.new(0, 10, 0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = cuadricula,
	})

	local valores = {}
	for orden, estadistica in ipairs(ESTADISTICAS) do
		local celda = crear("Frame", {
			LayoutOrder = orden,
			BackgroundColor3 = C.tarjeta,
			Parent = cuadricula,
		})
		Interfaz.redondear(celda, 12)
		Interfaz.texto({
			Position = UDim2.new(0, 0, 0.12, 0),
			Size = UDim2.new(1, 0, 0.3, 0),
			Text = estadistica.icono,
			TextScaled = true,
			Parent = celda,
		})
		valores[orden] = Interfaz.texto({
			Position = UDim2.new(0, 0, 0.42, 0),
			Size = UDim2.new(1, 0, 0.3, 0),
			Font = Enum.Font.FredokaOne,
			Text = "0",
			TextSize = 26,
			Parent = celda,
		})
		Interfaz.texto({
			Position = UDim2.new(0, 4, 0.72, 0),
			Size = UDim2.new(1, -8, 0.2, 0),
			Text = estadistica.titulo,
			TextSize = 13,
			TextColor3 = C.suave,
			TextWrapped = true,
			Parent = celda,
		})
	end

	local function actualizar()
		local nivel = dato("Nivel")
		local xp = dato("XP")
		local necesaria = Config.xpParaNivel(math.max(nivel, 1))
		nivelTexto.Text = "Nivel " .. math.max(nivel, 1)
		xpTexto.Text = xp .. " / " .. necesaria .. " XP"
		relleno.Size = UDim2.fromScale(math.clamp(xp / necesaria, 0, 1), 1)

		for orden, estadistica in ipairs(ESTADISTICAS) do
			valores[orden].Text = tostring(estadistica.valor())
		end
	end

	player.AttributeChanged:Connect(actualizar)
	actualizar()
end

return Perfil
