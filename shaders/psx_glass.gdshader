shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley, cull_disabled, blend_mix, depth_draw_never;

// Glass: freezer lids and the guard booth windows. Mostly see-through with a
// faint tint; tint.a is the opacity.
#include "res://shaders/psx_common.gdshaderinc"

void fragment() {
	vec4 tex = psx_texel(UV);
	ALBEDO = tex.rgb * tint.rgb * COLOR.rgb;
	ALPHA = tint.a * tex.a;
	EMISSION = emission * tex.rgb;
	PSX_SURFACE(tex)
}
