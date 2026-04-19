shader_type spatial;
render_mode unshaded;
render_mode ambient_light_disabled;

uniform float lines = 30.0;
uniform vec4 material_color : source_color = vec4(1,1,1,1);
instance uniform vec4 color : source_color = vec4(1,1,1,1);
uniform bool vignette = true;
uniform sampler2D noise_texture;

varying vec3 worldPosition;

void vertex() {
	// Called for every vertex the material is visible on.
    worldPosition = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float ins = sin(mod(worldPosition.y * lines, 1.0)*PI) - (pow(sin(mod(worldPosition.y * 1.0 - TIME / 10.0, 1.0) * PI), 20.0) * 2.75);
    float dist = 1.0 - length((UV - vec2(0.5)) * 2.0);
	ALBEDO = mix(vec3(0.8), vec3(1.0), ins) * color.rgb * material_color.rgb;
    float t = TIME * 25.0;
    vec2 uv = (worldPosition.xy * 0.2) + (worldPosition.z * 0.2) + vec2(0.5, 0.5);
    vec2 uvnoise = vec2(uv.x * cos(t) - uv.y * sin(t), uv.x * sin(t) + uv.y * cos(t));
    vec4 noise = texture(noise_texture, uvnoise);
    if (vignette) {
        ALPHA = max((dist + 0.4) * (noise.r * 0.8 + 0.2) * color.a * material_color.a, 0.0);
    }
    else {
        ALPHA = (noise.r * 0.8 + 0.2) * color.a * material_color.a;
    }
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
