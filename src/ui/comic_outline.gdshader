shader_type spatial;
render_mode unshaded, cull_front;
void vertex() { VERTEX += NORMAL * 0.008; }
void fragment() { ALBEDO = vec3(0.035, 0.042, 0.045); }
