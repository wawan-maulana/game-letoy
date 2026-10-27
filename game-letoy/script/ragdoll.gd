extends CharacterBody2D

@onready var head: RigidBody2D = $head
@onready var arm: RigidBody2D = $arm
@onready var arm_2: RigidBody2D = $arm2
@onready var leg: RigidBody2D = $leg
@onready var leg_2: RigidBody2D = $leg2
@onready var body: RigidBody2D = $body

var dragged_body: RigidBody2D = null
var drag_offset: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_stop_drag()

func _physics_process(_delta: float) -> void:
	if dragged_body and is_instance_valid(dragged_body):
		# Posisikan RigidBody langsung mengikuti mouse tanpa delay
		var target_pos = get_global_mouse_position() + drag_offset
		dragged_body.global_position = target_pos
		# Matikan kecepatan sesaat agar tidak meluncur/mental berlebihan
		dragged_body.linear_velocity = Vector2.ZERO
		dragged_body.angular_velocity = 0.0

func _start_drag() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	for result in results:
		var collider = result.collider
		if collider is RigidBody2D:
			dragged_body = collider
			# Hitung jarak offset agar klik tidak langsung menjepret ke tengah sprite
			drag_offset = dragged_body.global_position - get_global_mouse_position()
			
			# Ubah mode menjadi kinematic sementara agar bisa digeser bebas oleh mouse
			dragged_body.freeze = true
			dragged_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
			break

func _stop_drag() -> void:
	if dragged_body and is_instance_valid(dragged_body):
		# Kembalikan RigidBody ke mode fisik normal agar jatuh/terdorong lagi
		dragged_body.freeze = false
		dragged_body = null
