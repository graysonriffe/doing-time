shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo : hint_default_white;

void vertex() {

}

void fragment() {
	// Called for every pixel the material is visible on.
    EMISSION = vec3(1.0, 1.0, 5.0);
    ALPHA = texture(albedo, UV).a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
