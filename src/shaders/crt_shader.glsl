// src/shaders/crt_shader.glsl
extern number time;
extern vec2 screen_size;

extern number shake_intensity;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec2 uv = screen_coords / screen_size;
    
    // Scanlines (More pronounced)
    float scanline = sin(uv.y * screen_size.y * 3.14159) * 0.03;
    
    // Chromatic Aberration (Tied to shake, higher base)
    float chromOffset = 0.0015 + (shake_intensity * 0.008);
    float r = Texel(texture, uv + vec2(chromOffset, 0.0)).r;
    float g = Texel(texture, uv).g;
    float b = Texel(texture, uv - vec2(chromOffset, 0.0)).b;
    
    // Neon Bloom (Intense)
    vec4 bloom = Texel(texture, uv + vec2(0.004, 0.0)) + 
                 Texel(texture, uv - vec2(0.004, 0.0)) + 
                 Texel(texture, uv + vec2(0.0, 0.006)) + 
                 Texel(texture, uv - vec2(0.0, 0.006));
    bloom *= 0.25;
    float brightness = dot(bloom.rgb, vec3(0.299, 0.587, 0.114));
    vec3 finalBloom = bloom.rgb * smoothstep(0.3, 0.9, brightness) * 0.85;
    
    // Vignette
    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    vignette = clamp(pow(16.0 * vignette, 0.15), 0.0, 1.0);
    
    vec3 col = vec3(r, g, b);
    col += finalBloom; // Add glow
    col -= scanline;
    col *= vignette;
    
    return vec4(col, 1.0) * color;
}
