
# Sistema de Personajes

## 1. Descripción general

El sistema de personajes está diseñado para separar las diferentes responsabilidades que intervienen en la representación y control de un personaje dentro del mundo.

El sistema se divide en varias capas:

```text
CharacterBase / PlayerData
		│
		│ Datos del personaje
		▼
	 Character
		│
		│ Representación visual
		▼
CharacterAnimatedController
		│
		│ Animaciones
		│
		├─────────────────────┐
		│                     │
		▼                     ▼
CharacterStates       CharacterController
		│                     │
		│ Estado              │ Movimiento/Input
		│                     │
		└──────────┬──────────┘
				   ▼
				Player
```

Cada componente tiene una responsabilidad específica y no debe asumir las responsabilidades de los demás.

---

# 2. `CharacterBase`

```gdscript
class_name CharacterBase
extends Resource
```

`CharacterBase` representa los **datos básicos de un personaje**.

No controla movimiento, animaciones ni lógica de juego. Su función es almacenar información que puede ser utilizada por los diferentes sistemas.

## Propiedades

### `id`

```gdscript
@export var id: StringName = ""
```

Identificador único del personaje.

Se utiliza para diferenciar personajes dentro del juego.

---

### `ow`

```gdscript
@export var ow: EventObjects.Obj_Event = EventObjects.Obj_Event.NONE
```

Identifica el gráfico de overworld que debe utilizar el personaje.

El valor corresponde al enum `EventObjects.Obj_Event`.

Ejemplo:

```text
OBJ_EVENT_GFX_KAEL_EB
OBJ_EVENT_GFX_KAIDA_EB
OBJ_EVENT_GFX_RED_FRLG
```

El sistema posteriormente utiliza este identificador para obtener la ruta del sprite correspondiente.

---

### `name`

```gdscript
@export var name: String
```

Nombre del personaje.

---

### `money`

```gdscript
@export var money: int = 0
```

Cantidad de dinero asociada al personaje.

---

### `shadow_type`

```gdscript
@export var shadow_type: shadow = shadow.NONE
```

Determina el tipo de sombra que tendrá el personaje.

Los tipos disponibles son:

```gdscript
enum shadow {
	NONE,
	S,
	M,
	L,
	XL
}
```

---

### `shadow_coor`

```gdscript
@export var shadow_coor: Vector2
```

Coordenadas destinadas a controlar la posición de la sombra.

Actualmente el dato se almacena, pero la implementación visual de esta coordenada queda para una etapa posterior.

---

## 2.1. Sistema de sombras

Las sombras están asociadas mediante un diccionario:

```gdscript
const shadow_sprites: Dictionary = {
	shadow.NONE: "",
	shadow.S: "res://assets/object_events/shadow/shadow_small.png",
	shadow.M: "res://assets/object_events/shadow/shadow_medium.png",
	shadow.L: "res://assets/object_events/shadow/shadow_large.png",
	shadow.XL: "res://assets/object_events/shadow/shadow_extra_large.png"
}
```

Esto permite que `Character` determine automáticamente qué textura utilizar sin que `CharacterBase` tenga que cargar directamente las imágenes.

---

# 3. `PlayerData`

```gdscript
class_name PlayerData
extends CharacterBase
```

`PlayerData` hereda de `CharacterBase` y representa los datos específicos del jugador.

Actualmente añade:

```gdscript
@export var walk: float = 0.0
@export var running: float = 0.0
```

Estos valores están destinados a almacenar información relacionada con las capacidades o estadísticas de movimiento del jugador.

La separación permite que `CharacterBase` contenga los datos comunes a todos los personajes, mientras que `PlayerData` puede contener información exclusiva del jugador.

Conceptualmente:

```text
CharacterBase
├── NPC
├── Entrenador
├── Personaje
└── PlayerData
	  ├── walk
	  └── running
```

---

# 4. `EventObjects`

```gdscript
extends Node
class_name EventObjects
```

`EventObjects` funciona como catálogo de los gráficos asociados a los personajes del overworld.

## 4.1. Enum `Obj_Event`

