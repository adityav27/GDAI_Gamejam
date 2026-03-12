shader_type sky;
render_mode use_half_res_pass;

// --- Sky Colors ---
uniform vec4 sky_top_color      : source_color = vec4(0.01, 0.02, 0.08, 1.0);
uniform vec4 sky_mid_color      : source_color = vec4(0.04, 0.10, 0.18, 1.0);
uniform vec4 sky_horizon_color  : source_color = vec4(0.12, 0.28, 0.18, 1.0);
uniform vec4 horizon_glow_color : source_color = vec4(0.20, 0.55, 0.30, 1.0);

// --- Nebula / Cloud Colors ---
uniform vec4 nebula_color_a : source_color = vec4(0.45, 0.10, 0.55, 1.0);
uniform vec4 nebula_color_b : source_color = vec4(0.10, 0.55, 0.45, 1.0);
uniform vec4 nebula_color_c : source_color = vec4(0.70, 0.25, 0.10, 1.0);

// --- Nebula Settings ---
uniform float nebula_coverage  : hint_range(0.0, 1.0) = 0.48;
uniform float nebula_opacity   : hint_range(0.0, 1.0) = 0.72;
uniform float nebula_speed     : hint_range(0.0, 0.25) = 0.01;
uniform float nebula_scale     : hint_range(0.5, 5.0)  = 1.4;

// --- Stars ---
uniform float star_density     : hint_range(0.01, 0.9) = 0.072;
uniform float star_twinkle     : hint_range(0.0, 1.0) = 0.6;

// --- Gas Giant Moon ---
uniform bool  show_giant        = true;
uniform vec4  giant_color_a    : source_color = vec4(0.90, 0.92, 0.95, 1.0);
uniform vec4  giant_color_b    : source_color = vec4(0.75, 0.78, 0.82, 1.0);
uniform vec3  giant_direction  = vec3(-0.55, 0.38, -0.75);
uniform float giant_size       : hint_range(0.02, 0.25) = 0.09;
uniform float giant_glow_size  : hint_range(0.0, 0.3)  = 0.06;
uniform vec4  giant_glow_color : source_color = vec4(0.70, 0.75, 0.85, 1.0);

