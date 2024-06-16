#version 400

uniform vec4 ColorModulator;
uniform vec2 ScreenSize;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float GameTime;

in vec4 vertexColor;
in float marker;
in vec3 pos;

out vec4 fragColor;

void main() {
    vec4 color = vertexColor;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = color * ColorModulator;

    vec2 uv = floor(gl_FragCoord.xy);
    vec2 baseUV = vec2(floor(ScreenSize.x / 2.0), 0.0);
    vec2 posUV1 = baseUV;
    vec2 posUV2 = vec2(baseUV.x, baseUV.y + 1.0);
    vec2 posUV3 = vec2(baseUV.x, baseUV.y + 2.0);
    vec2 posUV4 = vec2(baseUV.x, baseUV.y + 3.0);
    vec2 rotZUV1 = vec2(baseUV.x + 1.0, baseUV.y);
    vec2 rotZUV2 = vec2(baseUV.x + 1.0, baseUV.y + 1.0);
    vec2 rotZUV3 = vec2(baseUV.x + 1.0, baseUV.y + 2.0);
    vec2 rotZUV4 = vec2(baseUV.x + 1.0, baseUV.y + 3.0);
    vec2 rotYUV1 = vec2(baseUV.x + 2.0, baseUV.y);
    vec2 rotYUV2 = vec2(baseUV.x + 2.0, baseUV.y + 1.0);
    vec2 rotYUV3 = vec2(baseUV.x + 2.0, baseUV.y + 2.0);
    vec2 rotYUV4 = vec2(baseUV.x + 2.0, baseUV.y + 3.0);
    vec2 miscUV1 = vec2(baseUV.x + 3.0, baseUV.y);
    vec2 miscUV2 = vec2(baseUV.x + 3.0, baseUV.y + 1.0);
    vec2 miscUV3 = vec2(baseUV.x + 3.0, baseUV.y + 2.0);
    vec2 miscUV4 = vec2(baseUV.x + 3.0, baseUV.y + 3.0);
    if (uv.x == posUV1.x) {
        uint ux = floatBitsToUint(mod(pos.x, 128.0));
        uint uy = floatBitsToUint(mod(pos.y, 128.0));
        uint uz = floatBitsToUint(mod(pos.z, 128.0));
        vec3 c;
        if (uv.y == posUV1.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 0, 8)) / 255.0;
            c.g = float(bitfieldExtract(ux, 8, 8)) / 255.0;
            c.b = float(bitfieldExtract(ux, 16, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == posUV2.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 24, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 0, 8)) / 255.0;
            c.b = float(bitfieldExtract(uy, 8, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == posUV3.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uy, 16, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 24, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 0, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == posUV4.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uz, 8, 8)) / 255.0;
            c.g = float(bitfieldExtract(uz, 16, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 24, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else {
            discard;
        }
    } else if (uv.x == rotZUV1.x) {
        vec3 viewZ = vec3(ModelViewMat[0].z, ModelViewMat[1].z, ModelViewMat[2].z);
        uint ux = floatBitsToUint(viewZ.x);
        uint uy = floatBitsToUint(viewZ.y);
        uint uz = floatBitsToUint(viewZ.z);
        vec3 c;
        if (uv.y == rotZUV1.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 0, 8)) / 255.0;
            c.g = float(bitfieldExtract(ux, 8, 8)) / 255.0;
            c.b = float(bitfieldExtract(ux, 16, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == rotZUV2.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 24, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 0, 8)) / 255.0;
            c.b = float(bitfieldExtract(uy, 8, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == rotZUV3.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uy, 16, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 24, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 0, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == rotZUV4.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uz, 8, 8)) / 255.0;
            c.g = float(bitfieldExtract(uz, 16, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 24, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else {
            discard;
        }
    } else if (uv.x == rotYUV1.x) {
        vec3 viewY = vec3(ModelViewMat[0].y, ModelViewMat[1].y, ModelViewMat[2].y);
        uint ux = floatBitsToUint(viewY.x);
        uint uy = floatBitsToUint(viewY.y);
        uint uz = floatBitsToUint(viewY.z);
        vec3 c;
        if (uv.y == rotYUV1.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 0, 8)) / 255.0;
            c.g = float(bitfieldExtract(ux, 8, 8)) / 255.0;
            c.b = float(bitfieldExtract(ux, 16, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == rotYUV2.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 24, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 0, 8)) / 255.0;
            c.b = float(bitfieldExtract(uy, 8, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == rotYUV3.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uy, 16, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 24, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 0, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == rotYUV4.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uz, 8, 8)) / 255.0;
            c.g = float(bitfieldExtract(uz, 16, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 24, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else {
            discard;
        }
    } else if (uv.x == miscUV1.x) {
        float cot = ProjMat[1][1];
        float gametime = GameTime * 1200.0;
        float daytime = dot(round(vertexColor.rgb * 255.0), vec3(65536.0, 256.0, 1.0)) / 24000.0;
        uint ux = floatBitsToUint(cot);
        uint uy = floatBitsToUint(gametime);
        uint uz = floatBitsToUint(daytime);
        vec3 c;
        if (uv.y == miscUV1.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 0, 8)) / 255.0;
            c.g = float(bitfieldExtract(ux, 8, 8)) / 255.0;
            c.b = float(bitfieldExtract(ux, 16, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == miscUV2.y && marker > 0.5) {
            c.r = float(bitfieldExtract(ux, 24, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 0, 8)) / 255.0;
            c.b = float(bitfieldExtract(uy, 8, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == miscUV3.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uy, 16, 8)) / 255.0;
            c.g = float(bitfieldExtract(uy, 24, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 0, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else if (uv.y == miscUV4.y && marker > 0.5) {
            c.r = float(bitfieldExtract(uz, 8, 8)) / 255.0;
            c.g = float(bitfieldExtract(uz, 16, 8)) / 255.0;
            c.b = float(bitfieldExtract(uz, 24, 8)) / 255.0;
            fragColor = vec4(c, 1.0);
        } else {
            discard;
        }
    } else {
        discard;
    }
}
