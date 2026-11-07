local Config = {}

-- Los bloques donde empieza el puente se llaman BlockBlueA1, BlockBlueA2, ...
-- y deben estar dentro de la carpeta "GrowingBlocks" en Workspace.
Config.PREFIJO_COLUMNA = "BlockBlueA"
Config.MAX_COLUMNAS = 50

-- Cuántos bloques tiene que crecer CADA columna para terminar el puente.
-- Bloques totales necesarios = número de columnas x LARGO_PUENTE
Config.LARGO_PUENTE = 8

-- Segundos que tarda un cubito en volver a aparecer después de recogerlo.
Config.TIEMPO_REAPARICION_CUBITO = 3

-- Si existe una parte llamada "Meta" en Workspace, al terminar el puente
-- los jugadores tienen que cruzar y tocarla para ganar.
Config.NOMBRE_META = "Meta"
Config.TIEMPO_PARA_CRUZAR = 30

-- Si NO hay Meta, todos ganan al terminar el puente y se espera esto antes de la siguiente ronda.
Config.TIEMPO_CELEBRACION = 6

-- Para que funcione en Studio: Game Settings > Security > "Enable Studio Access to API Services".
Config.NOMBRE_DATASTORE = "PuenteDatos_v1"

-- Solo se usa si en Workspace NO existen "Cubitos" ni "GrowingBlocks".
Config.MAPA_COLUMNAS = 4

return Config
