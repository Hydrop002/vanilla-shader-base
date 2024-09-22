#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <shadow.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;
uniform float GameTime;
uniform float FogStart;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;
out vec4 position;

void main() {
    if (is_main_frame(GameTime) || is_ui(ProjMat) || is_hand(FogStart)) {
        gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    } else {
        gl_Position = get_shadow_position(Position, GameTime);
    }

    vertexDistance = fog_distance(Position, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord0 = UV0;
    position = gl_Position;
}
