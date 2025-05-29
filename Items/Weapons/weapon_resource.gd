class_name WeaponResource extends Resource

enum Handedness { LEFT, RIGHT, BOTH }
@export var weapon_hand: Handedness
@export var weapon_sprite: Array[CompressedTexture2D]
@export var weapon_name: String = ""
@export var weapon_damage: float = 0.0
@export_range(0.0, 360.0) var weapon_angle: float
@export var weapon_offset: Vector2
@export var weapon_cooldown: float = 0.0
@export var weapon_duration: float = 1.0 
@export var weapon_mana_cost: float = 0.0
@export var weapon_cast_duration: float = 0.0
@export var weapon_collider: PackedScene
@export var weapon_effect: PackedScene
