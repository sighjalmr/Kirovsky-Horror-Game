// Shared by the world materials: smooth, mipmapped colour map; a normal map
// for relief (flat when the texture has none); glossiness per material so the
// tiles and chrome catch the torch; vertex colour carries the baked darkening
// towards the floor; cut-out holes where the texture alpha is zero.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform float normal_depth = 1.0;
uniform float roughness = 0.8;
uniform float specular = 0.3;
uniform float metallic = 0.0;

vec4 psx_texel(vec2 uv) {
	return texture(albedo_tex, uv);
}

// Surface response shared by every material.
#define PSX_SURFACE(tex) \
	NORMAL_MAP = texture(normal_tex, UV).rgb; \
	NORMAL_MAP_DEPTH = normal_depth; \
	ROUGHNESS = clamp(roughness + (0.5 - dot(tex.rgb, vec3(0.33))) * 0.2, 0.05, 1.0); \
	SPECULAR = specular; \
	METALLIC = metallic;
