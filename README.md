# Construye el Puente

Juego cooperativo de Roblox: recoge cubitos, llévalos al puente para hacerlo crecer y,
cuando esté terminado, cruza hasta la meta.

## Cómo se juega
1. Toca un **cubito** para recogerlo (solo puedes llevar uno a la vez).
2. Llévalo al **puente** (carpeta `GrowingBlocks`): al tocarlo, el puente crece un bloque.
3. Cuando el puente está completo, la **Meta** se ilumina. Cruza y tócala para ganar una victoria.
4. Después de unos segundos el puente se reinicia y empieza otra ronda.

El marcador (`Bloques` y `Victorias`) se guarda entre partidas con DataStore.

## Archivos
| Archivo | Qué hace |
|---|---|
| `src/shared/Config.luau` | Ajustes del juego (largo del puente, tiempos, etc.) |
| `src/server/BlockCollector.server.lua` | Recoger cubitos y llevar el bloque en la mano |
| `src/server/BridgeBuilder.server.lua` | Hacer crecer el puente, la meta y las rondas |
| `src/server/PlayerData.server.lua` | Marcador y guardado |
| `src/server/MapBuilder.server.lua` | Mapa de ejemplo (solo si el lugar no tiene uno) |
| `src/client/init.client.luau` | Pantalla del jugador: progreso, mensajes y ayuda |

## Usar tu propio mapa
En Workspace necesitas:
- Una carpeta **`Cubitos`** con las partes que se pueden recoger.
- Una carpeta **`GrowingBlocks`** con los bloques donde empieza el puente, llamados
  `BlockBlueA1`, `BlockBlueA2`, ... El puente crece hacia el eje X (rojo) de cada bloque.
- (Opcional) Una parte llamada **`Meta`** al otro lado. Si no existe, todos ganan al terminar el puente.

Si no existen `Cubitos` ni `GrowingBlocks`, se crea un mapa de ejemplo automáticamente.

Para que el guardado funcione en Studio: *Game Settings > Security > Enable Studio Access to API Services*.

## Compilar
```bash
rojo build -o "Roblox.rbxlx"
```

Abre `Roblox.rbxlx` en Roblox Studio y luego inicia el servidor de Rojo:

```bash
rojo serve
```

Más ayuda en [la documentación de Rojo](https://rojo.space/docs).
