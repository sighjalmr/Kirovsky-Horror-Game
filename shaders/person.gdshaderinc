// People (scripts/person.gd): the Rocketbox photo textures with their gloss
// maps. Skin lets light through a little (subsurface scattering, so faces
// are not plaster in the torch beam and ears glow red against a lamp),
// cloth catches a faint sheen at grazing angles, hair and lashes are cut-out
// cards with soft edges (alpha to coverage under MSAA).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
// Rocketbox specular map: bright where the surface is wet or polished.
uniform sampler2D spec_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float spec_map = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform float normal_depth = 1.0;
uniform float roughness = 0.8;
uniform float specular = 0.3;
uniform float metallic = 0.0;
uniform float skin = 0.0;
uniform float sheen = 0.0;

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = tex.rgb * tint.rgb * COLOR.rgb;
	EMISSION = emission * tex.rgb;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	NORMAL_MAP_DEPTH = normal_depth;
	float s = texture(spec_tex, UV).r;
	ROUGHNESS = mix(roughness, clamp(0.92 - s * 0.8, 0.22, 1.0), spec_map);
	SPECULAR = mix(specular, 0.25 + s * 0.35, spec_map);
	METALLIC = metallic;
	SSS_STRENGTH = skin;
	RIM = sheen;
	RIM_TINT = 0.7;
#ifdef CARDS
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA_ANTIALIASING_EDGE = 0.35;
	ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(albedo_tex, 0));
#else
	if (tex.a < 0.5) {
		discard;
	}
#endif
}
