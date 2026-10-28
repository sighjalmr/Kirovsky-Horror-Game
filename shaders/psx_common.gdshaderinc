// Shared by the world materials: smooth, mipmapped textures; vertex colour
// carries the baked darkening towards the floor; cut-out holes where the
// texture alpha is zero.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 emission : source_color = vec3(0.0);

vec4 psx_texel(vec2 uv) {
	return texture(albedo_tex, uv);
}
