shader_type spatial;
render_mode ambient_light_disabled;

uniform sampler2D albedo : hint_default_white;
uniform vec3 material_color : source_color = vec3(1,1,1);
instance uniform vec3 color : source_color = vec3(1,1,1);
instance uniform float lighting_multiplier = 1.0;
instance uniform float emission = 0.0;
uniform float specular_strength = 1.0;
uniform float shininess = 50.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
    ALBEDO = texture(albedo, UV).rgb * material_color * color * lighting_multiplier;
    //EMISSION = vec3(0);
    EMISSION = texture(albedo, UV).rgb * material_color * color * emission;
}

void light() {
    // Called for every pixel for every light affecting the material.
    // Uncomment to replace the default light processing function with this one.
    if (dot(NORMAL, LIGHT) > 0.1) {
        // This creates the "steps"
        float step_factor = ceil(16.0 / length(LIGHT_COLOR));
        DIFFUSE_LIGHT += (floor(dot(NORMAL, LIGHT) * (ATTENUATION/PI) * length(LIGHT_COLOR) * step_factor) / step_factor) * normalize(LIGHT_COLOR) * ALBEDO;
        // Apply a little bit of a gredient
        DIFFUSE_LIGHT += (mod(dot(NORMAL, LIGHT) * (ATTENUATION/PI) * length(LIGHT_COLOR) * step_factor, 1.0) / (step_factor * 2.5)) * normalize(LIGHT_COLOR) * ALBEDO;;
    }

    vec3 reflection_vector = (2.0 * dot(LIGHT, NORMAL) * NORMAL) - LIGHT;

    float spec_dot = max(0.0, dot(reflection_vector, VIEW));
    float specular_intensity = pow(spec_dot, shininess);

    // Applying ATTENUATION ensures the highlight respects shadows and light distance
    SPECULAR_LIGHT += SPECULAR_AMOUNT * specular_strength * step(0.5, specular_intensity) * (ATTENUATION/PI) * LIGHT_COLOR * 0.5 * ALBEDO;
}

