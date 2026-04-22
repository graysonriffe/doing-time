shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE: hint_normal_roughness_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, repeat_disable, filter_nearest;

uniform bool edge_only = true;

uniform float edge_threshold = 1.5;
uniform vec3 line_color: source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 background_color: source_color = vec3(0.408, 0.969, 0.694);

uniform sampler2D noise_texture;
global uniform bool pause_effect;

const mat3 sobel_y = mat3(
    vec3(1.0, 0.0, -1.0),
    vec3(2.0, 0.0, -2.0),
    vec3(1.0, 0.0, -1.0)
);

const mat3 sobel_x = mat3(
    vec3(1.0, 2.0, 1.0),
    vec3(0.0, 0.0, 0.0),
    vec3(-1.0, -2.0, -1.0)
);

float get_lin_depth(mat4 inv_proj, vec2 offset_uv) {
    float d = texture(DEPTH_TEXTURE, offset_uv).r;
    vec4 p = inv_proj * vec4(offset_uv * 2.0 - 1.0, d, 1.0);
    return -p.z / p.w;
}

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 normal = texture(NORMAL_TEXTURE, uv).rgb;
    normal = normal * 2.0 - 1.0;
    float depth = texture(DEPTH_TEXTURE, uv).r;
    vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
    vec3 pixel_position = upos.xyz / upos.w;
    depth = length(pixel_position) / 1000.0;
    vec2 offset = 2.0 / VIEWPORT_SIZE;
    
    vec3 n = texture(NORMAL_TEXTURE, uv + vec2(0.0, -offset.y)).rgb;
    vec3 s = texture(NORMAL_TEXTURE, uv + vec2(0.0, offset.y)).rgb;
    vec3 e = texture(NORMAL_TEXTURE, uv + vec2(offset.x, 0.0)).rgb;
    vec3 w = texture(NORMAL_TEXTURE, uv + vec2(-offset.x, 0.0)).rgb;
    vec3 nw = texture(NORMAL_TEXTURE, uv + vec2(-offset.x, -offset.y)).rgb;
    vec3 ne = texture(NORMAL_TEXTURE, uv + vec2(offset.x, -offset.y)).rgb;
    vec3 sw = texture(NORMAL_TEXTURE, uv + vec2(-offset.x, offset.y)).rgb;
    vec3 se = texture(NORMAL_TEXTURE, uv + vec2(offset.x, offset.y)).rgb;
    
    mat3 surrounding_pixels = mat3(
        vec3(length(nw-normal), length(n-normal), length(ne-normal)),
        vec3(length(w-normal), length(normal-normal), length(e-normal)),
        vec3(length(sw-normal), length(s-normal), length(se-normal))
    );
    
    float edge_x = dot(sobel_x[0], surrounding_pixels[0]) + dot(sobel_x[1], surrounding_pixels[1]) + dot(sobel_x[2], surrounding_pixels[2]);
    float edge_y = dot(sobel_y[0], surrounding_pixels[0]) + dot(sobel_y[1], surrounding_pixels[1]) + dot(sobel_y[2], surrounding_pixels[2]);
    
    float edge = sqrt(pow(edge_x, 2.0)+pow(edge_y, 2.0));
    
    // 1. Get linear depth for the center pixel
    float depth_center = texture(DEPTH_TEXTURE, uv).r;
    vec4 upos_center = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, depth_center, 1.0);
    float lin_depth_center = -upos_center.z / upos_center.w; // Actual distance in meters
    
    // Construct the matrix using linear differences
    mat3 d_surrounding_pixels = mat3(
        vec3(get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(-offset.x, -offset.y)), get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(0.0, -offset.y)), get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(offset.x, -offset.y))),
        vec3(get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(-offset.x, 0.0)), lin_depth_center, get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(offset.x, 0.0))),
        vec3(get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(-offset.x, offset.y)), get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(0.0, offset.y)), get_lin_depth(INV_PROJECTION_MATRIX, uv + vec2(offset.x, offset.y)))
    );
    
    // 3. Apply Sobel
    float d_edge_x = dot(sobel_x[0], d_surrounding_pixels[0]) + dot(sobel_x[1], d_surrounding_pixels[1]) + dot(sobel_x[2], d_surrounding_pixels[2]);
    float d_edge_y = dot(sobel_y[0], d_surrounding_pixels[0]) + dot(sobel_y[1], d_surrounding_pixels[1]) + dot(sobel_y[2], d_surrounding_pixels[2]);
    float d_edge = sqrt(d_edge_x * d_edge_x + d_edge_y * d_edge_y);
    
    // 4. Relative Thresholding
    // Adjusting by lin_depth_center ensures the "sensitivity" scales with distance
    float final_depth_edge = d_edge / (lin_depth_center);
    
    ALBEDO = texture(SCREEN_TEXTURE, uv).rgb;
    
    if (pause_effect) {
        float line = (pow(sin(mod(UV.y * -1.0 - TIME / 10.0, 1.0) * PI), 20.0) * 2.75);
        float ins = sin(mod(UV.y * 100.0, 1.0)*PI) - line;
        float dist = 1.0 - length((UV - vec2(0.5)) * 2.0);
        
        float t = TIME * 25.0;
        vec2 uv2 = UV + vec2(0.5, 0.5);
        vec2 uvnoise = vec2(uv2.x * cos(t) - uv2.y * sin(t), uv2.x * sin(t) + uv2.y * cos(t));
        vec4 noise = texture(noise_texture, uvnoise);
        ALBEDO *= (dist + 0.7) * ((ins * 0.30) + 1.0) * (noise.r * 0.55 + 0.35);
    }
    
    if (max(edge * 1.5, final_depth_edge * 2.0) > edge_threshold) {
        ALBEDO = line_color;
    }
    else {
        if (!edge_only){
            ALBEDO = background_color;
        }
    }
}