```gdscript
enum Obj_Event {
	NONE,
	OBJ_EVENT_GFX_PROF_OAK,

	# Valtherion
	OBJ_EVENT_GFX_KAEL_EB,
	OBJ_EVENT_GFX_KAIDA_EB,

	# Kanto
	OBJ_EVENT_GFX_RED_FRLG,
	OBJ_EVENT_GFX_LEAF_FRLG,

	# Johto
	OBJ_EVENT_GFX_ECO_HGSS,
	OBJ_EVENT_GFX_CRISTI_GPC,
	OBJ_EVENT_GFX_LYRA_HGSS,

	# Hoenn
	OBJ_EVENT_GFX_BRUNO_RSB,
	OBJ_EVENT_GFX_AURA_RSB,

	# Sinnoh
	OBJ_EVENT_GFX_LEON_DP,
	OBJ_EVENT_GFX_MAYA_DP,

	# Unova
	OBJ_EVENT_GFX_LUCHO_BW,
	OBJ_EVENT_GFX_LIZA_BW,
	OBJ_EVENT_GFX_RISSO_B2W2,
	OBJ_EVENT_GFX_NANCI_B2W2,
}
```

El enum proporciona un identificador común para los diferentes gráficos.

Esto evita almacenar directamente rutas de archivos dentro de `CharacterBase`.

---

# 4.2. Diccionario `ow_sprites`

```gdscript
const ow_sprites: Dictionary = {
	...
}
```

Relaciona cada `Obj_Event` con la textura del personaje en el overworld.

Ejemplo:

```text
OBJ_EVENT_GFX_KAEL_EB
		↓
res://game/assets/object_events/player/male/kael/normal.png
```

Por lo tanto:

```text
CharacterBase.ow
		↓
EventObjects.ow_sprites
		↓
Ruta del sprite
		↓
Texture2D
		↓
Character
```

---

# 4.3. Diccionario `trainer_sprites`

```gdscript
const trainer_sprites: Dictionary = {
	...
}
```

Relaciona los mismos identificadores `Obj_Event` con sus sprites de entrenador.

Esto permite que un mismo personaje tenga diferentes representaciones dependiendo del contexto.

Por ejemplo:

```text
Kael
│
├── Overworld
│   └── normal.png
│
└── Trainer
	└── Kael.png
```

Esto mantiene separado el gráfico del overworld del gráfico utilizado durante una batalla.

---

# 5. `Character`

```gdscript
@tool
extends Node
class_name Character
```

`Character` es responsable de la **representación visual del personaje**.

No controla:

- movimiento;
- input;
- estados;
- velocidad;
- colisiones;
- dirección lógica.

Su responsabilidad es transformar los datos de `CharacterBase` en elementos visuales.

Su estructura esperada es:

```text
Character
├── Sprite
└── Shadow
```

Donde:

```text
Sprite  → AnimatedSprite2D
Shadow  → Sprite2D
```

---

# 5.1. Datos del personaje

```gdscript
@export var data: CharacterBase
```

`Character` recibe una instancia de `CharacterBase`.

Cuando cambia:

```gdscript
data = value
```

se ejecuta:

```gdscript
update_character()
```

Esto permite actualizar automáticamente la representación visual cuando cambia el recurso asociado.

---

# 5.2. Referencias visuales

```gdscript
@onready var OwSprite: AnimatedSprite2D = $Sprite
@onready var ShadowSprite: Sprite2D = $Shadow
```

`OwSprite` contiene las animaciones del personaje.

`ShadowSprite` contiene la sombra.

---

# 5.3. Detección de cambios en el editor

El nodo utiliza:

```gdscript
@tool
```

para permitir que el sistema también funcione dentro del editor.

Se almacenan los últimos valores utilizados:

```gdscript
var _last_ow: EventObjects.Obj_Event = EventObjects.Obj_Event.NONE
var _last_shadow: CharacterBase.shadow = CharacterBase.shadow.NONE
```

Durante `_process()` se comprueba si cambiaron:

```text
data.ow
data.shadow_type
```

Si alguno cambió, se ejecuta:

```gdscript
update_character()
```

Esto permite modificar el personaje desde el inspector y visualizar inmediatamente el resultado.

---

# 5.4. `update_character()`

Esta función actualiza la representación visual completa.

Primero obtiene la ruta del overworld:

```gdscript
var ow_path: String = EventObjects.ow_sprites.get(data.ow, "")
```

Después carga la textura:

```gdscript
var texture: Texture2D = load(ow_path)
```

