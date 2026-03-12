extends Node3D


@export var world_environment_node : WorldEnvironment

func _ready() -> void:
	_setup_directional_light()
	_setup_environment()


func _setup_directional_light() -> void:
	var light := DirectionalLight3D.new()
	add_child(light)
	light.name = "AlienSunLight"

	# --- Direction ---.
	light.rotation_degrees = Vector3(-48.0, -46.0, 0.0)

	# --- Color & Energy ---
	light.light_color       = Color(0.78, 0.84, 0.92)  
	light.light_energy      = 1.15                      

	# --- Shadows ---
	light.shadow_enabled    = true

	light.directional_shadow_mode        = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_split_1     = 0.10
	light.directional_shadow_split_2     = 0.30
	light.directional_shadow_split_3     = 0.60
	light.directional_shadow_fade_start  = 0.85
	light.shadow_blur                    = 2.0           


	light.light_specular    = 0.25


func _setup_environment() -> void:
	var env_node : WorldEnvironment

	if world_environment_node != null:
		env_node = world_environment_node
	else:
		env_node = WorldEnvironment.new()
		add_child(env_node)
		env_node.name = "WorldEnvironment"

	var env : Environment
	if env_node.environment != null:
		env = env_node.environment
	else:
		env = Environment.new()
		env_node.environment = env

	env.ambient_light_source  = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color   = Color(0.14, 0.22, 0.20)  
	env.ambient_light_energy  = 0.55                        


	env.tonemap_mode          = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure      = 1.05
	env.tonemap_white         = 1.0

	env.glow_enabled          = true
	env.glow_normalized       = false
	env.glow_intensity        = 0.6
	env.glow_bloom            = 0.12
	env.glow_blend_mode       = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	env.ssao_enabled          = true
	env.ssao_radius           = 0.8
	env.ssao_intensity        = 1.2

	print("[AlienLighting] Setup complete.")
