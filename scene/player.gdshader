shader_type spatial;

render_mode unshaded, depth_prepass_alpha, blend_mix, cull_back;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float distortion_strength = 0.02;
uniform float noise_scale = 10.0;
uniform float visibility = 0.2;

// shimmer control
uniform float shimmer_amount = 1.0;

// fringe controls
uniform vec3 fringe_color : source_color = vec3(0.3,0.7,1.0);
uniform float fringe_strength = 2.0;
uniform float fringe_width = 3.0;

void fragment() {

    vec2 uv = SCREEN_UV;

    // base screen color
    vec3 screen_color = texture(SCREEN_TEXTURE, uv).rgb;

    // shimmer distortion
    if (shimmer_amount > 0.0) {

        float noise = sin(uv.x * noise_scale + TIME) *
                      sin(uv.y * noise_scale + TIME);

        vec2 distortion = vec2(noise) * distortion_strength * shimmer_amount;

        vec3 distorted_color = texture(SCREEN_TEXTURE, uv + distortion).rgb;

        screen_color = mix(screen_color, distorted_color, shimmer_amount);
    }

    // -------- Fringe / outline effect --------

    float fresnel = pow(1.0 - dot(NORMAL, VIEW), fringe_width);

    vec3 fringe = fringe_color * fresnel * fringe_strength * shimmer_amount;

    vec3 final_color = screen_color + fringe;

    // output
    ALBEDO = final_color;

    ALPHA = 0.75 + visibility * shimmer_amount + (1.0 - shimmer_amount) * 1.0;
}