y la entrega a:

```gdscript
update_ow_sprite(texture)
```

Posteriormente obtiene la textura de sombra:

```gdscript
var shadow_path: String = CharacterBase.shadow_sprites.get(data.shadow_type, "")
```

Si existe una ruta válida:

```gdscript
ShadowSprite.texture = load(shadow_path)
```

En caso contrario:

```gdscript
ShadowSprite.texture = null
```

Finalmente se actualizan los valores utilizados como referencia:

```gdscript
_last_ow = data.ow
_last_shadow = data.shadow_type
```

---

# 5.5. Construcción de las animaciones desde el spritesheet

El spritesheet utilizado tiene la siguiente estructura:

```text
			 COLUMNAS
		  0       1       2
	   ┌───────┬───────┬───────┐
Down   │ First │ Idle  │Second │
	   ├───────┼───────┼───────┤
Up     │ First │ Idle  │Second │
	   ├───────┼───────┼───────┤
Left   │ First │ Idle  │Second │
	   ├───────┼───────┼───────┤
Right  │ First │ Idle  │Second │
	   └───────┴───────┴───────┘
```

Por lo tanto:

```text
3 columnas
4 filas
```

Cada frame se obtiene dividiendo el tamaño total de la textura:

```gdscript
var frame_size: Vector2 = texture.get_size() / Vector2(3, 4)
```

---

# 5.6. Direcciones

Las filas se interpretan mediante:

```gdscript
var directions: Dictionary = {
	"Down": 0,
	"Up": 1,
	"Left": 2,
	"Right": 3
}
```

Por tanto:

```text
Fila 0 → Down
Fila 1 → Up
Fila 2 → Left
Fila 3 → Right
```

---

# 5.7. Pasos

Las columnas se interpretan mediante:

```gdscript
var steps: Dictionary = {
	"First_Step": 0,
	"Idle": 1,
	"Second_Step": 2
}
```

Por tanto:

```text
Columna 0 → First_Step
Columna 1 → Idle
Columna 2 → Second_Step
```

---

# 5.8. Animaciones resultantes

El sistema genera nombres como:

```text
First_Step_Down
First_Step_Up
First_Step_Left
First_Step_Right

Idle_Down
Idle_Up
Idle_Left
Idle_Right

Second_Step_Down
Second_Step_Up
Second_Step_Left
Second_Step_Right
```

Las animaciones de paso contienen dos frames:

```text
First_Step:
	frame 0 → posición inicial
	frame 1 → Idle

Second_Step:
	frame 0 → posición final
	frame 1 → Idle
```

Las animaciones `Idle` contienen solamente el frame central.

---

# 5.9. `play_animation()`

```gdscript
func play_animation(animation_name: String) -> void:
	OwSprite.play(animation_name)
```

Esta función constituye la interfaz que utilizan otros sistemas para solicitar una animación.

`Character` no decide cuándo caminar ni qué animación corresponde.

Simplemente reproduce la animación solicitada.

---

# 6. `CharacterAnimatedController`

```gdscript
class_name CharacterAnimatedController
extends Node2D
```

`CharacterAnimatedController` es responsable exclusivamente de la **lógica de animación del personaje**.

No controla:

- input;
- movimiento;
- velocidad;
- posición;
- colisiones;
- estados de gameplay.

Su función es traducir una orden abstracta como:

```gdscript
play_step_animation(Vector2.RIGHT)
```

en una animación concreta:

```text
First_Step_Right
```

o:

```text
Second_Step_Right
```

---

# 6.1. Contador de pasos

```gdscript
var step: int = 0
```

El contador determina qué pierna/pose corresponde al siguiente paso.

La lógica es:

```gdscript
if step % 2 == 1:
	First_Step
else:
	Second_Step
```

Por lo tanto:

```text
Paso 1 → First_Step
Paso 2 → Second_Step
Paso 3 → First_Step
Paso 4 → Second_Step
...
```

---

# 6.2. `AnimStates`

El enum contiene todos los estados visuales posibles:

```text
IDLE_DOWN
IDLE_UP
IDLE_LEFT
IDLE_RIGHT

FIRST_STEP_DOWN
FIRST_STEP_UP
FIRST_STEP_LEFT
FIRST_STEP_RIGHT

SECOND_STEP_DOWN
SECOND_STEP_UP
SECOND_STEP_LEFT
SECOND_STEP_RIGHT
```

