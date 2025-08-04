# Juego de Tanque - Tank Wars

## Descripción
Un juego de tanques 2D desarrollado en Processing donde controlas un tanque y debes sobrevivir a oleadas de enemigos cada vez más difíciles.

## Características
- **Sistema de oleadas**: Enemigos aparecen en oleadas progresivamente más difíciles
- **Tipos de enemigos**: Normal, Kamikaze, Invocador, Disabler, Artillería, Apoyo
- **Sistema de elementos**: Recoge power-ups como KBOOM, One Shot, Vida y Perks
- **Sistema de reparación**: Mini-juego de memoria cuando tu tanque es destruido
- **Sistema de audio**: Efectos de sonido con control de volumen
- **Perks**: Double Tap (doble daño) y Speed Cola (velocidad aumentada)

## Controles
- **WASD**: Mover el tanque
- **Mouse**: Apuntar
- **Click izquierdo**: Disparar
- **M**: Mute/Unmute audio
- **+/-**: Ajustar volumen
- **0**: Resetear volumen al 50%
- **Espacio**: Reiniciar juego

## Archivos del proyecto
- `juegodetanque.pde`: Archivo principal con la lógica del juego
- `tanque.pde`: Clase Tanque (jugador y enemigos)
- `bala.pde`: Clase Bala para proyectiles
- `elementos.pde`: Clase Elemento para power-ups
- `data/`: Carpeta con archivos de audio

## Correcciones realizadas
1. **Eliminación de enums duplicados**: Los enums `TipoEnemigo`, `TipoElemento` y `TipoPerk` ahora están solo en el archivo principal
2. **Eliminación de variables globales duplicadas**: Variables como `elementos`, `mensajePerkTiempo`, etc. están solo en el archivo principal
3. **Eliminación de funciones duplicadas**: Funciones como `crearEfectoCuracion`, `crearEfectoExplosion`, etc. están solo en el archivo principal
4. **Corrección de referencias a colores**: Uso de `red()`, `green()`, `blue()` en lugar de `.r`, `.g`, `.b`
5. **Inicialización correcta de variables**: Todas las variables se inicializan correctamente en `inicializarJuego()`

## Requisitos
- Processing 3.x o superior
- Biblioteca Sound (incluida en Processing)

## Instalación
1. Abre Processing
2. Abre la carpeta `juegodetanquemod2` como sketch
3. Asegúrate de que la carpeta `data` contenga los archivos de audio:
   - `disparo.wav`
   - `impacto.wav`
   - `explosion.wav`
4. Ejecuta el sketch

## Cómo jugar
1. Presiona "JUGAR" en el menú principal
2. Usa WASD para moverte y el mouse para apuntar
3. Haz click para disparar
4. Recoge elementos para obtener ventajas
5. Cuando tu tanque sea destruido, completa el mini-juego de reparación
6. Sobrevive a tantas oleadas como puedas

## Tipos de enemigos
- **Normal**: Enemigo básico que dispara periódicamente
- **Kamikaze**: Se activa cuando está cerca y explota al tocar al jugador
- **Invocador**: Mantiene distancia y crea nuevos enemigos
- **Disabler**: Dispara balas ralentizantes más frecuentemente
- **Artillería**: Se posiciona en los bordes y dispara proyectiles potentes
- **Apoyo**: Cura a otros enemigos cercanos

## Elementos
- **KBOOM**: Mata a todos los enemigos en pantalla
- **One Shot**: Hace que tus disparos maten de un tiro (10 segundos)
- **Vida**: Restaura toda tu vida
- **Perk Bebida**: Otorga un perk aleatorio (Double Tap o Speed Cola) 