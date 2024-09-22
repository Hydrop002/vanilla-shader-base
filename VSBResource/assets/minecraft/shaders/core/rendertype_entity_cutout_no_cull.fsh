#version 150

#moj_import <fog.glsl>
#moj_import <shadow.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float GameTime;
uniform mat4 ProjMat;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 position;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1) {
        discard;
    }
    if (is_main_frame(GameTime) || is_ui(ProjMat) || is_hand(FogStart)) {
        color *= vertexColor * ColorModulator;
        color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
        color *= lightMapColor;
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
    } else {
        fragColor = encode_depth(gl_FragCoord.z);
    }
    if (is_marker(gl_FragCoord.xy, get_screen_size(gl_FragCoord.xy, position))) {
        discard;
    }
}