El enum permite trabajar con estados internos sin depender directamente de strings.

---

# 6.3. Diccionario `Anim`

El diccionario transforma los estados internos en los nombres reales de las animaciones:

```text
AnimStates.FIRST_STEP_DOWN
		↓
"First_Step_Down"
```

Esto separa la lógica de selección de animación de los nombres utilizados por `AnimatedSprite2D`.

---

# 6.4. Animación de caminata

La entrada principal es:

```gdscript
func play_step_animation(direction: Vector2)
```

Cada vez que se solicita un paso:

```gdscript
step += 1
```

Después se determina si corresponde `First_Step` o `Second_Step`.

Finalmente se solicita a `Character` que reproduzca la animación:

```gdscript
character.play_animation(...)
```

El flujo es:

```text
CharacterController
		│
		│ "comienza un paso hacia la derecha"
		▼
CharacterAnimatedController
		│
		├── incrementa step
		├── determina First/Second
		├── determina dirección
		▼
Character
		│
		▼
AnimatedSprite2D
```

---

# 6.5. Animación Idle

La función:

```gdscript
play_idle_animation(direction)
```

reproduce la pose estática correspondiente a la dirección.

Ejemplo:

```text
Vector2.DOWN
	↓
Idle_Down

Vector2.LEFT
	↓
Idle_Left
```

El `CharacterAnimatedController` no decide cuándo el personaje debe estar en Idle.

Solamente proporciona la función necesaria para reproducir dicha animación.

---

# 7. `CharacterController`

```gdscript
class_name CharacterController
extends Node2D
```

`CharacterController` es responsable del **movimiento lógico y físico del personaje**.

Entre sus responsabilidades se encuentran:

- leer el input;
- determinar la dirección;
- controlar los giros;
- iniciar movimientos;
- realizar el desplazamiento suave;
- finalizar movimientos;
- encadenar movimientos;
- mantener la posición en la cuadrícula;
- comunicarse con `CharacterAnimatedController`.

No es responsable de construir las animaciones.

---

# 7.1. Parámetros del movimiento

```gdscript
const TILE_SIZE: float = 16.0
const MOVE_SPEED: float = 64.0
const HOLD_THRESHOLD: float = 0.12
```

## `TILE_SIZE`

Define el tamaño lógico de una casilla:

```text
16 × 16 píxeles
```

Cada movimiento corresponde actualmente a un desplazamiento de 16 píxeles.

---

## `MOVE_SPEED`

Define la velocidad del desplazamiento.

Con:

```text
64 px/s
```

y:

```text
16 px por movimiento
```

un movimiento completo tarda aproximadamente:

```text
16 / 64 = 0.25 segundos
```

---

## `HOLD_THRESHOLD`

Define cuánto tiempo debe mantenerse una dirección antes de iniciar automáticamente un movimiento cuando el personaje está esperando después de un toque.

Actualmente:

```text
0.12 segundos
```

Este umbral **no se utiliza entre movimientos continuos**.

---

# 7.2. Posiciones

El controlador utiliza tres posiciones:

```gdscript
var current_position: Vector2
var initial_position: Vector2
var target_position: Vector2
```

### `current_position`

Representa la posición lógica actual después de completar un movimiento.

### `initial_position`

Representa el punto desde donde comenzó el movimiento actual.

### `target_position`

Representa el destino del movimiento actual.

Conceptualmente:

```text
initial_position
	   │
	   │ movimiento
	   ▼
target_position
```

---

# 7.3. Estado de movimiento

```gdscript
var moving: bool = false
```

Indica si el personaje está actualmente desplazándose entre dos casillas.

Esta variable es fundamental.

Mientras:

```gdscript
moving == true
```

el controlador **no vuelve a interpretar el input para cancelar el movimiento actual**.

El movimiento debe terminar.

---

# 7.4. Dirección

```gdscript
var direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
```

### `direction`

Representa la dirección del movimiento actual.

### `last_direction`

Representa la última dirección conocida del personaje y se utiliza para mantener la orientación cuando queda detenido.

Por defecto:

```text
Down
```

---

# 7.5. Progreso del movimiento

```gdscript
var move_progress: float = 0.0
```

