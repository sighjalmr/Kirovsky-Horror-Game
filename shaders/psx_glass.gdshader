shader_type spatial;
render_mode specular_disabled, diffuse_lambert, cull_disabled, blend_mix, depth_draw_never;

// Glass: freezer lids and the guard booth windows. Mostly see-through with a
// faint tint; tint.a is the opacity.
#include "res://shaders/psx_common.gdshaderinc"

void fragment() {
	vec4 tex = psx_texel();
	ALBEDO = tex.rgb * tint.rgb * COLOR.rgb;
	ALPHA = tint.a * tex.a;
	EMISSION = emission * tex.rgb;
}
