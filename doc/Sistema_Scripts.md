# Sistema de scripts

Formato `.txt` estilo pokeemerald / eventos de mapa. El runtime no interpreta Ruby ni GDScript embebido: solo comandos del parser.

## 1. Pipeline

```text
archivo .txt
  → ScriptTextParser.parse_script / load_script_file
  → Array de diccionarios { command, args, line }
  → ScriptCmdTextFile._convert → Array[ScriptCommand]
  → ScriptRunner.start_script(...)
```

Entradas típicas:

- NPC: `NPCData.script_file` → `ScriptCmdTextFile` al interactuar.
- `MapEvent` COORD / BG: `script_file` del evento.
- Script que hace `warp`: el runner se reparenta a `MapFactory` antes de descargar el mapa.

## 2. Contexto

`ScriptExecutionContext` lleva `npc`, `player`, `map`, `variables` locales, `runner` y flags globales estáticos (`global_flags`).

`complete_async` desbloquea el runner tras un comando que esperaba (fade, texto, wait, waitmovement, warp).

## 3. Comandos operativos

| Comando | Efecto |
|---|---|
| `text "..." [MSGBOX_*] [speaker_id]` | Páginas de mensaje. Ver `Sistema_Mensajes.md`. |
| `multichoice "pregunta" "A" "B" ...` | Texto + choices. Índice en `last_choice`. |
| `label nombre` | Marca de salto. |
| `goto nombre` | Salta a la etiqueta. |
| `ifchoice esperado etiqueta` | Si `last_choice` (string) == `esperado`, salta. `0` = primera opción. |
| `ifflag nombre etiqueta` | Salta si el flag global es verdadero. |
| `setflag nombre` / `clearflag nombre` | Escribe el flag global. |
| `setvar nombre valor` | Variable de contexto (número). |
| `addvar nombre delta` | Suma a la variable. |
| `compare nombre op valor etiqueta` | `op`: `==` `!=` `>` `<` `>=` `<=`. Si cumple, salta. |
| `faceplayer` | El NPC del contexto mira al jugador. |
| `lock` / `release` | `player.set_script_locked(true/false)`. |
| `waitbutton` | Espera A / accept. |
| `wait segundos` | Espera tiempo (float). |
| `fadeout [seg]` / `fadein [seg]` | `FadeScreen` (default 0.4). Asíncrono. |
| `weather nombre` | `WeatherManager`. |
| `sound SE_...` o `GUI_...` | `MusicManager.reproducir_se`. Prefijo `SE_` opcional. |
| `applymovement [objetivo] paso,paso,...` | Inicia ruta. Objetivo: vacío/`event`/`npc`, `player`, o id de script. |
| `moveplayer paso,paso,...` | Igual que `applymovement player ...`. |
| `waitmovement [objetivo]` | Espera `route_finished` del `MoveRouteController`. |
| `warp MAP_ID x y [dirección]` | Fade out → `MapFactory.load_cluster` → fade in. |
| `end` / `return` | Termina el runner. |

### Tokens de movimiento

`walk_up` / `up`, `walk_down` / `down`, `walk_left` / `left`, `walk_right` / `right`,  
`face_up`, `face_down`, `face_left`, `face_right`, `face_player`,  
`wait_0.5` (segundos).

Varios pasos en un argumento separados por coma: `walk_up,walk_up,face_down`.

### Warp

```text
warp MAPSEC_RUTA_1 5 10 down
warp PUEBLO_INICIO 8 12
```

El token de mapa acepta el enum con o sin prefijo `MAPSEC_`. Dirección opcional: `up` `down` `left` `right`.

## 4. Msgbox

| Token | Efecto |
|---|---|
| `MSGBOX_YESNO` | Choices `Sí` y `No`. Índice en `last_choice`. |
| `MSGBOX_SIGN` | Sin caja de nombre. |
| `MSGBOX_NPC`, `MSGBOX_DEFAULT`, `MSGBOX_AUTOCLOSE`, `MSGBOX_GETINPUT` | Se aceptan. Un tercer token puede ser `speaker_id`. |

## 5. Ejemplo

```text
lock
faceplayer
text "¿Vienes?" MSGBOX_YESNO
ifchoice 1 no
applymovement event walk_up,walk_up,face_down
applymovement player walk_up,walk_up
waitmovement event
waitmovement player
sound SE_GUI_SEL_DECISION
warp MAPSEC_RUTA_1 5 10 up
release
end

label no
text "Está bien."
release
end
```

## 6. Fuera de alcance del intérprete

`giveitem`, `checkitem`, `trainerbattle`, `savegame` no tienen factory operativo. No forman parte del overworld cerrado.
