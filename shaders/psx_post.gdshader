shader_type canvas_item;

// Full-frame pass over the world image, after the look of late-90s/early-2000s
// survival horror shot on 1980s colour film: soft halation round bright
// lights (reddish at the edge, as on real negative), a faded, slightly
// green-brown grade with crushed but not black shadows, faint colour fringes
// towards the edges, animated film grain that clumps like silver (stronger in
// the dark), now and then a speck of dust or a hair on the frame, the frame
// weaving a hair in the gate, a slow flicker, a vignette, a soft blur when
// the head turns fast and a red flash for hits.

uniform float grain = 0.08;
uniform float vignette = 0.55;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(0.55, 0.0, 0.0);
uniform float saturation = 0.62;
uniform vec3 shadow_tint : source_color = vec3(0.075, 0.085, 0.07);
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.95, 0.84);
uniform float halation = 0.35;
uniform float fringe = 0.6;
// The player's brightness setting: a gamma over the finished picture.
uniform float brightness = 1.0;
// 0..1: the 1980s film stock (Settings.film): print curve, red halation,
// clumped grain, dust, gate weave.
uniform float film = 1.0;
// How far the picture moved on screen this frame (UV units), from the head
// turning; the frame is smeared along it (Settings.motion_blur).
uniform vec2 blur_vec = vec2(0.0);

float rnd(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(rnd(i), rnd(i + vec2(1.0, 0.0)), f.x), mix(rnd(i + vec2(0.0, 1.0)), rnd(i + vec2(1.0)), f.x), f.y);
}

// The frame with the lens fringe: red and blue a little apart.
#define SAMPLE_FRAME(P, O) vec3(texture(TEXTURE, (P) + (O)).r, texture(TEXTURE, (P)).g, texture(TEXTURE, (P) - (O)).b)

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	// Gate weave: the whole frame drifts a fraction of a pixel, slowly.
	float t8 = floor(TIME * 24.0);
	vec2 weave = (vec2(vnoise(vec2(TIME * 1.3, 2.0)), vnoise(vec2(5.0, TIME * 0.9))) - 0.5) * px * 1.6 * film;
	vec2 uv = UV + weave;
	vec2 q = uv - 0.5;
	// Lens fringe: red and blue drift apart towards the corners.
	vec2 off = q * dot(q, q) * fringe * px * 60.0;
	vec3 c = SAMPLE_FRAME(uv, off);

	// Motion blur: eight taps back along the way the picture moved.
	float bl = length(blur_vec / px);
	if (bl > 1.5) {
		vec2 step = blur_vec / 8.0;
		float j = rnd(FRAGCOORD.xy + TIME) - 0.5;
		vec3 acc = c;
		for (int i = 1; i < 8; i++) {
			acc += SAMPLE_FRAME(uv - step * (float(i) + j), off);
		}
		c = acc / 8.0;
	}

	// Halation: a wide, soft glow of whatever is brighter than the walls;
	// on film the light spreads through the base and comes back red.
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 12; i++) {
		float a = float(i) * 2.39996;
		float r = (float(i) + 1.0) * 3.0;
		glow += max(texture(TEXTURE, uv + vec2(cos(a), sin(a)) * r * px).rgb - 0.6, 0.0);
	}
	c += glow / 12.0 * halation * mix(vec3(1.0, 0.9, 0.75), vec3(1.15, 0.62, 0.42), film * 0.6);

	// Grade: fade the colour, lift the blacks into murky green, warm the lights.
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, saturation);
	c = c * c * (3.0 - 2.0 * c) * 0.35 + c * 0.65;  // gentle S-curve
	c = mix(shadow_tint, highlight_tint, c);
	c = pow(c, vec3(1.08, 1.0, 1.1));
	// Print stock of the eighties: a filmic shoulder that rolls the
	// highlights off softly, shadows a touch cyan, mids a touch warm, the
	// greens pulled down towards olive.
	vec3 film_c = c;
	film_c = 1.0 - exp(-film_c * 1.6);
	film_c /= 1.0 - exp(-1.6);
	float l2 = dot(film_c, vec3(0.299, 0.587, 0.114));
	film_c += vec3(-0.012, 0.004, 0.018) * (1.0 - smoothstep(0.0, 0.35, l2));
	film_c += vec3(0.018, 0.006, -0.02) * smoothstep(0.25, 0.8, l2) * (1.0 - smoothstep(0.8, 1.0, l2));
	film_c.g = mix(film_c.g, (film_c.r + film_c.g) * 0.5, 0.08);
	c = mix(c, film_c, film);

	// Film grain: fine, every pixel, every frame, heavier in the dark; with
	// the film stock it clumps into soft two-pixel grains.
	float n = rnd(FRAGCOORD.xy + fract(TIME * 7.13) * 917.0) + rnd(FRAGCOORD.xy * 1.37 + fract(TIME * 3.7) * 311.0);
	float clump = vnoise(FRAGCOORD.xy * 0.55 + vec2(t8 * 37.0, t8 * 11.0)) * 2.0;
	n = mix(n, clump, film * 0.45);
	c += (n - 1.0) * grain * (0.6 + (1.0 - lum) * 0.9);
	// The picture breathes a little, like an old projector.
	c *= 1.0 + (rnd(vec2(floor(TIME * 18.0), 1.0)) - 0.5) * 0.025;

	// Dust and hairs: one frame in a few has a dark speck somewhere.
	if (film > 0.0) {
		float seed = rnd(vec2(t8, 3.1));
		if (seed > 0.86) {
			vec2 at = vec2(rnd(vec2(t8, 7.0)), rnd(vec2(t8, 9.0)));
			vec2 h = (UV - at) * vec2(px.y / px.x, 1.0);  // in screen heights
			float speck = 1.0 - smoothstep(0.0012, 0.0032, length(h));
			if (seed > 0.97) {  // a hair: a thin curved line
				float curve = abs(h.y - sin(h.x * 90.0 + seed * 20.0) * 0.004);
				speck = max(speck, (1.0 - smoothstep(0.0003, 0.0009, curve)) * step(abs(h.x), 0.025));
			}
			c *= 1.0 - speck * 0.55 * film;
		}
	}

	c *= 1.0 - smoothstep(0.12, 0.75, dot(q * vec2(1.1, 1.0), q * vec2(1.1, 1.0)) * 2.0) * vignette;
	c = mix(c, flash_color, clamp(flash, 0.0, 1.0) * 0.6);
	c = pow(clamp(c, 0.0, 1.0), vec3(1.0 / brightness));
	COLOR = vec4(c, 1.0);
}