Representa cuánto ha avanzado el movimiento actual:

```text
0.0 → comienzo
0.5 → mitad
1.0 → final
```

Esto permite realizar un desplazamiento suave mediante interpolación.

---

# 7.6. Sistema de espera

El controlador utiliza:

```gdscript
var input_direction: Vector2 = Vector2.ZERO
var hold_time: float = 0.0
var waiting_for_move: bool = false
```

Estos valores permiten diferenciar entre:

```text
Toque rápido
```

y:

```text
Mantener pulsada una dirección
```

---

# 8. Inicialización

En `_ready()`:

```gdscript
character.global_position = snap_to_grid(character.global_position)
```

La posición inicial se ajusta a la cuadrícula.

Posteriormente se inicializan:

```gdscript
current_position
initial_position
target_position
```

con la posición actual del personaje.

Esto garantiza que el personaje comience correctamente alineado con el grid.

---

# 9. Procesamiento del movimiento

La función principal es:

```gdscript
process_movement(delta)
```

Su prioridad es:

```text
¿Está moviéndose?
		│
	   Sí
		↓
process_move()

	   No
		│
		▼
¿Está esperando una pulsación?
		│
	   Sí
		↓
process_input_hold()

	   No
		│
		▼
process_input()
```

Esta prioridad es importante.

Un movimiento iniciado tiene prioridad sobre cualquier nuevo input.

---

# 10. Interpretación del input

`process_input()` obtiene la dirección actual:

```gdscript
var new_direction: Vector2 = get_direction()
```

Si no existe input:

```text
Vector2.ZERO
```

no ocurre nada.

---

# 10.1. Primer toque en una dirección diferente

Si:

```gdscript
new_direction != last_direction
```

el personaje interpreta la acción inicialmente como un giro.

Se actualiza:

```gdscript
direction = new_direction
last_direction = new_direction
```

y se comienza el período de espera:

```gdscript
hold_time = 0.0
waiting_for_move = true
```

Además se reproduce inmediatamente la animación de paso:

```gdscript
animation_controller.play_step_animation(direction)
```

En este momento:

```text
NO se mueve físicamente.
```

El objetivo es permitir que un toque rápido funcione como giro.

---

# 10.2. Segundo toque en la misma dirección

Si la dirección coincide con la dirección actual, se inicia directamente:

```gdscript
start_move()
```

Esto permite:

```text
Primer toque → girar
Segundo toque → caminar
```

---

# 11. Espera después del primer toque

`process_input_hold()` controla el período en el que el personaje está esperando para determinar si el jugador:

```text
tocó
```

o:

```text
mantuvo presionado
```

---

## 11.1. Liberar el botón

Si:

```gdscript
current_direction == Vector2.ZERO
```

se cancela la espera:

```gdscript
waiting_for_move = false
hold_time = 0.0
```

El resultado es:

```text
Toque rápido
→ cambia dirección
→ reproduce animación
→ no camina
```

---

## 11.2. Cambiar de dirección durante la espera

Si el jugador cambia de dirección antes de alcanzar el umbral:

```gdscript
current_direction != input_direction
```

se actualiza la nueva dirección.

También se reinicia:

```gdscript
hold_time = 0.0
```

y se reproduce la nueva animación de paso.

Esto permite cambiar de orientación sin iniciar inmediatamente el movimiento.

---

## 11.3. Mantener la misma dirección

Mientras el jugador mantenga la misma dirección:

```gdscript
hold_time += delta
```

Cuando:

```gdscript
hold_time >= HOLD_THRESHOLD
```

se inicia:

```gdscript
start_move()
```

Por tanto:

```text
Mantener dirección
		↓
0.12 s
		↓
Movimiento
```

---

# 12. Inicio de un movimiento

`start_move()` prepara un nuevo desplazamiento.

Primero se establece el origen:

```gdscript
initial_position = character.global_position
```

Después se calcula el destino:

```gdscript
target_position = initial_position + direction * TILE_SIZE
```

Con un tile de 16 píxeles:

```text
DOWN  → +16 Y
UP    → -16 Y
LEFT  → -16 X
RIGHT → +16 X
```

Se reinicia el progreso:

```gdscript
move_progress = 0.0
```

y se marca:

```gdscript
moving = true
```

