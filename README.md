# Puentes y Cofres

Juego de Roblox por equipos: lleva bloques desde tu base para construir puentes hasta el
centro, captura los cofres y usa el lanzacohetes para romper los puentes del rival.

## Cómo se juega
1. Cada jugador entra en el equipo **Azul** o **Rojo**.
2. Toca una caja de **BLOQUES** de tu base para llenarte las manos (con la Mochila cargas más).
3. Llévalos a una **zona amarilla** del borde de tu base o camina sobre tu puente: crece un bloque por cada uno.
4. Cuando un puente llega al centro, cruza y toca el **cofre** para que sea de tu equipo.
   El otro equipo te lo puede quitar tocándolo.
5. Pulsa **1** para sacar el **lanzacohetes**. Haz clic para disparar: elimina rivales y,
   si le das a un puente enemigo, ese bloque y todo lo que hay delante se cae.
6. Gana la ronda el equipo que tenga **todos los cofres**, o el que tenga más cuando se acabe el tiempo.

## Monedas, nivel y tienda
- Ganas **monedas** y **experiencia (XP)** por cada bloque, eliminación, cofre capturado,
  victoria y por jugar cada ronda. Al subir de nivel te regalan monedas.
- En la **Tienda** (botón de la izquierda o el puesto de tu base) compras mejoras:
  🎒 Mochila (cargar más bloques), 👟 Zapatillas (velocidad), 💥 Cohete grande (radio de explosión)
  y ⚡ Recarga rápida (disparar más seguido).
- En **Perfil** ves tu nivel, victorias, partidas, % de victorias, bloques, eliminaciones y cofres.
- Todo se guarda entre partidas con DataStore. Premios y precios se cambian en `Config.luau`.

## Archivos
| Archivo | Qué hace |
|---|---|
| `src/shared/Config.luau` | Ajustes: equipos, puentes, tiempos, cohetes, premios, niveles y tienda |
| `src/server/Juego.server.lua` | Equipos, rondas, quién gana y caerse al vacío |
| `src/server/Mapa.server.lua` | Crea el mapa (carpeta `Arena`) si Workspace no tiene uno |
| `src/server/Puentes.luau` | Cajas de bloques, llevar bloques y hacer crecer o romper los puentes |
| `src/server/Cofres.luau` | Capturar los cofres del centro |
| `src/server/Cohetes.luau` | El lanzacohetes |
| `src/server/Datos.luau` | Perfil de cada jugador (monedas, nivel, estadísticas, mejoras) y guardado |
| `src/server/Tienda.luau` | Recibe las compras y aplica la velocidad |
| `src/server/Ayudantes.luau` | Funciones pequeñas que usan los demás scripts |
| `src/client/init.client.luau` | Arranca la pantalla del jugador |
| `src/client/HUD.luau` | Marcador de cofres, tiempo, ayuda y avisos |
| `src/client/Monedas.luau` | Monedas, nivel y botones de la izquierda |
| `src/client/Tienda.luau` | Panel de la tienda |
| `src/client/Perfil.luau` | Panel de estadísticas |
| `src/client/Cohete.luau` | Disparar el lanzacohetes |
| `src/client/Interfaz.luau` | Colores y funciones para crear la interfaz |

## Usar tu propio mapa
Si en Workspace hay una carpeta **`Arena`**, el juego usa esa y no crea otra. Dentro, el juego
busca partes por sus **atributos** (en Studio: Properties → Attributes):

| Atributos | Qué es |
|---|---|
| `Carril` (número) y `Equipo` (`Azul`/`Rojo`) | Zona de entrega donde empieza un puente. El puente crece hacia su eje X (rojo) |
| `Monton` (`Azul`/`Rojo`) | Montón de bloques de ese equipo |
| `Cofre` (true) | Cofre que se puede capturar |

Además necesitas una **SpawnLocation** por equipo con su `TeamColor`.

La forma más fácil: pulsa Play, copia la carpeta `Arena` de Workspace, pulsa Stop y pégala
en Workspace. Después puedes moverla y decorarla.

Para que el guardado funcione en Studio: *Game Settings > Security > Enable Studio Access to API Services*.

## Probar con dos equipos en Studio
Pestaña **Test** → **Clients and Servers** → elige **2 Players** → **Start**.

## Compilar
```bash
rojo build -o "Roblox.rbxlx"
```

O para ver los cambios en vivo, inicia `rojo serve` y pulsa **Connect** en el plugin de Rojo en Studio.

Más ayuda en [la documentación de Rojo](https://rojo.space/docs).
