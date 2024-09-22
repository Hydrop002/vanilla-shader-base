#version 150

#moj_import <fog.glsl>
#moj_import <shadow.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec4 position;

out vec4 fragColor;

void main() {
    if (is_main_frame(GameTime)) {
        vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
    } else {
        fragColor = encode_depth(gl_FragCoord.z);
    }
    if (is_marker(gl_FragCoord.xy, get_screen_size(gl_FragCoord.xy, position))) {
        discard;
    }
}