Finalmente se reproduce la animación correspondiente:

```gdscript
animation_controller.play_step_animation(direction)
```

---

# 13. Movimiento suave

`process_move(delta)` actualiza progresivamente el movimiento.

El progreso aumenta mediante:

```gdscript
move_progress += (MOVE_SPEED * delta) / TILE_SIZE
```

Después se limita:

```gdscript
move_progress = min(move_progress, 1.0)
```

La posición se calcula mediante interpolación:

```gdscript
character.global_position = initial_position.lerp(
	target_position,
	move_progress
)
```

Por tanto:

```text
0.0
 ↓
posición inicial

0.5
 ↓
mitad del tile

1.0
 ↓
posición objetivo
```

No es necesario definir manualmente un estado para:

```text
inicio
mitad
final
```

porque la interpolación produce naturalmente todo el desplazamiento intermedio.

---

# 14. Finalización de un movimiento

Cuando:

```gdscript
move_progress >= 1.0
```

el personaje alcanza definitivamente:

```gdscript
character.global_position = target_position
```

La posición lógica se actualiza:

```gdscript
current_position = target_position
```

y:

```gdscript
moving = false
```

El movimiento actual ha terminado.

---

# 15. Movimiento continuo

Una característica importante del sistema es que los movimientos pueden encadenarse.

Después de terminar un movimiento:

```gdscript
var next_direction: Vector2 = get_direction()
```

Si existe una dirección:

```gdscript
if next_direction != Vector2.ZERO:
```

se actualiza:

```gdscript
direction = next_direction
last_direction = next_direction
```

y se inicia inmediatamente:

```gdscript
start_move()
```

Por lo tanto:

```text
→ → → → →
```

se ejecuta sin pausas artificiales.

---

# 16. Cambio de dirección durante movimiento continuo

El sistema también permite cambiar de dirección mientras el personaje todavía está desplazándose.

Por ejemplo:

```text
→ → → ↓
```

Si el jugador comienza a mantener `DOWN` durante el movimiento hacia la derecha, el movimiento actual **no se interrumpe**.

Primero:

```text
→
```

termina completamente.

Después se obtiene:

```text
DOWN
```

y comienza inmediatamente el siguiente movimiento:

```text
↓
```

No se aplica:

```text
HOLD_THRESHOLD
```

en este caso.

La regla es:

> El umbral sirve para distinguir un toque de un movimiento iniciado desde una posición estacionaria. No se utiliza para encadenar movimientos.

---

# 17. Obtención de dirección

`get_direction()` traduce el input del jugador a un `Vector2`.

```text
Up    → Vector2.UP
Down  → Vector2.DOWN
Left  → Vector2.LEFT
Right → Vector2.RIGHT
```

Actualmente se comprueban en este orden:

```text
Up
Down
Left
Right
```

Si ninguna está presionada:

```gdscript
Vector2.ZERO
```

---

# 18. Cuadrícula

La función:

```gdscript
snap_to_grid(position)
```

alinea una posición con el tamaño del tile.

Con:

```text
TILE_SIZE = 16
```

una posición se redondea a múltiplos de 16:

```text
0
16
32
48
64
...
```

Esto garantiza que los personajes permanezcan alineados con la cuadrícula.

---

# 19. `CharacterStates`

```gdscript
class_name CharacterStates
extends Node
```

`CharacterStates` representa la **máquina de estados de alto nivel del personaje**.

Actualmente existen:

```gdscript
enum State {
	IDLE,
	WALK,
	RUN,
}
```

Su responsabilidad no es mover directamente al personaje.

Su responsabilidad es determinar en qué estado conceptual se encuentra.

---

# 19.1. Estados

### `IDLE`

El personaje está detenido.

### `WALK`

El personaje está realizando o intentando realizar desplazamientos normales.

### `RUN`

Estado reservado para el futuro sistema de carrera.

Actualmente:

```gdscript
func run(_delta: float) -> void:
	pass
```

---

# 19.2. Estado actual y anterior

```gdscript
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
```

Se utilizan para detectar cambios de estado.

---

# 19.3. `process_state()`

Cada frame de física se ejecuta:

```gdscript
state.process_state(delta)
```

La función determina qué comportamiento corresponde:

```text
IDLE → idle()
WALK → walk()
RUN  → run()
```

