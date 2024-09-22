#version 150

#moj_import <fog.glsl>
#moj_import <shadow.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec4 position;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, clamp(texCoord0, 0.0, 1.0));
    color *= vertexColor * ColorModulator;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
    if (is_marker(gl_FragCoord.xy, get_screen_size(gl_FragCoord.xy, position))) {
        discard;
    }
}
