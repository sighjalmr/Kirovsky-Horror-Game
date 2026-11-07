// Shared by the world materials: smooth, mipmapped colour map; a normal map
// for relief (flat when the texture has none); glossiness per material so the
// tiles and chrome catch the torch; vertex colour carries the baked darkening
// towards the floor; a roughness map where there is one; cut-out holes where the texture alpha is zero.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
// Roughness map for the surfaces that have one (glossy tiles, matt grout);
// rough_map 0 keeps the single per-material value.
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float rough_map = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform float normal_depth = 1.0;
uniform float roughness = 0.8;
uniform float specular = 0.3;
uniform float metallic = 0.0;

// Standing water (Mats.WET): the floor freshly mopped in patches, puddles
// on the asphalt. The mask is laid in world space, one repeat every 14 m,
// so it does not repeat with the tiles; `wet_cover` is how much of the
// ground it covers (0 dry .. 1 flooded), `wet` how wet the wet part is.
uniform sampler2D wet_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float wet = 0.0;
uniform float wet_cover = 0.4;
uniform float wet_darken = 0.5;
varying vec3 psx_world;

void vertex() {
	psx_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec4 psx_texel(vec2 uv) {
	return texture(albedo_tex, uv);
}

// Surface response shared by every material.
#define PSX_SURFACE(tex) \
	NORMAL_MAP = texture(normal_tex, UV).rgb; \
	NORMAL_MAP_DEPTH = normal_depth; \
	ROUGHNESS = clamp(mix(roughness + (0.5 - dot(tex.rgb, vec3(0.33))) * 0.2, \
		texture(rough_tex, UV).r * roughness * 2.0, rough_map), 0.05, 1.0); \
	SPECULAR = specular; \
	METALLIC = metallic; \
	if (wet > 0.0) { \
		float psx_m = texture(wet_tex, psx_world.xz / 14.0).r; \
		float psx_up = smoothstep(0.75, 0.95, (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y); \
		float psx_pool = smoothstep(1.0 - wet_cover, 1.0 - wet_cover + 0.06, psx_m) * psx_up * wet; \
		float psx_damp = smoothstep(1.0 - wet_cover - 0.18, 1.0 - wet_cover, psx_m) * psx_up * wet; \
		ROUGHNESS = mix(ROUGHNESS, ROUGHNESS * 0.45, psx_damp); \
		ROUGHNESS = mix(ROUGHNESS, 0.02, psx_pool); \
		SPECULAR = mix(SPECULAR, 0.6, psx_pool); \
		NORMAL_MAP = mix(NORMAL_MAP, vec3(0.5, 0.5, 1.0), psx_pool * 0.9); \
		ALBEDO *= mix(1.0, 0.6, max(psx_pool, psx_damp * 0.6) * wet_darken); \
	}