Después comprueba:

```gdscript
if current_state != previous_state
```

para ejecutar:

```gdscript
on_state_changed()
```

---

# 20. Estado `IDLE`

La función:

```gdscript
idle()
```

comprueba si existe input.

Si existe:

```gdscript
change_state(State.WALK)
```

Si no existe:

```gdscript
animation_controller.play_idle_animation(
	controller.last_direction
)
```

Esto mantiene al personaje mirando hacia su última dirección conocida.

---

# 21. Estado `WALK`

`walk()` tiene una consideración especialmente importante:

```gdscript
if controller.moving:
	return
```

Esto evita que el estado cambie inmediatamente a `IDLE` mientras el controlador todavía está terminando un movimiento.

Por ejemplo:

```text
Jugador suelta botón
		↓
CharacterStates podría detectar ZERO
		↓
Pero CharacterController.moving == true
		↓
El movimiento continúa
```

Cuando el movimiento termina y no existe input:

```gdscript
change_state(State.IDLE)
```

---

# 22. Separación entre estado y movimiento

El sistema establece deliberadamente esta separación:

```text
CharacterStates
	│
	└── ¿Qué estado tiene el personaje?

CharacterController
	│
	└── ¿Cómo se mueve el personaje?
```

Esto permite que ambas cosas no estén obligatoriamente sincronizadas durante cada frame.

Por ejemplo:

```text
current_state = IDLE
moving = true
```

puede existir temporalmente.

Esto no es un error.

Significa:

> El personaje ya no está recibiendo una orden de caminar, pero todavía está terminando el desplazamiento que había comenzado.

---

# 23. `Player`

El nodo `Player` funciona como punto de coordinación.

Sus referencias principales son:

```gdscript
@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
```

En cada frame de física:

```gdscript
func _physics_process(delta: float) -> void:
	state.process_state(delta)
	controller.process_movement(delta)
```

Los dos sistemas se procesan independientemente.

Esto es importante porque:

```text
CharacterStates
```

no controla directamente:

```text
CharacterController
```

y el controlador continúa funcionando aunque el estado cambie.

---

# 24. Flujo completo de una pulsación

## Caso A — toque para girar

```text
Jugador presiona RIGHT
		↓
CharacterController
		↓
get_direction()
		↓
RIGHT != last_direction
		↓
actualiza dirección
		↓
waiting_for_move = true
		↓
play_step_animation(RIGHT)
		↓
Personaje gira
		↓
Jugador suelta
		↓
No hay movimiento
```

---

# 25. Caso B — segundo toque

```text
Jugador vuelve a presionar RIGHT
		↓
get_direction()
		↓
RIGHT == last_direction
		↓
start_move()
		↓
moving = true
		↓
Interpolación 16 px
		↓
Movimiento terminado
```

---

# 26. Caso C — mantener una dirección

```text
Jugador mantiene RIGHT
		↓
waiting_for_move
		↓
hold_time aumenta
		↓
hold_time >= 0.12
		↓
start_move()
		↓
Movimiento
		↓
RIGHT sigue presionado
		↓
start_move()
		↓
Movimiento
		↓
RIGHT sigue presionado
		↓
...
```

No existe un nuevo `HOLD_THRESHOLD` entre los movimientos.

---

# 27. Caso D — soltar durante un movimiento

```text
Jugador mantiene RIGHT
		↓
start_move()
		↓
moving = true
		↓
Jugador suelta RIGHT
		↓
get_direction() = ZERO
		↓
El movimiento actual NO se cancela
		↓
El personaje termina sus 16 px
		↓
moving = false
		↓
No comienza otro movimiento
		↓
IDLE
```

Esta es una de las reglas fundamentales del sistema.

---

# 28. Caso E — cambiar de dirección durante movimiento

```text
RIGHT
  ↓
movimiento en curso
  ↓
jugador mantiene DOWN
  ↓
el movimiento RIGHT continúa
  ↓
llega al siguiente tile
  ↓
get_direction() = DOWN
  ↓
start_move(DOWN)
  ↓
movimiento DOWN inmediatamente
```

No se vuelve a aplicar:

```text
HOLD_THRESHOLD
```

---

# 29. Relación entre movimiento y animación

El controlador de movimiento no decide qué animación concreta debe reproducirse.

