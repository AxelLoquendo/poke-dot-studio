# Sistema de mensajes

Cajas de texto estilo Pokémon Essentials (viewport 512×384, fuente Power Green, windowskins del proyecto).

## 1. Capas de responsabilidad

| Pieza | Rol |
|---|---|
| `MessageConfig` | Constantes: fuentes, colores, layout, rutas de skin |
| `MessageService` | API para scripts (`show_texts`, choices). No pinta |
| `MessageUI` | Orquesta ventanas en un `CanvasLayer` |
| `MessageWindow` | Caja principal + typewriter + pause arrow |
| `NameWindow` | Placa de nombre del hablante |
| `ChoiceWindow` | Lista Sí/No o multichoice + flecha de selección |
| `PeWindowSkin` | Márgenes nine-patch según formato PE del PNG |

## 2. Skins

- Diálogo: `assets/window_skins/speech hgss 1.png` (u otra speech configurada).
- Choices: `assets/window_skins/choice 1.png`.
- Flecha de pausa: atlas por frames (no el spritesheet completo).
- Flecha de selección: `assets/ui/sel_arrow.png`.

## 3. Texto

- Typewriter con velocidades PE (`TEXT_SPEED_MEDIUM` = 2/80 s, etc.).
- Sombra de letra solo en **Y** (offset X = 0).
- El texto de la caja principal vive en el área blanca del nine-patch (clip / márgenes de skin).

## 4. Integración con scripts

`ScriptCmdText` usa `MessageService`. `MSGBOX_YESNO` rellena choices Sí/No. El índice queda en la variable de contexto `last_choice` para `ifchoice`.

Mientras hay mensaje activo, el player no procesa movimiento ni A de interacción (`MessageService.is_active()`). El cartel de ubicación también se cierra si hay mensaje.
