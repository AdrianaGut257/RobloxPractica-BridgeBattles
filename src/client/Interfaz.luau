-- Colores y funciones para crear la interfaz. Lo usan todas las pantallas.
local Interfaz = {}

Interfaz.COLOR = {
	fondo = Color3.fromRGB(20, 24, 38),
	panel = Color3.fromRGB(30, 36, 56),
	tarjeta = Color3.fromRGB(44, 52, 78),
	texto = Color3.fromRGB(235, 240, 255),
	suave = Color3.fromRGB(165, 175, 205),
	dorado = Color3.fromRGB(255, 200, 40),
	verde = Color3.fromRGB(60, 190, 100),
	gris = Color3.fromRGB(85, 92, 112),
	rojo = Color3.fromRGB(225, 75, 75),
	morado = Color3.fromRGB(150, 110, 255),
}

-- Crea un objeto con sus propiedades. "Parent" se pone al final.
function Interfaz.crear(clase, propiedades)
	local objeto = Instance.new(clase)
	for nombre, valor in pairs(propiedades) do
		if nombre ~= "Parent" then
			objeto[nombre] = valor
		end
	end
	objeto.Parent = propiedades.Parent
	return objeto
end

function Interfaz.redondear(objeto, radio)
	return Interfaz.crear("UICorner", { CornerRadius = UDim.new(0, radio or 10), Parent = objeto })
end

function Interfaz.borde(objeto, color, grosor)
	return Interfaz.crear("UIStroke", {
		Color = color or Color3.new(1, 1, 1),
		Transparency = color and 0 or 0.85,
		Thickness = grosor or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = objeto,
	})
end

-- Texto simple sin fondo
function Interfaz.texto(propiedades)
	propiedades.BackgroundTransparency = 1
	propiedades.Font = propiedades.Font or Enum.Font.GothamBold
	propiedades.TextColor3 = propiedades.TextColor3 or Interfaz.COLOR.texto
	propiedades.TextSize = propiedades.TextSize or 16
	return Interfaz.crear("TextLabel", propiedades)
end

-- Botón con esquinas redondas que se achica un poco al pulsarlo
function Interfaz.boton(propiedades)
	propiedades.Font = propiedades.Font or Enum.Font.FredokaOne
	propiedades.TextColor3 = propiedades.TextColor3 or Color3.new(1, 1, 1)
	propiedades.TextSize = propiedades.TextSize or 18
	propiedades.AutoButtonColor = true
	local boton = Interfaz.crear("TextButton", propiedades)
	Interfaz.redondear(boton, 10)
	local escala = Interfaz.crear("UIScale", { Parent = boton })
	boton.MouseButton1Down:Connect(function()
		escala.Scale = 0.94
	end)
	boton.MouseButton1Up:Connect(function()
		escala.Scale = 1
	end)
	boton.MouseLeave:Connect(function()
		escala.Scale = 1
	end)
	return boton
end

-- ===== Paneles (Tienda, Perfil...): solo uno abierto a la vez =====
local TweenService = game:GetService("TweenService")
local paneles = {}

function Interfaz.cerrarPaneles()
	for _, panel in pairs(paneles) do
		panel.Visible = false
	end
end

function Interfaz.abrirPanel(nombre)
	local panel = paneles[nombre]
	if not panel then
		return
	end
	Interfaz.cerrarPaneles()
	panel.Visible = true
	local escala = panel:FindFirstChildOfClass("UIScale")
	escala.Scale = 0.85
	TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
end

function Interfaz.alternarPanel(nombre)
	local panel = paneles[nombre]
	if panel and panel.Visible then
		panel.Visible = false
	else
		Interfaz.abrirPanel(nombre)
	end
end

-- Crea un panel centrado con título y botón de cerrar. Devuelve el panel y su zona de contenido.
function Interfaz.crearPanel(gui, nombre, titulo)
	local C = Interfaz.COLOR
	local panel = Interfaz.crear("Frame", {
		Name = nombre,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.8),
		BackgroundColor3 = C.panel,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	})
	Interfaz.crear("UISizeConstraint", { MaxSize = Vector2.new(580, 430), Parent = panel })
	Interfaz.crear("UIScale", { Parent = panel })
	Interfaz.redondear(panel, 16)
	Interfaz.borde(panel)

	Interfaz.texto({
		Name = "Titulo",
		Position = UDim2.new(0, 20, 0, 12),
		Size = UDim2.new(1, -80, 0, 36),
		Font = Enum.Font.FredokaOne,
		Text = titulo,
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
		Parent = panel,
	})

	local cerrar = Interfaz.boton({
		Name = "Cerrar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.new(0, 36, 0, 36),
		BackgroundColor3 = C.rojo,
		Text = "X",
		ZIndex = 11,
		Parent = panel,
	})
	cerrar.Activated:Connect(function()
		panel.Visible = false
	end)

	local contenido = Interfaz.crear("Frame", {
		Name = "Contenido",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 60),
		Size = UDim2.new(1, -32, 1, -76),
		ZIndex = 11,
		Parent = panel,
	})

	paneles[nombre] = panel
	return panel, contenido
end

return Interfaz
