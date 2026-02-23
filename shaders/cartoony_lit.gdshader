shader_type spatial;
render_mode ambient_light_disabled;

uniform sampler2D albedo_color;
uniform vec3 color : source_color;
instance uniform vec3 instance_color : source_color = vec3(1,1,1);
uniform float shininess;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
    ALBEDO = instance_color;
    EMISSION = texture(albedo_color, UV).rgb * color * instance_color;
}

void light() {
    // Called for every pixel for every light affecting the material.
    // Uncomment to replace the default light processing function with this one.
    if (dot(NORMAL, LIGHT) > 0.1) {
        // This creates the "steps"
        float step_factor = ceil(16.0 / length(LIGHT_COLOR));
        DIFFUSE_LIGHT += (floor(dot(NORMAL, LIGHT) * (ATTENUATION/PI) * length(ALBEDO * LIGHT_COLOR) * step_factor) / step_factor) * normalize(ALBEDO * LIGHT_COLOR);;
        // Apply a little bit of a gredient
        DIFFUSE_LIGHT += (mod(dot(NORMAL, LIGHT) * (ATTENUATION/PI) * length(ALBEDO * LIGHT_COLOR) * step_factor, 1.0) / (step_factor * 2.5)) * normalize(ALBEDO * LIGHT_COLOR);;
    }

    vec3 reflection_vector = (2.0 * dot(LIGHT, NORMAL) * NORMAL) - LIGHT;

    float spec_dot = max(0.0, dot(reflection_vector, VIEW));
    float specular_intensity = pow(spec_dot, shininess);

    // Applying ATTENUATION ensures the highlight respects shadows and light distance
    SPECULAR_LIGHT += SPECULAR_AMOUNT * step(0.5, specular_intensity) * (ATTENUATION/PI) * LIGHT_COLOR * 0.5;
}
