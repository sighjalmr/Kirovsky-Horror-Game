shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley, cull_back, depth_draw_opaque;

// Material for every solid model in the store.
#include "res://shaders/psx_common.gdshaderinc"

void fragment() {
	vec4 tex = psx_texel(UV);
	if (tex.a < 0.5) {
		discard;
	}
	ALBEDO = tex.rgb * tint.rgb * COLOR.rgb;
	EMISSION = emission * tex.rgb;
	PSX_SURFACE(tex)
}
