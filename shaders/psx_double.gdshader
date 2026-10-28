shader_type spatial;
render_mode specular_disabled, diffuse_lambert, cull_disabled, depth_draw_opaque;

// Two-sided PS1 material: cloth skirts, baskets, thin sheets seen from both sides.
#include "res://shaders/psx_common.gdshaderinc"

void fragment() {
	vec4 tex = psx_texel();
	if (tex.a < 0.5) {
		discard;
	}
	ALBEDO = tex.rgb * tint.rgb * COLOR.rgb;
	EMISSION = emission * tex.rgb;
}
