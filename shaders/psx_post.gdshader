shader_type canvas_item;

// Full-frame pass over the 480×270 world image: animated film grain
// (stronger in the dark), vignette, a red flash for hits, then 15-bit
// colour (5 bits per channel) with a 4×4 Bayer dither.

uniform vec2 res = vec2(480.0, 270.0);
uniform float grain = 0.06;
uniform float vignette = 0.35;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(0.55, 0.0, 0.0);

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float rnd(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV * res);
	vec3 c = texture(TEXTURE, (px + 0.5) / res).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c += (rnd(px + fract(TIME * 7.13) * 91.7) - 0.5) * grain * (1.0 + (1.0 - lum) * 0.6);
	vec2 q = UV - 0.5;
	c *= 1.0 - dot(q, q) * vignette * 2.0;
	c = mix(c, flash_color, clamp(flash, 0.0, 1.0) * 0.6);
	int i = int(mod(px.y, 4.0)) * 4 + int(mod(px.x, 4.0));
	c += (BAYER[i] / 16.0 - 0.5) / 31.0;
	COLOR = vec4(floor(clamp(c, 0.0, 1.0) * 31.0 + 0.5) / 31.0, 1.0);
}
