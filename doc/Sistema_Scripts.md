# Scripts de evento

## 1. Ejecución

`ScriptRunner` recibe una lista de `ScriptCommand`. Cada `execute` devuelve `true` si el comando terminó en el acto. Si devuelve `false`, el contexto queda en `is_waiting` y el runner no avanza hasta `on_async_complete`.

`get_inline_commands` permite que un comando se reescriba como varios antes de ejecutarse. `ScriptCmdTextFile` hace eso: lee el `.txt`, lo convierte y el runner sustituye el comando archivo por la lista resultante. Los labels se reconstruyen después de la expansión.

`jump_to_label` deja `current_index` en el índice del `ScriptCmdLabel`. El siguiente ciclo ejecuta lo que hay detrás de la etiqueta, no la etiqueta misma (su `execute` no hace nada).

El contexto guarda:

- `npc`, `player`, `map`
- `variables` locales de esta corrida (`last_choice` es una de ellas)
- `global_flags`, estático en la clase, vivo mientras el proceso exista

`find_character_by_id` recorre los grupos `npc` y `player` y compara con `get_script_id`.

## 2. Formato del archivo

UTF-8, una orden por línea. Se ignoran líneas vacías y las que empiezan por `#` o `//`. El primer token es el comando, en minúsculas. Los argumentos van separados por espacios. Un argumento con espacios se encierra en comillas. El parser no admite comillas escapadas.

```text
lock
faceplayer
text "¿Sales de viaje?" MSGBOX_YESNO
ifchoice 0 SiViaja
text "Otro día será."
release
end

label SiViaja
text "Cuídate."
release
end
```

Varias líneas `text` seguidas, sin `MSGBOX_*` ni hablante, se agrupan en un solo `ScriptCmdText` de varias páginas. En cuanto una línea trae msgbox o un id de hablante, se corta el grupo y esa línea sale como comando propio.

## 3. Comandos con efecto

| Comando | Efecto |
|---|---|
| `text "..." [MSGBOX_*] [speaker_id]` | Muestra páginas. Ver sección 4. |
| `multichoice "pregunta" "A" "B"` | Un texto y una choice por argumento extra. El índice queda en `last_choice`. |
| `label nombre` | Marca. |
| `goto nombre` | Salta. |
| `ifchoice esperado etiqueta` | Si `last_choice` como string es igual a `esperado`, salta. `0` es la primera opción. |
| `ifflag nombre etiqueta` | Salta si el flag global es verdadero. |
| `setflag nombre` / `clearflag nombre` | Escribe el flag global. |
| `faceplayer` | El NPC ejecuta `face_towards` hacia el jugador. |
| `lock` / `release` | `player.set_script_locked`. No pausa la ruta del NPC; eso ya ocurrió al iniciar el script. |
| `waitbutton` | Espera A. |
| `fadeout [seg]` / `fadein [seg]` | `FadeScreen`. Asíncrono. |
| `weather nombre` | `WeatherManager`. |
| `end` / `return` | Termina el runner. |

## 4. Msgbox

El segundo argumento de `text`, si está en `ScriptTextParser.MSGBOX_MAP`:

| Token | Efecto |
|---|---|
| `MSGBOX_YESNO` | Choices `Sí` y `No`. Índice en `last_choice`. |
| `MSGBOX_SIGN` | Sin caja de nombre. |
| `MSGBOX_NPC`, `MSGBOX_DEFAULT`, `MSGBOX_AUTOCLOSE`, `MSGBOX_GETINPUT` | Se aceptan. No cambian el comando, salvo que un tercer token se tome como `speaker_id`. `AUTOCLOSE` no cierra solo. `GETINPUT` no abre el teclado de nombre. |

Si el segundo argumento no es un msgbox, se interpreta como id de personaje y `ScriptCmdText` resuelve el nombre con `get_display_name` o con `data.name`.

## 5. Comandos reconocidos y sin implementación

El parser los acepta para no romper archivos de Essentials, y `_create` emite un warning y devuelve `null`. El runner se salta los huecos nulos.

`applymovement`, `moveplayer`, `giveitem`, `sound`, `warp`, `checkitem`, `compare`, `savegame`, `trainerbattle`.

Hasta que cada uno tenga factory, un script que dependa de ellos no hace esa línea.

## 6. Añadir un comando

1. Meter el nombre en `ScriptTextParser.COMANDOS_VALIDOS`.
2. Añadir una rama en `ScriptCmdTextFile._create` que delegue en un `_cmd_*` pequeño.
3. El `execute` del comando nuevo calcula o llama a un servicio. No instancia UI si ya existe un servicio para eso.
