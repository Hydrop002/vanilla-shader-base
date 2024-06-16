#version 400

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out float marker;
out vec3 pos;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexColor = Color;

    float alpha = round(vertexColor.a * 255.0);
    marker = float(alpha == 0.0);
    if (marker > 0.5) {
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
    }
}
