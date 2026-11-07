shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley, cull_disabled, depth_draw_opaque;

// Hair, lashes and spectacle glass: cut-out cards seen from both sides.
#define CARDS
#include "res://shaders/person.gdshaderinc"
