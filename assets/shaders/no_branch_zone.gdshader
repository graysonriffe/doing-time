shader_type spatial;
render_mode unshaded, ambient_light_disabled, cull_disabled;

uniform float lines = 30.0;

uniform vec4 color: source_color;

uniform sampler2D noise_texture;

varying vec3 worldPosition;

void vertex() {
    worldPosition = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float ins = sin(mod(worldPosition.y * lines, 1.0)*PI) - (pow(sin(mod(worldPosition.y * 0.5 - TIME / 5.0, 1.0) * PI), 20.0) * 2.75);
    ALBEDO = mix(vec3(0.8), vec3(1.0), ins) * color.rgb;
    float t = TIME * 25.0;
    vec2 uv = (worldPosition.xy * 0.2) + (worldPosition.z * 0.2) + vec2(0.5, 0.5);
    vec2 uvnoise = vec2(uv.x * cos(t) - uv.y * sin(t), uv.x * sin(t) + uv.y * cos(t));
    vec4 noise = texture(noise_texture, uvnoise);
    
    ALPHA = (noise.r * 0.8 + 0.2) * color.a;
}