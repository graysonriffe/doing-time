shader_type spatial;
render_mode ambient_light_disabled, depth_test_disabled;

instance uniform vec3 color: source_color;
instance uniform float emission;

void fragment() {
    ALBEDO = color;
    EMISSION = color * emission;
}

void light() {
    if (dot(NORMAL, LIGHT) > 0.1) {
        float stepFactor = ceil(16.0 / length(LIGHT_COLOR));
        DIFFUSE_LIGHT += (floor(dot(NORMAL, LIGHT) * (ATTENUATION / PI) * length(ALBEDO * LIGHT_COLOR) * stepFactor) / stepFactor) * normalize(ALBEDO * LIGHT_COLOR);
        
        DIFFUSE_LIGHT += (mod(dot(NORMAL, LIGHT) * (ATTENUATION / PI) * length(ALBEDO * LIGHT_COLOR) * stepFactor, 1.0) / (stepFactor * 2.5)) * normalize(ALBEDO * LIGHT_COLOR);
    }
    
    vec3 reflectionVector = (2.0 * dot(LIGHT, NORMAL) * NORMAL) - LIGHT;
    
    float specularDot = max(0.0, dot(reflectionVector, VIEW));
    float specularIntensity = pow(specularDot, 50.0);
    
    SPECULAR_LIGHT += SPECULAR_AMOUNT * step(0.5, specularIntensity) * (ATTENUATION / PI) * LIGHT_COLOR;
}
