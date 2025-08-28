class_name EntityBehaviorClass extends Node

# ===== EXPORT VARIABLES =====
@export_category("Core Components")
@export var Sprite: Sprite2D
@export var Attack_Origin: Marker2D

@export_category("Spawn & State")
@export var spawn_pos: Vector2
@export var is_active: bool = false

# ===== CONSTANTS =====
const SPEED: float = 300.0

# ===== HEALTH SYSTEM =====
# Base stats
var strength: int = 0
var intelligence: int = 0
var endurance: int = 0

# Max Values
var hp_max: float = 1000.0
var mana_max: float = 100.0
var stamina_max: float = 5.0

# Costs and Regens
var mana_cost: float = 0.0
var mana_cost_default: float = 0.0
var stamina_regen_rate: float = 2.0
var stamina_cost: float = 1.0
var stamina_cost_default: float = 1.0

# Internal
var stamina_regen_timer: Timer
var stat_values: Dictionary = {}

# Health properties with automatic signal emission
var hp: float:
	get: return stat_values.get("hp", hp_max)
	set(value): 
		stat_values["hp"] = value
		hp_changed.emit(value, hp_max)

var mana: float:
	get: return stat_values.get("mana", mana_max)
	set(value): 
		stat_values["mana"] = value
		mana_changed.emit(value, mana_max)

var stamina: float:
	get: return stat_values.get("stamina", stamina_max)
	set(value): 
		stat_values["stamina"] = value
		stamina_changed.emit(value, stamina_max)
		# Restart stamina regeneration if we're below max
		if value < stamina_max and stamina_regen_timer and stamina_regen_timer.is_stopped():
			stamina_regen_timer.start()

# ===== COMBAT & MOVEMENT =====
var atk_pwr: float = 400.0  
var def_base: float = 100.0
var tar_pos: Vector2
var target: Node2D = null

# ===== STATE VARIABLES =====
var name_display: String
var spawn_rot: float = 0.0
var is_in_iframes: bool = false
var iframes_duration: float = 0.5
var has_control: bool = false

# ===== SIGNALS =====
signal hp_changed(new_hp: float, max_hp: float)
signal mana_changed(new_mana: float, max_mana: float)
signal stamina_changed(new_stamina: float, max_stamina: float)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
