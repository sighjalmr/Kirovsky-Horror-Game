// Shared by the PS1 materials: vertices snapped to the 480×270 pixel grid
// (the wobble), affine texture mapping without perspective correction (the
// warp), nearest texels, cut-out holes where the texture alpha is zero.

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

vec4 psx_texel() {
	return texture(albedo_tex, affine_uv.xy / affine_uv.z);
}
