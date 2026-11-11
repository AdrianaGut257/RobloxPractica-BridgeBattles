-- Pantalla del jugador. Cada parte está en su propio módulo (los archivos de esta carpeta):
--   HUD      -> marcador de cofres, tiempo, ayuda y avisos
--   Monedas  -> monedas, nivel y botones de la izquierda
--   Tienda   -> panel para comprar mejoras
--   Perfil   -> panel con tus estadísticas
--   Cohete   -> disparar el lanzacohetes
local Players = game:GetService("Players")

local Interfaz = require(script.Interfaz)

local gui = Interfaz.crear("ScreenGui", {
	Name = "HUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})

require(script.HUD).iniciar(gui)
require(script.Monedas).iniciar(gui)
require(script.Tienda).iniciar(gui)
require(script.Perfil).iniciar(gui)
require(script.Cohete).iniciar(gui)