Solamente informa:

```gdscript
animation_controller.play_step_animation(direction)
```

Por ejemplo:

```text
CharacterController
		│
		│ play_step_animation(Vector2.RIGHT)
		▼
CharacterAnimatedController
		│
		├── step = 1
		├── determina First_Step
		└── determina Right
		▼
"First_Step_Right"
		│
		▼
Character.play_animation()
		│
		▼
AnimatedSprite2D
```

La siguiente orden de movimiento producirá:

```text
Second_Step_Right
```

y posteriormente:

```text
First_Step_Right
```

creando el ciclo visual de caminata.

---

# 30. Responsabilidades definitivas

| Clase | Responsabilidad |
|---|---|
| `CharacterBase` | Datos generales del personaje |
| `PlayerData` | Datos específicos del jugador |
| `EventObjects` | Identificadores y recursos gráficos |
| `Character` | Representación visual |
| `CharacterAnimatedController` | Selección y reproducción de animaciones |
| `CharacterController` | Input y movimiento |
| `CharacterStates` | Estados de alto nivel |
| `Player` | Coordinación de los sistemas |

---

# 31. Reglas de diseño del sistema

Estas reglas deben conservarse al ampliar el sistema.

### Regla 1 — `Character` no mueve al personaje

Su responsabilidad es visual.

### Regla 2 — `CharacterAnimatedController` no mueve al personaje

Solo administra animaciones.

### Regla 3 — `CharacterStates` no mueve físicamente al personaje

Determina el estado conceptual.

### Regla 4 — `CharacterController` controla el movimiento

El desplazamiento lógico y físico pertenece al controlador.

### Regla 5 — un movimiento iniciado debe terminar

Liberar una tecla no cancela un movimiento de 16 px que ya comenzó.

### Regla 6 — el movimiento es suave

No se realizan saltos instantáneos entre casillas.

### Regla 7 — el movimiento continuo no tiene pausas artificiales

Mientras exista una dirección válida, los movimientos se encadenan.

### Regla 8 — cambiar de dirección durante movimiento continuo no requiere umbral

El siguiente movimiento comienza inmediatamente después de terminar el actual.

### Regla 9 — `HOLD_THRESHOLD` solo se utiliza para iniciar movimiento desde espera

No debe convertirse en una pausa entre tiles.

### Regla 10 — el controlador se procesa independientemente del estado

`process_movement(delta)` debe ejecutarse en cada frame de física.

---

# 32. Arquitectura actual

La arquitectura actual puede resumirse así:

```text
						 DATOS
						   │
			 ┌─────────────┴─────────────┐
			 │                           │
	   CharacterBase                 PlayerData
			 │
			 ▼
		 Character
		┌────┴────┐
		│         │
	 Sprite     Shadow
		│
		▼
AnimatedSprite2D


					CONTROL
					   │
		  ┌────────────┴────────────┐
		  │                         │
 CharacterStates             CharacterController
		  │                         │
		  │                         ├── Input
		  │                         ├── Dirección
		  │                         ├── Movimiento
		  │                         ├── Grid
		  │                         └── Velocidad
		  │
		  ▼
 CharacterAnimatedController
		  │
		  ▼
	  Character
		  │
		  ▼
   AnimatedSprite2D
```

---

# 33. Estado actual del sistema

Actualmente el sistema ya posee una base funcional para:

- representación de personajes;
- selección de sprites;
- sombras;
- construcción automática de animaciones desde spritesheets;
- orientación;
- animación Idle;
- animación de pasos alternados;
- movimiento basado en grid;
- movimiento suave;
- detección de pulsaciones;
- distinción entre toque y pulsación mantenida;
- movimiento continuo;
- cambio de dirección durante movimiento continuo;
- finalización obligatoria de movimientos iniciados;
- máquina de estados básica;
- separación entre datos, visuales, animación, movimiento y estados.

Quedan como extensiones futuras, entre otras:

```text
Colisiones
Restricciones de movimiento
Interacción con objetos
NPCs
Pathfinding
Correr
Animaciones especiales
Movimiento forzado
Eventos
Warp/teletransporte
Bicicleta
Surf
Escaleras
Puertas
Animaciones contextuales
```

Estas funcionalidades deberán integrarse respetando la separación de responsabilidades establecida en esta documentación.
