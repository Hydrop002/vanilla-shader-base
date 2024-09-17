#version 400

#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

out float vertexDistance;
out vec4 vertexColor;
out float marker0;
out float marker1;
out float marker2;
out float marker3;
out vec3 pos;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance(Position, FogShape);
    vertexColor = Color;

    float alpha = round(vertexColor.a * 255.0);
    marker0 = float(alpha == 0.0);
    marker1 = float(alpha == 1.0);
    marker2 = float(alpha == 2.0);
    marker3 = float(alpha == 3.0);
    if (marker0 > 0.5 || marker1 > 0.5 || marker2 > 0.5 || marker3 > 0.5) {
        vertexColor.a = 1.0;
        pos = Position;
        if (gl_VertexID == 0) {
            gl_Position = vec4(-1.0, 1.0, 0.0, 1.0);
        } else if (gl_VertexID == 1) {
            gl_Position = vec4(-1.0, -1.0, 0.0, 1.0);
        } else if (gl_VertexID == 2) {
            gl_Position = vec4(1.0, -1.0, 0.0, 1.0);
        } else {
            gl_Position = vec4(1.0, 1.0, 0.0, 1.0);
        }
    } else {
        vertexColor *= texelFetch(Sampler2, UV2 / 16, 0);
    }
}
