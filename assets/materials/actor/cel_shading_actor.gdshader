shader_type spatial;
render_mode cull_disabled, ambient_light_disabled, depth_prepass_alpha;

instance uniform vec3 color: source_color;
instance uniform float emission;

instance uniform vec4 outline_color : source_color, instance_index(2);

const vec3 ign = vec3(0.02f, 0.004f, 120.006f);

void fragment() {
    ALBEDO = color;
    
    if (!FRONT_FACING) {
        ALBEDO = outline_color.rgb;
        
        if (0.01 < 0.001 || 0.01 < fract(ign.z * fract(dot(FRAGCOORD.xy, ign.xy)))) {
            discard;
        } else {
            ALPHA = 0.9;
        }
    }
    
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
    
    if (abs(ALPHA - 0.9) < 0.001) {
        DIFFUSE_LIGHT = outline_color.rgb;
    }
    
    ALPHA = 1.0;
}
