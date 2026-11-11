-- Cofres del centro: tócalo para que sea de tu equipo. El otro equipo te lo puede quitar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ayudantes = require(script.Parent.Ayudantes)
local Datos = require(script.Parent.Datos)

local Cofres = {}
Cofres.activo = false -- el script Juego lo activa durante la ronda
Cofres.alCapturar = nil -- función que el script Juego pone para enterarse

local lista = {}
local COLOR_NEUTRO = Color3.fromRGB(255, 200, 40)

-- Pinta del color del dueño las piezas del cofre llamadas "Tapa", la luz y el "Haz" de luz.
-- Si el cofre no tiene Tapa, se pinta el cofre entero.
local function pintar(cofre)
	local dueno = cofre:GetAttribute("Dueno")
	local datosEquipo = Config.buscarEquipo(dueno)
	local color = datosEquipo and datosEquipo.color.Color or COLOR_NEUTRO

	local tieneTapa = false
	for _, pieza in ipairs(cofre:GetDescendants()) do
		if pieza:IsA("BasePart") and pieza.Name == "Tapa" then
			pieza.Color = color
			tieneTapa = true
		elseif pieza:IsA("BasePart") and pieza.Name == "Haz" then
			pieza.Color = color
			pieza.Transparency = datosEquipo and 0.55 or 1 -- solo se ve si tiene dueño
		elseif pieza:IsA("PointLight") then
			pieza.Color = color
		end
	end
	if not tieneTapa then
		cofre.Color = color
	end

	local etiqueta = cofre:FindFirstChildWhichIsA("TextLabel", true)
	if etiqueta then
		etiqueta.Text = datosEquipo and string.upper(dueno) or "COFRE"
		etiqueta.TextColor3 = datosEquipo and datosEquipo.color.Color or COLOR_NEUTRO
	end
end

local function capturar(cofre, hit)
	if not Cofres.activo then
		return
	end

	local _, player = Ayudantes.jugadorDe(hit)
	local equipo = player and Ayudantes.equipoDe(player)
	if not equipo or cofre:GetAttribute("Dueno") == equipo then
		return
	end

	cofre:SetAttribute("Dueno", equipo)
	pintar(cofre)

	Datos.recompensar(player, "Cofre")

	local datosEquipo = Config.buscarEquipo(equipo)
	Ayudantes.avisarTodos(player.DisplayName .. " capturó un cofre para el equipo " .. equipo, datosEquipo.color.Color)

	if Cofres.alCapturar then
		Cofres.alCapturar()
	end
end

function Cofres.contar(equipo)
	local cantidad = 0
	for _, cofre in ipairs(lista) do
		if cofre:GetAttribute("Dueno") == equipo then
			cantidad += 1
		end
	end
	return cantidad
end

function Cofres.total()
	return #lista
end

function Cofres.reiniciar()
	for _, cofre in ipairs(lista) do
		cofre:SetAttribute("Dueno", "")
		pintar(cofre)
	end
end

-- Busca en el mapa las partes con el atributo "Cofre"
function Cofres.iniciar(arena)
	for _, parte in ipairs(arena:GetDescendants()) do
		if parte:IsA("BasePart") and parte:GetAttribute("Cofre") then
			table.insert(lista, parte)
			parte.Touched:Connect(function(hit)
				capturar(parte, hit)
			end)
		end
	end
	Cofres.reiniciar()

	if #lista == 0 then
		warn("[Cofres] No encontré cofres (partes con el atributo 'Cofre') en el mapa.")
	end
end

return Cofres
