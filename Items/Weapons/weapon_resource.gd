class_name WeaponResource extends Resource

enum Handedness { LEFT, RIGHT, BOTH }
enum ThrowStyle { SPIN, STRAIGHT, TUMBLE }
enum InputMode { CLICK_ONLY, HOLD_ACTION, BOTH }
enum Types { SWORD, SHIELD, STAFF, BOW, ARROW}

@export var weapon_name: String = ""
@export var weapon_type: Types
@export var weapon_sync: Array[Types]
@export var weapon_hand: Handedness
@export var weapon_throw_style: ThrowStyle
@export var weapon_controller: Resource
@export var weapon_sprite: Array[CompressedTexture2D]
@export var weapon_collision: Resource
@export var weapon_damage: float = 0.0
@export_range(0.0, 360.0) var weapon_angle: float
@export var weapon_offset: Vector2
@export var weapon_arm_length: float
@export var weapon_cooldown: float = 0.0
@export var weapon_duration: float = 1.0 
@export var weapon_mana_cost: float = 0.0
@export var weapon_cast_duration: float = 0.0
@export var weapon_effect: PackedScene