// -------------------------------------------------------
// Utility
// -------------------------------------------------------
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// -------------------------------------------------------
// Value noise
// -------------------------------------------------------
float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash21(i),                   hash21(i + vec2(1.0, 0.0)), u.x),
        mix(hash21(i + vec2(0.0, 1.0)),  hash21(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

// -------------------------------------------------------
// FBM
// -------------------------------------------------------
float fbm(vec2 p) {
    float f = 0.0;
    float w = 0.5;
    mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
    for (int i = 0; i < 7; i++) {
        f += w * vnoise(p);
        p  = rot * p * 2.1 + vec2(1.7, 9.2);
        w *= 0.5;
    }
    return f;
}

// -------------------------------------------------------
// Domain-warped FBM — swirling nebula look
// -------------------------------------------------------
float warp_fbm(vec2 p) {
    vec2 q = vec2(fbm(p + vec2(0.0, 0.0)),
                  fbm(p + vec2(5.2, 1.3)));
    vec2 r = vec2(fbm(p + 4.0 * q + vec2(1.7, 9.2)),
                  fbm(p + 4.0 * q + vec2(8.3, 2.8)));
    return fbm(p + 4.0 * r);
}

// -------------------------------------------------------
// Star field — colorful alien stars
// -------------------------------------------------------
vec3 star_field(vec3 dir) {
    const float GRID = 550.0;
    vec2 uv = vec2(
        atan(dir.z, dir.x) / (2.0 * 3.14159265),
        asin(clamp(dir.y, -1.0, 1.0)) / 3.14159265
    ) + 0.5;

    vec2 grid_id = floor(uv * GRID);
    vec2 grid_uv = fract(uv * GRID);
    vec3 brightness = vec3(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2  offset  = vec2(float(x), float(y));
            vec2  cell_id = grid_id + offset;
            float h       = hash21(cell_id);
            if (h > star_density) continue;

            vec2  star_pos = hash22(cell_id + 73.1) - (grid_uv - offset);
            float dist     = length(star_pos);
            float sz       = 0.04 + 0.12 * hash21(cell_id + 19.3);
            float lum      = 0.5 + 0.5 * hash21(cell_id + 44.7);
            float twink    = 1.0 - star_twinkle * 0.5
                           + star_twinkle * 0.5 * sin(TIME * (2.5 + 6.0 * hash21(cell_id)) + hash21(cell_id) * 6.28);

            float point = lum * twink * smoothstep(sz, 0.0, dist);

            // Alien star tint: cyan, magenta, white, warm yellow
            float hue_choice = hash21(cell_id + 88.0);
            vec3 star_col;
            if (hue_choice < 0.25)      star_col = vec3(0.5, 1.0, 0.9);  // cyan
            else if (hue_choice < 0.50) star_col = vec3(1.0, 0.5, 0.9);  // magenta
            else if (hue_choice < 0.75) star_col = vec3(1.0, 1.0, 0.8);  // warm white
            else                         star_col = vec3(0.7, 0.9, 1.0);  // cool blue

            brightness += point * star_col;
        }
    }
    return clamp(brightness, vec3(0.0), vec3(1.0));
}

// -------------------------------------------------------
// Gas giant disk with banded texture
// -------------------------------------------------------
vec3 draw_giant(vec3 dir) {
    vec3  gdir = normalize(giant_direction);
    float ang  = acos(clamp(dot(dir, gdir), -1.0, 1.0));
    float edge = giant_size;

    // Glow halo
    float glow  = smoothstep(edge + giant_glow_size, edge, ang) * 0.6;
    vec3  result = giant_glow_color.rgb * glow;

    // Disk
    if (ang < edge) {
        // UV on disk face
        vec3 right = normalize(cross(gdir, vec3(0.0, 1.0, 0.0)));
        vec3 up    = cross(right, gdir);
        vec2 disk_uv = vec2(dot(dir - gdir, right), dot(dir - gdir, up)) / edge;
        disk_uv = disk_uv * 0.5 + 0.5;

        // Horizontal bands via noise + smooth stripes
        float band_y    = disk_uv.y;
        float band_n    = vnoise(vec2(band_y * 12.0, TIME * 0.02)) * 0.08;
        float stripe    = 0.5 + 0.5 * sin((band_y + band_n) * 18.0);
        float swirl_n   = fbm(disk_uv * 4.0 + vec2(TIME * 0.01, 0.0)) * 0.3;
        vec3  band_col  = mix(giant_color_a.rgb, giant_color_b.rgb, clamp(stripe + swirl_n, 0.0, 1.0));

        // Limb darkening
        float limb = 1.0 - smoothstep(0.55, 1.0, length(disk_uv * 2.0 - 1.0));
        limb = pow(limb, 0.5);

        float mask = smoothstep(edge, edge * 0.97, ang);
        result += band_col * limb * mask;
    }
    return result;
}

// -------------------------------------------------------
// Main
// -------------------------------------------------------
void sky() {
    vec3 dir = EYEDIR;

    // --- Sky gradient ---
    float t_mid  = clamp(dir.y * 2.0, 0.0, 1.0);
    float t_top  = clamp(dir.y * 1.4, 0.0, 1.0);
    float t_glow = pow(clamp(1.0 - abs(dir.y) * 6.0, 0.0, 1.0), 3.0); // horizon band

    vec3 sky = mix(sky_horizon_color.rgb, sky_mid_color.rgb, sqrt(t_mid));
    sky       = mix(sky, sky_top_color.rgb, t_top * t_top);
    sky      += horizon_glow_color.rgb * t_glow * 0.6;

    // --- Nebula layer (three overlapping domains, coloured) ---
    float proj    = max(abs(dir.y), 0.015);
    vec2  neb_uv  = (dir.xz / proj) * (0.14 / nebula_scale);
    neb_uv.x     += TIME * nebula_speed;

    float na = warp_fbm(neb_uv);
    float nb = warp_fbm(neb_uv * 1.3 + vec2(3.1, 7.4));
    float nc = warp_fbm(neb_uv * 0.7 + vec2(12.0, 2.5));

    float threshold = 1.0 - nebula_coverage;

    // Three independently masked nebula regions
    float m_a = smoothstep(threshold, threshold + 0.35, na);
    float m_b = smoothstep(threshold + 0.08, threshold + 0.40, nb) * 0.7;
    float m_c = smoothstep(threshold + 0.12, threshold + 0.38, nc) * 0.5;

    vec3 nebula_col = nebula_color_a.rgb * m_a
                    + nebula_color_b.rgb * m_b
                    + nebula_color_c.rgb * m_c;
    float nebula_alpha = clamp(m_a + m_b + m_c, 0.0, 1.0) * nebula_opacity;

    // Fade nebula near horizon
    float neb_fade = smoothstep(-0.10, 0.15, dir.y)
                   * smoothstep(0.95,  0.50, dir.y);
    nebula_alpha  *= neb_fade;

    // Nebula occludes sky slightly
    sky = mix(sky, sky * 0.6 + nebula_col, nebula_alpha);

    // --- Stars ---
    float star_vis = smoothstep(-0.04, 0.10, dir.y);
    vec3  stars    = star_field(dir) * star_vis;

    // Stars dim inside dense nebula
    float neb_occlude = clamp(m_a * 1.2, 0.0, 1.0) * neb_fade;
    stars *= (1.0 - neb_occlude * 0.85);

    // --- Gas Giant ---
    vec3 giant = vec3(0.0);
    if (show_giant) {
        giant = draw_giant(dir);
    }

    // Final composite
    COLOR = sky + stars + giant;
}
