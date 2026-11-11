-- Disparo del lanzacohetes: al hacer clic le dice al servidor hacia dónde apuntas.
-- El servidor revisa todo y crea el cohete.
-- Mientras tienes el lanzacohetes en la mano se ve una barra con el tiempo de recarga.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Interfaz = require(script.Parent.Interfaz)

local crear, C = Interfaz.crear, Interfaz.COLOR
local player = Players.LocalPlayer

local Cohete = {}

-- Segundos entre disparos, según la mejora "Recarga rápida" que tengas
local function tiempoRecarga()
	return Config.valorMejora("Recarga", player:GetAttribute("Mejora_Recarga") or 0)
end

function Cohete.iniciar(gui)
	-- ===== Barra de recarga (encima del texto de ayuda) =====
	local caja = crear("Frame", {
		Name = "Recarga",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -140),
		Size = UDim2.new(0, 220, 0, 34),
		BackgroundColor3 = C.fondo,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = gui,
	})
	Interfaz.redondear(caja, 10)

	local relleno = crear("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.verde,
		Parent = caja,
	})
	Interfaz.redondear(relleno, 10)

	local texto = Interfaz.texto({
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.FredokaOne,
		Text = "🚀 ¡Listo!",
		TextSize = 18,
		TextStrokeTransparency = 0.5,
		ZIndex = 2,
		Parent = caja,
	})

	local listoEn = 0 -- momento en que se puede volver a disparar
	local espera = 1

	-- Cada cuadro actualiza la barra
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		caja.Visible = character ~= nil and character:FindFirstChild("Lanzacohetes") ~= nil
		if not caja.Visible then
			return
		end

		local faltan = listoEn - os.clock()
		if faltan > 0 then
			relleno.Size = UDim2.fromScale(1 - faltan / espera, 1)
			relleno.BackgroundColor3 = C.dorado
			texto.Text = string.format("🚀 Recargando %.1f s", faltan)
		else
			relleno.Size = UDim2.fromScale(1, 1)
			relleno.BackgroundColor3 = C.verde
			texto.Text = "🚀 ¡Listo!"
		end
	end)

	-- ===== Disparar =====
	local mouse = player:GetMouse()
	local conectadas = setmetatable({}, { __mode = "k" })

	local function conectar(herramienta)
		if not herramienta:IsA("Tool") or herramienta.Name ~= "Lanzacohetes" or conectadas[herramienta] then
			return
		end
		conectadas[herramienta] = true

		herramienta.Activated:Connect(function()
			if os.clock() < listoEn then
				return -- todavía recargando
			end
			local disparar = ReplicatedStorage:FindFirstChild("Disparar")
			if disparar then
				espera = tiempoRecarga()
				listoEn = os.clock() + espera
				disparar:FireServer(mouse.Hit.Position)
			end
		end)
	end

	local function alAparecer(character)
		character.ChildAdded:Connect(conectar)
	end
	player.CharacterAdded:Connect(alAparecer)
	if player.Character then
		alAparecer(player.Character)
	end
end

return Cohete
