extends RigidBody2D

@onready var line_trajectory = $Line2D 
# Path menuju RigidBody2D kaki ragdoll Anda (misal: Paha atau Betis)
@onready var ragdoll_leg = $leg # Sesuaikan dengan nama node RigidBody2D kaki Anda

var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var max_drag_distance: float = 200.0 
var power_multiplier: float = 15.0  

func _ready() -> void:
	freeze = true
	if line_trajectory:
		line_trajectory.clear_points()
		setup_dotted_line_appearance()
		
	if ragdoll_leg:
		# Buat kaki ragdoll freeze/diam dulu di awal agar tidak lemas jatuh ke bawah
		ragdoll_leg.freeze = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if global_position.distance_to(event.position) < 50.0:
					is_dragging = true
					drag_start_position = global_position
					if ragdoll_leg:
						ragdoll_leg.freeze = true # Kunci posisi kaki saat mulai ditarik
			elif not event.pressed and is_dragging:
				is_dragging = false
				shoot_ball()

func _process(_delta: float) -> void:
	if is_dragging:
		var current_mouse_pos = get_global_mouse_position()
		var drag_vector = current_mouse_pos - drag_start_position
		
		if drag_vector.length() > max_drag_distance:
			drag_vector = drag_vector.normalized() * max_drag_distance
			
		# --- TARIK KAKI RAGDOLL BERDASARKAN JARAK MOUSE ---
		if ragdoll_leg:
			var drag_ratio = drag_vector.length() / max_drag_distance
			# Putar RigidBody kaki secara prosedural mengikuti tarikan (ubah angka -1.5 sesuai arah yang diinginkan)
			ragdoll_leg.rotation = lerp(ragdoll_leg.rotation, -drag_ratio * 1.5, 0.2)

		# --- GARIS TRAYEKTORI ---
		if line_trajectory:
			line_trajectory.clear_points()
			var pull_direction = drag_vector.normalized()
			var pull_strength = drag_vector.length()
			var start_pos = Vector2.ZERO 
			var num_points = 20 
			var velocity_preview = -pull_direction * (pull_strength * (power_multiplier * 0.4))
			var gravity_preview = 980.0 
			
			for i in range(num_points):
				var t = float(i) * 0.05 
				var x = start_pos.x + (velocity_preview.x * t)
				var y = start_pos.y + (velocity_preview.y * t) + (0.5 * gravity_preview * t * t)
				line_trajectory.add_point(Vector2(x, y))
	else:
		if line_trajectory:
			line_trajectory.clear_points()

func shoot_ball() -> void:
	freeze = false # Lepaskan bola
	
	var current_mouse_pos = get_global_mouse_position()
	var drag_vector = current_mouse_pos - drag_start_position
	if drag_vector.length() > max_drag_distance:
		drag_vector = drag_vector.normalized() * max_drag_distance
		
	var pull_strength = drag_vector.length()
	var launch_vector = -drag_vector 
	apply_central_impulse(launch_vector * power_multiplier)
	
	# --- LEPASKAN RAGDOLL DAN BERIKAN GAYA TENDANGAN ---
	if ragdoll_leg:
		ragdoll_leg.freeze = false # Aktifkan kembali fisika ragdoll
		
		# Hitung kecepatan putar (tendangan) berdasarkan seberapa jauh ditarik
		var kick_force = remap(pull_strength, 0.0, max_drag_distance, 5.0, 25.0)
		
		# Berikan kecepatan putar (angular velocity) agar kaki mengayun menendang ke depan
		ragdoll_leg.angular_velocity = kick_force

	if line_trajectory:
		line_trajectory.clear_points()

func setup_dotted_line_appearance() -> void:
	line_trajectory.width = 14.0 
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1),    
		Color(1, 1, 1, 0.1)   
	])
	line_trajectory.gradient = gradient
	
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.2, 0.2))
	curve.add_point(Vector2(0.4, 1.0))
	curve.add_point(Vector2(0.6, 0.2))
	curve.add_point(Vector2(0.8, 1.0))
	curve.add_point(Vector2(1.0, 0.1))
	line_trajectory.width_curve = curve
