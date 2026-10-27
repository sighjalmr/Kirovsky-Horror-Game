shader_type spatial;
render_mode specular_disabled, diffuse_lambert, cull_back, depth_draw_opaque;

// PS1 material for every model in the store: per-vertex (Gouraud) light,
// vertices snapped to the 480×270 pixel grid (the wobble), affine texture
// mapping without perspective correction (the warp), nearest texels.

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform vec2 snap_res = vec2(480.0, 270.0);

varying vec3 affine_uv; // UV * w and w: dividing in fragment() undoes perspective correction

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (clip.w > 0.0) {
		vec2 grid = snap_res * 0.5;
		clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
	}
	POSITION = clip;
	affine_uv = vec3(UV * clip.w, clip.w);
}

void fragment() {
	vec2 uv = affine_uv.xy / affine_uv.z;
	ALBEDO = texture(albedo_tex, uv).rgb * tint.rgb * COLOR.rgb;
	EMISSION = emission;
}
