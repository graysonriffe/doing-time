shader_type spatial;
render_mode unshaded;
render_mode ambient_light_disabled;

uniform float lines = 90.0;
uniform sampler2D noise_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    float ins = sin(mod(UV.y * lines, 1.0)*PI) - (pow(sin(mod(UV.y * 1.0 - TIME / 10.0, 1.0) * PI), 20.0) * 2.75);
    float dist = 1.0 - length((UV - vec2(0.5)) * 2.0);
	ALBEDO = mix(vec3(0.8), vec3(1.0), ins) * vec3(1,0,0);
    float t = TIME * 25.0;
    vec2 uv = UV + vec2(0.5, 0.5);
    vec2 uvnoise = vec2(uv.x * cos(t) - uv.y * sin(t), uv.x * sin(t) + uv.y * cos(t));
    vec4 noise = texture(noise_texture, uvnoise);
    ALPHA = (dist + 0.4) * (noise.r * 0.8 + 0.2);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
