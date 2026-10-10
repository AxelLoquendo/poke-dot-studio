# Mensajes

## 1. Reparto

`MessageService` es el autoload que ven los scripts. Expone `show_text`, `show_pages` y `show_texts`, y reemite `message_finished` y `choice_selected`. No crea nodos.

`MessageUI` (capa 95, `PROCESS_MODE_ALWAYS`) posee tres vistas y el estado de páginas:

- `MessageWindow`, caja inferior.
- `NameWindow`, placa de hablante.
- `ChoiceWindow`, lista Sí/No u otras opciones.

`MessageConfig` solo tiene números: viewport 512×384, fuente `res://font/power green.ttf` a 24 px, alto de línea 32, caja de dos líneas, skins en `res://assets/window_skins/`.

## 2. Piel de ventana

Los windowskins de Essentials no usan el mismo margen en los cuatro lados. `PeWindowSkin.from_texture` lo resuelve:

- Speech de 80×48 o 96×48: margen izquierdo 32, superior 16, derecho `ancho - 48`, inferior `alto - 32`.
- Choice de 48×48: 16 en los cuatro lados.
- Cualquier otro tamaño: centro de 16 px y el resto como margen.

`apply_to` copia esos márgenes al `NinePatchRect`. La caja de nombre usa el mismo skin de speech que el diálogo. Su alto es `margen superior + margen inferior + LINE_HEIGHT`. El ancho es la suma de márgenes, el padding y el ancho medido del texto. Por eso el nombre no aplasta el marco.

## 3. Flujo de una página

`show_pages` guarda páginas, hablante y choices, y muestra la página 0.

`_show_current_page`:

1. Enseña u oculta el nombre según el hablante esté vacío.
2. `MessageWindow.display_text` reinicia el contador de caracteres.
3. Si esta es la última página y hay choices, `ChoiceWindow.show_choices` aparece en el mismo momento. No espera un A extra.

A con el texto todavía escribiéndose lo completa (`skip_typing`) y no confirma la choice. A con la choice ya visible y el texto terminado confirma. Arriba y abajo mueven el índice. El índice confirmado sale por `choice_selected` y el servicio lo guarda en `get_last_choice` antes de cerrar las tres ventanas.

Sin choices, A avanza de página y la última llamada a `_finish_all` cierra y emite `message_finished`.

## 4. Tipeo

`MessageWindow` no mezcla el reloj con los nodos. `_advance_typing` suma caracteres según `TEXT_SPEED_MEDIUM` (2/80 s por carácter, unos 40 caracteres por segundo). `_apply_visible_count` escribe ese entero en el `RichTextLabel` de texto y en el de sombra, desplazado 2 px en Y.

El color sale de `resolve_text_colors`: un pixel del centro del skin. Si la luminancia es menor que 160/255, el texto es claro. Si no, oscuro. Es una función pura. `setup` solo aplica el diccionario que devuelve.

La flecha de pausa es un atlas de 4 frames de 20×28 a 5 fps. `_advance_pause_arrow` solo corre cuando ya no se está tipeando.

## 5. Choices

`show_choices` no mide y construye en el mismo bloque:

1. `_clear_rows` destruye las filas anteriores con `free`, no con `queue_free`, para que `_refresh` no vea la flecha vieja.
2. `_measure_widest` devuelve el ancho máximo del texto.
3. `_build_rows` crea una fila por opción: slot de flecha de 16 px, siempre presente, y un `Label`.
4. `_place_window` suma márgenes del skin y se ancla a la derecha, encima de la caja. Si no cabe arriba, pasa debajo.

La flecha visible es `modulate.a` del slot seleccionado. El tamaño de la fila no cambia al mover la selección.

## 6. Lo que el jugador no puede hacer mientras hay texto

`Player._physics_process` trata `MessageService.is_active()` como un lock de input. El NPC ya está en `LOCKED` desde antes de abrir la caja.
