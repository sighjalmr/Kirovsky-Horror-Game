shader_type spatial;
render_mode specular_disabled, diffuse_lambert, cull_back, depth_draw_opaque;

// PS1 material for every solid model in the store.
#include "res://shaders/psx_common.gdshaderinc"

void fragment() {
	vec4 tex = psx_texel();
	if (tex.a < 0.5) {
		discard;
	}
	ALBEDO = tex.rgb * tint.rgb * COLOR.rgb;
	EMISSION = emission * tex.rgb;
}
