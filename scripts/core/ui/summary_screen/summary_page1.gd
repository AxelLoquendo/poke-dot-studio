extends Node2D
class_name SummaryPage1
## Trainer Memo (PE page 2). Solo rellena textos; layout en la escena.

@onready var nature_name: Label = $Trainer_Memo/Nature/Nature_Name
@onready var fecha: Label = $Trainer_Memo/Fecha
@onready var encounter: Label = $Trainer_Memo/Encounter
@onready var encounter_info: Label = $Trainer_Memo/Encounter/Encounter_Info
@onready var personality: Label = $Trainer_Memo/Personality

const NATURE_ES: Array[String] = [
	"Fuerte", "Huraña", "Audaz", "Firme", "Pícara",
	"Osada", "Dócil", "Plácida", "Agitada", "Floja",
	"Miedosa", "Activa", "Alegre", "Ingenua", "Mansa",
	"Modesta", "Afable", "Alocada", "Tímida", "Rara",
	"Serena", "Amable", "Cauta", "Grosera", "Meticulosa",
]

# PE: characteristic por IV más alto (orden HP,Atk,Def,Spe,SpA,SpD)
const CHAR_LINES: Array = [
	["Le encanta comer.", "A menudo se duerme.", "Cabecea a menudo.", "Suele desordenar.", "Le gusta relajarse."], # HP
	["Orgulloso de su fuerza.", "Le gusta dar tortazos.", "Un poco cabezota.", "Le gusta pelear.", "Es un poco temperamental."], # Atk
	["Cuerpo resistente.", "Capaz de aguantar golpes.", "Muy persistente.", "Buena resistencia.", "Muy perseverante."], # Def
	["Le gusta correr.", "Oído alerta.", "Impetuoso y bobo.", "Es un poco payaso.", "Huye rápido."], # Spe
	["Muy curioso.", "Travieso.", "Muy astuto.", "A menudo está en las nubes.", "Muy particular."], # SpA
	["De voluntad firme.", "Un poco vanidoso.", "Muy rebelde.", "Odia perder.", "Es un poco mandón."], # SpD
]


func bind(mon: Pokemon) -> void:
	if mon == null:
		return

	if nature_name != null:
		var ni: int = int(mon.nature)
		if ni >= 0 and ni < NATURE_ES.size():
			nature_name.text = NATURE_ES[ni]
		else:
			nature_name.text = str(mon.nature)

	# Fecha / encuentro: campos aún no en Pokemon → placeholders seguros
	if fecha != null:
		if mon.get("obtain_time") != null and str(mon.get("obtain_time")) != "":
			fecha.text = str(mon.get("obtain_time"))
		else:
			fecha.text = ""

	if encounter != null:
		if mon.get("obtain_map") != null and str(mon.get("obtain_map")) != "":
			encounter.text = str(mon.get("obtain_map"))
		else:
			encounter.text = ""

	if encounter_info != null:
		var met_lv: int = mon.level
		if mon.get("obtain_level") != null:
			met_lv = int(mon.get("obtain_level"))
		encounter_info.text = "Encontrado con Nv. %d." % met_lv

	if personality != null:
		personality.text = _characteristic(mon)


func _characteristic(mon: Pokemon) -> String:
	if mon.ivs.size() < 6:
		return ""
	# Orden PE para desempate: HP, Atk, Def, Spe, SpA, SpD
	var order: Array[int] = [0, 1, 2, 5, 3, 4]
	var best_stat: int = order[0]
	var best_iv: int = int(mon.ivs[best_stat])
	for s: int in order:
		var v: int = int(mon.ivs[s])
		if v > best_iv:
			best_iv = v
			best_stat = s
	var lines: Array = CHAR_LINES[best_stat]
	var idx: int = best_iv % lines.size()
	return str(lines[idx])
