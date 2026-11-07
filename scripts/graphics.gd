class_name Graphics
extends RefCounted

## The look of the picture at the quality the player picked in Settings →
## «Графика». Every WorldEnvironment, light and 3D viewport is set up here as
## it enters the scene tree (Graphics.install), so the hall, the street, the
## cutscenes and the car all get the same treatment without each building it:
##
## - volumetric fog: the air in the hall holds a little dust, so the torch
##   throws a visible beam and the tubes stand in a haze;
## - soft shadows: shadows blur with distance from what casts them (PCSS);
## - SSAO / SSIL: contact shadows in corners and under shelves, light from a
##   lit wall bouncing onto the next one;
## - SSR: the mopped floor and the wet asphalt reflect lamps and people;
## - SDFGI (Ультра): real bounced light through the whole building;
## - TAA and MSAA against shimmering edges.
##
## All of this needs the Forward+ renderer (Vulkan / Direct3D 12). On a
## computer without it Godot starts in OpenGL (Compatibility) and these
## effects are simply off; the picture then looks as it did before.

enum { LOW, MEDIUM, HIGH, ULTRA }
const NAMES := ["низкое", "среднее", "высокое", "ультра"]

## Light meta "role": "beam" for hand torches and headlights (strong
## scattering in the fog, crisp-edged soft shadow), "lamp" for ceiling tubes.
static var _envs: Array[Environment] = []
static var _views: Array = []
static var _installed := false


static func level() -> int:
	return clampi(Settings.graphics, LOW, ULTRA)


## True when the modern renderer is running (so the effects really exist).
static func modern() -> bool:
	return RenderingServer.get_current_rendering_method() != "gl_compatibility"


static func install(tree: SceneTree) -> void:
	if _installed:
		return
	_installed = true
	for a in OS.get_cmdline_user_args():  # dev: --gfx=0..3 picks the level for screenshots
		if a.begins_with("--gfx="):
			Settings.graphics = clampi(int(a.get_slice("=", 1)), LOW, ULTRA)
	tree.node_added.connect(_on_node_added)
	MeshBuilder.bevel = 0.01 if level() >= HIGH else 0.0
	apply_global()


static func _on_node_added(n: Node) -> void:
	if n is WorldEnvironment:
		var we := n as WorldEnvironment
		if we.environment:
			setup_env(we.environment)
	elif n is Light3D:
		setup_light(n as Light3D)
	elif n is SubViewport:
		setup_view(n as SubViewport)
	elif n is Camera3D and (n as Camera3D).environment:
		setup_env((n as Camera3D).environment)


## Settings changed: everything already in the world takes the new level.
static func reapply(tree: SceneTree) -> void:
	apply_global()
	var alive: Array[Environment] = []
	for e in _envs:
		if is_instance_valid(e):
			alive.append(e)
	_envs = alive
	for e in _envs:
		_configure_env(e)
	for n in tree.root.find_children("*", "Light3D", true, false):
		setup_light(n as Light3D)
	for n in tree.root.find_children("*", "SubViewport", true, false):
		setup_view(n as SubViewport)


static func apply_global() -> void:
	var q := level()
	var soft: int = [RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][q]
	RenderingServer.positional_soft_shadow_filter_set_quality(soft)
	RenderingServer.directional_soft_shadow_filter_set_quality(soft)
	if not modern():
		return
	RenderingServer.environment_set_volumetric_fog_volume_size([64, 64, 96, 128][q], [48, 64, 96, 128][q])
	RenderingServer.environment_set_volumetric_fog_filter_active(q >= MEDIUM)
	RenderingServer.environment_set_ssao_quality([RenderingServer.ENV_SSAO_QUALITY_VERY_LOW,
		RenderingServer.ENV_SSAO_QUALITY_LOW, RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		RenderingServer.ENV_SSAO_QUALITY_HIGH][q], true, 0.5, 2, 50, 300)
	RenderingServer.environment_set_ssil_quality([RenderingServer.ENV_SSIL_QUALITY_VERY_LOW,
		RenderingServer.ENV_SSIL_QUALITY_LOW, RenderingServer.ENV_SSIL_QUALITY_LOW,
		RenderingServer.ENV_SSIL_QUALITY_MEDIUM][q], true, 0.5, 4, 50, 300)
	RenderingServer.environment_set_ssr_roughness_quality([RenderingServer.ENV_SSR_ROUGHNESS_QUALITY_DISABLED,
		RenderingServer.ENV_SSR_ROUGHNESS_QUALITY_LOW, RenderingServer.ENV_SSR_ROUGHNESS_QUALITY_MEDIUM,
		RenderingServer.ENV_SSR_ROUGHNESS_QUALITY_HIGH][q])
	RenderingServer.environment_set_sdfgi_ray_count(RenderingServer.ENV_SDFGI_RAY_COUNT_32 if q < ULTRA
		else RenderingServer.ENV_SDFGI_RAY_COUNT_64)
	RenderingServer.environment_set_sdfgi_frames_to_converge(RenderingServer.ENV_SDFGI_CONVERGE_IN_15_FRAMES)


static func setup_env(e: Environment) -> void:
	if not e in _envs:
		_envs.append(e)
	_configure_env(e)


## Outdoors when the depth fog reaches far (the street, the district).
static func _outdoor(e: Environment) -> bool:
	return e.fog_enabled and e.fog_depth_end > 40.0 or e.has_meta("outdoor")


