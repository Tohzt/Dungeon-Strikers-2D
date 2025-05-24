class_name AttackResource extends Resource

enum AttackType { MELEE, PROJECTILE, MAGIC, AOE, HEAL, BUFF, TELEPORT }

@export var attack_name: String = ""
@export var damage: float = 0.0
@export var mana_cost: float = 0.0
@export var cast_time: float = 0.0
@export var cooldown: float = 0.0
@export var attack_duration: float = 1.0  # How long the attack lasts before being destroyed
@export var aoe_radius: float = 0.0
@export var attack_scene: PackedScene  # Should be a scene that extends Area2D for collision detection
@export var telegraph_scene: PackedScene  # Should be a scene that extends Node2D for visual effects
@export var attack_type: AttackType = AttackType.MELEE
