shader_type canvas_item;

// Full-frame pass over the world image: animated film grain (stronger in the
// dark), vignette and a red flash for hits.

uniform float grain = 0.045;
uniform float vignette = 0.35;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(0.55, 0.0, 0.0);

float rnd(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	vec2 px = floor(FRAGCOORD.xy / 2.0);
	c += (rnd(px + fract(TIME * 7.13) * 91.7) - 0.5) * grain * (1.0 + (1.0 - lum) * 0.6);
	vec2 q = UV - 0.5;
	c *= 1.0 - dot(q, q) * vignette * 2.0;
	c = mix(c, flash_color, clamp(flash, 0.0, 1.0) * 0.6);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