static func _configure_env(e: Environment) -> void:
	var q := level()
	var out := _outdoor(e)
	var night := e.ambient_light_energy < 0.4
	# Volumetric fog: dust in the hall's air, the evening damp over the square.
	e.volumetric_fog_enabled = q >= MEDIUM and Settings.volumetric
	e.volumetric_fog_density = (0.012 if night else 0.004) if out else 0.018
	e.volumetric_fog_albedo = Color(0.82, 0.84, 0.8) if not out else Color(0.85, 0.87, 0.9)
	e.volumetric_fog_emission = Color.BLACK
	e.volumetric_fog_anisotropy = 0.45  # light scatters forward: the beam glows when seen along it
	e.volumetric_fog_length = 90.0 if out else 28.0
	e.volumetric_fog_detail_spread = 2.0
	e.volumetric_fog_gi_inject = 0.6
	e.volumetric_fog_ambient_inject = 0.0 if night else 0.15
	e.volumetric_fog_sky_affect = 0.2
	e.volumetric_fog_temporal_reprojection_enabled = true
	e.volumetric_fog_temporal_reprojection_amount = 0.9
	# Contact shadows in the corners, under shelves, behind the freezers.
	e.ssao_enabled = q >= MEDIUM
	e.ssao_radius = 1.2
	e.ssao_intensity = 2.2
	e.ssao_power = 1.6
	e.ssao_detail = 0.6
	e.ssao_light_affect = 0.15
	e.ssao_ao_channel_affect = 0.4
	e.ssil_enabled = q >= HIGH
	e.ssil_radius = 4.0
	e.ssil_intensity = 0.7
	# The wet floor and the puddles.
	e.ssr_enabled = q >= HIGH and Settings.reflections
	e.ssr_max_steps = 48 if q == HIGH else 80
	e.ssr_fade_in = 0.12
	e.ssr_fade_out = 2.5
	e.ssr_depth_tolerance = 0.25
	# Bounced light through the whole building.
	e.sdfgi_enabled = q >= ULTRA and Settings.gi
	e.sdfgi_use_occlusion = true
	e.sdfgi_read_sky_light = out
	e.sdfgi_cascades = 4 if out else 3
	e.sdfgi_min_cell_size = 0.25 if out else 0.12
	e.sdfgi_energy = 0.6 if night else 0.9
	e.sdfgi_bounce_feedback = 0.25
	e.sdfgi_normal_bias = 1.1
	# A soft bloom on the tubes, the headlights, the lit windows.
	e.glow_enabled = q >= MEDIUM
	e.glow_normalized = false
	e.glow_intensity = 0.55
	e.glow_strength = 1.0
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = 1.15
	e.glow_hdr_scale = 2.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	for i in 7:
		e.set_glow_level(i, [0.0, 0.0, 1.0, 0.8, 1.0, 0.6, 0.0][i])


static func setup_light(l: Light3D) -> void:
	var q := level()
	var role: String = l.get_meta("role", "")
	if role == "":
		role = "beam" if l is SpotLight3D and (l as SpotLight3D).spot_angle < 40.0 and l.shadow_enabled else "lamp"
	if role == "beam":
		l.light_volumetric_fog_energy = 7.0
		l.light_size = 0.04 if q >= HIGH else 0.0
		l.shadow_blur = 1.0
	else:
		l.light_volumetric_fog_energy = 0.3
		l.light_size = 0.12 if q >= HIGH and l.shadow_enabled else 0.0
		l.shadow_blur = 1.6 if q >= MEDIUM else 1.0
	if l.shadow_enabled:
		l.shadow_bias = 0.04
		l.shadow_normal_bias = 1.2
	if l is DirectionalLight3D:
		var d := l as DirectionalLight3D
		d.light_angular_distance = 0.8 if q >= HIGH else 0.0
		d.directional_shadow_blend_splits = q >= HIGH
	l.distance_fade_enabled = q <= LOW and not l is DirectionalLight3D and role != "beam"
	l.distance_fade_begin = 30.0
	l.distance_fade_length = 10.0


static func setup_view(v: SubViewport) -> void:
	if v.has_meta("plain"):
		return
	if not v in _views:
		_views.append(v)
	var q := level()
	v.msaa_3d = [Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_4X, Viewport.MSAA_4X][q]
	v.use_taa = q >= HIGH and modern()
	v.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	v.positional_shadow_atlas_size = [2048, 4096, 4096, 8192][q]
	v.positional_shadow_atlas_16_bits = true
	v.mesh_lod_threshold = [4.0, 1.5, 1.0, 0.5][q]
	v.use_debanding = modern()


## The film settings and the motion blur on a post material, every frame:
## how far the middle of the picture moved on screen since the last frame,
## from the camera turning or swaying (not from things moving in it).
class Blur extends Node:
	var view: SubViewport
	var post: ShaderMaterial
	var _prev := Transform3D()
	var _cam: Camera3D

	func _init(v: SubViewport, p: ShaderMaterial) -> void:
		view = v
		post = p
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(_delta: float) -> void:
		post.set_shader_parameter("film", Settings.film)
		var cam := view.get_camera_3d()
		var vec := Vector2.ZERO
		if cam and Settings.motion_blur and Graphics.level() >= Graphics.MEDIUM and not get_tree().paused:
			var now := cam.global_transform
			if cam == _cam:
				# A point ten metres ahead last frame, seen through the camera now.
				var p := _prev * Vector3(0, 0, -10.0)
				if not cam.is_position_behind(p):
					var size := Vector2(view.size)
					vec = (cam.unproject_position(p) - size * 0.5) / size
					vec *= 0.5  # a 180° shutter: the frame is exposed half the time
					if vec.length() > 0.12:  # a cut or a jump, not a turn
						vec = Vector2.ZERO
					vec = vec.limit_length(0.03)
			_prev = now
			_cam = cam
		post.set_shader_parameter("blur_vec", -vec)
