-- Panel de la tienda: una tarjeta por mejora con su nivel, lo que cambia y el botón de comprar.
-- Se abre con el botón "Tienda" o acercándote al puesto de tu base.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local crear, C = Interfaz.crear, Interfaz.COLOR
local player = Players.LocalPlayer

local Tienda = {}

local function crearTarjeta(lista, mejora, orden)
	local tarjeta = crear("Frame", {
		Name = mejora.id,
		LayoutOrder = orden,
		BackgroundColor3 = C.tarjeta,
		Parent = lista,
	})
	Interfaz.redondear(tarjeta, 12)
	crear("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = tarjeta,
	})

	Interfaz.texto({
		Size = UDim2.new(1, 0, 0, 24),
		Font = Enum.Font.FredokaOne,
		Text = mejora.icono .. " " .. mejora.nombre,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tarjeta,
	})
	local nivelTexto = Interfaz.texto({
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		TextSize = 14,
		TextColor3 = C.dorado,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = tarjeta,
	})
	Interfaz.texto({
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.Gotham,
		Text = mejora.descripcion,
		TextSize = 14,
		TextColor3 = C.suave,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tarjeta,
	})
	local valorTexto = Interfaz.texto({
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = tarjeta,
	})
	local boton = Interfaz.boton({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.verde,
		Text = "",
		Parent = tarjeta,
	})

	local ocupado = false
	local mensajeTemporal = nil

	local function actualizar()
		local nivel = player:GetAttribute("Mejora_" .. mejora.id) or 0
		local maximo = #mejora.precios
		local precio = mejora.precios[nivel + 1]
		local monedas = player:GetAttribute("Monedas") or 0

		-- ●●○○ = nivel 2 de 4
		nivelTexto.Text = string.rep("●", nivel) .. string.rep("○", maximo - nivel)

		local ahora = string.format(mejora.formato, mejora.valor(nivel))
		if precio then
			valorTexto.Text = ahora .. "  →  " .. string.format(mejora.formato, mejora.valor(nivel + 1))
		else
			valorTexto.Text = ahora
		end

		if mensajeTemporal then
			boton.Text = mensajeTemporal
		elseif not precio then
			boton.Text = "MÁXIMO"
		else
			boton.Text = "Comprar · " .. precio .. " 🪙"
		end

		-- Verde si te alcanza, gris si no (o si ya está al máximo)
		local alcanza = precio ~= nil and monedas >= precio
		boton.BackgroundColor3 = alcanza and C.verde or C.gris
	end

	boton.Activated:Connect(function()
		if ocupado then
			return
		end
		ocupado = true

		local comprar = ReplicatedStorage:WaitForChild("Comprar")
		local exito, comprado, mensaje = pcall(function()
			return comprar:InvokeServer(mejora.id)
		end)
		if not exito then
			comprado, mensaje = false, "Intenta otra vez"
		end

		mensajeTemporal = comprado and "¡Comprado!" or mensaje
		boton.BackgroundColor3 = comprado and C.verde or C.rojo
		boton.Text = mensajeTemporal
		task.wait(1.2)
		mensajeTemporal = nil
		ocupado = false
		actualizar()
	end)

	return actualizar
end

function Tienda.iniciar(gui)
	local panel, contenido = Interfaz.crearPanel(gui, "Tienda", "🛒 TIENDA")

	-- Monedas arriba a la derecha del panel
	local monedasTexto = Interfaz.texto({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -60, 0, 12),
		Size = UDim2.new(0, 140, 0, 36),
		Font = Enum.Font.FredokaOne,
		Text = "",
		TextSize = 22,
		TextColor3 = C.dorado,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 11,
		Parent = panel,
	})

	local lista = crear("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = contenido,
	})
	crear("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, 150),
		CellPadding = UDim2.new(0, 10, 0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = lista,
	})

	local actualizadores = {}
	for orden, mejora in ipairs(Config.MEJORAS) do
		table.insert(actualizadores, crearTarjeta(lista, mejora, orden))
	end

	local function actualizarTodo()
		monedasTexto.Text = "🪙 " .. (player:GetAttribute("Monedas") or 0)
		for _, actualizar in ipairs(actualizadores) do
			actualizar()
		end
	end
	player.AttributeChanged:Connect(actualizarTodo)
	actualizarTodo()

	-- El puesto de la tienda en tu base
	ProximityPromptService.PromptTriggered:Connect(function(aviso)
		if aviso.Name == "AbrirTienda" then
			Interfaz.abrirPanel("Tienda")
		end
	end)
end

return Tienda
