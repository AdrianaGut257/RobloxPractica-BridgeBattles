local Config = {}

-- Los dos equipos. "color" es un BrickColor porque así lo piden los Teams de Roblox.
Config.EQUIPOS = {
	{ nombre = "Azul", color = BrickColor.new("Bright blue") },
	{ nombre = "Rojo", color = BrickColor.new("Bright red") },
}

-- Puentes
Config.CARRILES = 3 -- puentes por equipo (y cofres en el centro)
Config.LARGO_PUENTE = 10 -- bloques que necesita cada puente para llegar al centro
Config.TAM_BLOQUE = Vector3.new(4, 1, 6) -- X = largo de cada bloque, Z = ancho del puente

-- Rondas (en segundos)
Config.TIEMPO_RONDA = 240
Config.TIEMPO_ENTRE_RONDAS = 8

-- Lanzacohetes
Config.COHETE_VELOCIDAD = 90 -- studs por segundo
Config.COHETE_ALCANCE = 250 -- distancia máxima antes de desaparecer
Config.COHETE_RADIO = 6 -- radio de la explosión
Config.COHETE_ESPERA = 1.5 -- segundos entre disparos

-- Si un jugador cae por debajo de esta altura, muere.
Config.ALTURA_VACIO = 20

-- ===== Monedas y experiencia =====
-- Lo que gana cada jugador por cada cosa. "estadistica" es el número del perfil que sube.
Config.RECOMPENSAS = {
	Bloque = { monedas = 2, xp = 1, estadistica = "Bloques", texto = "Bloque" },
	Eliminacion = { monedas = 10, xp = 5, estadistica = "Eliminaciones", texto = "Eliminación" },
	Cofre = { monedas = 15, xp = 8, estadistica = "Cofres", texto = "Cofre capturado" },
	Victoria = { monedas = 50, xp = 25, estadistica = "Victorias", texto = "¡Victoria!" },
	Participacion = { monedas = 10, xp = 8, texto = "Por jugar" },
}

-- Monedas de regalo al subir de nivel
Config.MONEDAS_POR_NIVEL = 25

-- Experiencia que hace falta para pasar del nivel "nivel" al siguiente
function Config.xpParaNivel(nivel)
	return 30 + nivel * 20
end

-- ===== Tienda =====
-- precios[1] es lo que cuesta el nivel 1, precios[2] el nivel 2, etc.
-- valor(nivel) dice cuánto vale la mejora en ese nivel (nivel 0 = sin comprar).
Config.MEJORAS = {
	{
		id = "Capacidad",
		nombre = "Mochila",
		icono = "🎒",
		descripcion = "Carga más bloques a la vez",
		precios = { 50, 120, 250, 500 },
		valor = function(nivel)
			return 1 + nivel
		end,
		formato = "%d bloques",
	},
	{
		id = "Velocidad",
		nombre = "Zapatillas",
		icono = "👟",
		descripcion = "Corre más rápido",
		precios = { 40, 90, 180, 350, 600 },
		valor = function(nivel)
			return 16 + 2 * nivel
		end,
		formato = "velocidad %d",
	},
	{
		id = "Explosion",
		nombre = "Cohete grande",
		icono = "💥",
		descripcion = "Explosiones más grandes",
		precios = { 60, 150, 300 },
		valor = function(nivel)
			return Config.COHETE_RADIO + 1.5 * nivel
		end,
		formato = "radio %.1f",
	},
	{
		id = "Recarga",
		nombre = "Recarga rápida",
		icono = "⚡",
		descripcion = "Dispara más seguido",
		precios = { 60, 150, 300 },
		valor = function(nivel)
			return Config.COHETE_ESPERA - 0.3 * nivel
		end,
		formato = "%.1f s entre disparos",
	},
}

function Config.buscarMejora(id)
	for _, mejora in ipairs(Config.MEJORAS) do
		if mejora.id == id then
			return mejora
		end
	end
	return nil
end

function Config.valorMejora(id, nivel)
	return Config.buscarMejora(id).valor(nivel)
end

-- Para que funcione en Studio: Game Settings > Security > "Enable Studio Access to API Services".
Config.NOMBRE_DATASTORE = "PuenteDatos_v1"

function Config.buscarEquipo(nombre)
	for _, equipo in ipairs(Config.EQUIPOS) do
		if equipo.nombre == nombre then
			return equipo
		end
	end
	return nil
end

return Config
