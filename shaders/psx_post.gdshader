shader_type canvas_item;

// Full-frame pass over the world image, after the look of late-90s/early-2000s
// survival horror: soft halation round bright lights, a faded, slightly
// green-brown grade with crushed but not black shadows, faint colour fringes
// towards the edges, heavy animated film grain (stronger in the dark), a
// slow flicker, a vignette and a red flash for hits.

uniform float grain = 0.08;
uniform float vignette = 0.55;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(0.55, 0.0, 0.0);
uniform float saturation = 0.62;
uniform vec3 shadow_tint : source_color = vec3(0.075, 0.085, 0.07);
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.95, 0.84);
uniform float halation = 0.35;
uniform float fringe = 0.6;

float rnd(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 q = UV - 0.5;
	vec2 px = SCREEN_PIXEL_SIZE;
	// Lens fringe: red and blue drift apart towards the corners.
	vec2 off = q * dot(q, q) * fringe * px * 60.0;
	vec3 c = vec3(texture(TEXTURE, UV + off).r, texture(TEXTURE, UV).g, texture(TEXTURE, UV - off).b);

	// Halation: a wide, soft glow of whatever is brighter than the walls.
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 12; i++) {
		float a = float(i) * 2.39996;
		float r = (float(i) + 1.0) * 3.0;
		glow += max(texture(TEXTURE, UV + vec2(cos(a), sin(a)) * r * px).rgb - 0.6, 0.0);
	}
	c += glow / 12.0 * halation * vec3(1.0, 0.9, 0.75);

	// Grade: fade the colour, lift the blacks into murky green, warm the lights.
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, saturation);
	c = c * c * (3.0 - 2.0 * c) * 0.35 + c * 0.65;  // gentle S-curve
	c = mix(shadow_tint, highlight_tint, c);
	c = pow(c, vec3(1.08, 1.0, 1.1));

	// Film grain: fine, every pixel, every frame; heavier in the dark.
	float n = rnd(FRAGCOORD.xy + fract(TIME * 7.13) * 917.0) + rnd(FRAGCOORD.xy * 1.37 + fract(TIME * 3.7) * 311.0);
	c += (n - 1.0) * grain * (0.6 + (1.0 - lum) * 0.9);
	// The picture breathes a little, like an old projector.
	c *= 1.0 + (rnd(vec2(floor(TIME * 18.0), 1.0)) - 0.5) * 0.025;

	c *= 1.0 - smoothstep(0.12, 0.75, dot(q * vec2(1.1, 1.0), q * vec2(1.1, 1.0)) * 2.0) * vignette;
	c = mix(c, flash_color, clamp(flash, 0.0, 1.0) * 0.6);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
