#version 400

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec2 ScreenSize;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in float marker0;
in float marker1;
in float marker2;
in float marker3;
in vec3 pos;

out vec4 fragColor;

vec3 writeToColor0(uint ux, uint uy, uint uz) {
    vec3 c;
    c.r = float(bitfieldExtract(ux, 0, 8)) / 255.0;
    c.g = float(bitfieldExtract(ux, 8, 8)) / 255.0;
    c.b = float(bitfieldExtract(ux, 16, 8)) / 255.0;
    return c;
}

vec3 writeToColor1(uint ux, uint uy, uint uz) {
    vec3 c;
    c.r = float(bitfieldExtract(ux, 24, 8)) / 255.0;
    c.g = float(bitfieldExtract(uy, 0, 8)) / 255.0;
    c.b = float(bitfieldExtract(uy, 8, 8)) / 255.0;
    return c;
}

vec3 writeToColor2(uint ux, uint uy, uint uz) {
    vec3 c;
    c.r = float(bitfieldExtract(uy, 16, 8)) / 255.0;
    c.g = float(bitfieldExtract(uy, 24, 8)) / 255.0;
    c.b = float(bitfieldExtract(uz, 0, 8)) / 255.0;
    return c;
}

vec3 writeToColor3(uint ux, uint uy, uint uz) {
    vec3 c;
    c.r = float(bitfieldExtract(uz, 8, 8)) / 255.0;
    c.g = float(bitfieldExtract(uz, 16, 8)) / 255.0;
    c.b = float(bitfieldExtract(uz, 24, 8)) / 255.0;
    return c;
}

void main() {
    vec4 color = vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

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
    vec2 projUV1 = vec2(baseUV.x + 3.0, baseUV.y);
    vec2 projUV2 = vec2(baseUV.x + 3.0, baseUV.y + 1.0);
    vec2 projUV3 = vec2(baseUV.x + 3.0, baseUV.y + 2.0);
    vec2 projUV4 = vec2(baseUV.x + 3.0, baseUV.y + 3.0);
    vec2 extraUV1 = vec2(baseUV.x + 4.0, baseUV.y);
    vec2 extraUV2 = vec2(baseUV.x + 4.0, baseUV.y + 1.0);
    vec2 extraUV3 = vec2(baseUV.x + 4.0, baseUV.y + 2.0);
    vec2 extraUV4 = vec2(baseUV.x + 4.0, baseUV.y + 3.0);
    vec2 fogUV1 = vec2(baseUV.x + 5.0, baseUV.y);
    vec2 fogUV2 = vec2(baseUV.x + 5.0, baseUV.y + 1.0);
    vec2 fogUV3 = vec2(baseUV.x + 5.0, baseUV.y + 2.0);
    vec2 fogUV4 = vec2(baseUV.x + 5.0, baseUV.y + 3.0);
    vec2 chunkPosUV1 = vec2(baseUV.x + 6.0, baseUV.y);
    vec2 chunkPosUV2 = vec2(baseUV.x + 6.0, baseUV.y + 1.0);
    vec2 chunkPosUV3 = vec2(baseUV.x + 6.0, baseUV.y + 2.0);
    vec2 extraUV5 = vec2(baseUV.x + 7.0, baseUV.y);
    vec2 extraUV6 = vec2(baseUV.x + 7.0, baseUV.y + 1.0);
    vec2 extraUV7 = vec2(baseUV.x + 7.0, baseUV.y + 2.0);
    bool marker = marker0 > 0.5 || marker1 > 0.5 || marker2 > 0.5 || marker3 > 0.5;
    if (uv.x == posUV1.x) {
        uint ux = floatBitsToUint(-pos.x);
        uint uy = floatBitsToUint(-pos.y);
        uint uz = floatBitsToUint(-pos.z);
        if (uv.y == posUV1.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor0(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == posUV2.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor1(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == posUV3.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor2(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == posUV4.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor3(ux, uy, uz), 1.0);
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (uv.x == rotZUV1.x) {
        vec3 viewZ = vec3(ModelViewMat[0].z, ModelViewMat[1].z, ModelViewMat[2].z);
        uint ux = floatBitsToUint(viewZ.x);
        uint uy = floatBitsToUint(viewZ.y);
        uint uz = floatBitsToUint(viewZ.z);
        if (uv.y == rotZUV1.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor0(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == rotZUV2.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor1(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == rotZUV3.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor2(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == rotZUV4.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor3(ux, uy, uz), 1.0);
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (uv.x == rotYUV1.x) {
        vec3 viewY = vec3(ModelViewMat[0].y, ModelViewMat[1].y, ModelViewMat[2].y);
        uint ux = floatBitsToUint(viewY.x);
        uint uy = floatBitsToUint(viewY.y);
        uint uz = floatBitsToUint(viewY.z);
        if (uv.y == rotYUV1.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor0(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == rotYUV2.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor1(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == rotYUV3.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor2(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == rotYUV4.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor3(ux, uy, uz), 1.0);
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (uv.x == projUV1.x) {
        float cot = ProjMat[1][1];
        float bobX = ProjMat[3][0];
        float bobY = ProjMat[3][1];
        uint ux = floatBitsToUint(cot);
        uint uy = floatBitsToUint(bobX);
        uint uz = floatBitsToUint(bobY);
        if (uv.y == projUV1.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor0(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == projUV2.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor1(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == projUV3.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor2(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == projUV4.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor3(ux, uy, uz), 1.0);
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (uv.x == extraUV1.x) {
        uint ux = floatBitsToUint(GameTime);
        uint uy = floatBitsToUint(FogStart);
        uint uz = floatBitsToUint(FogEnd);
        if (uv.y == extraUV1.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor0(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == extraUV2.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor1(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == extraUV3.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor2(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == extraUV4.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor3(ux, uy, uz), 1.0);
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (uv.x == fogUV1.x) {
        uint ux = floatBitsToUint(FogColor.x);
        uint uy = floatBitsToUint(FogColor.y);
        uint uz = floatBitsToUint(FogColor.z);
        if (uv.y == fogUV1.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor0(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == fogUV2.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor1(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == fogUV3.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor2(ux, uy, uz), 1.0);
            else discard;
        } else if (uv.y == fogUV4.y) {
            if (marker0 > 0.5) fragColor = vec4(writeToColor3(ux, uy, uz), 1.0);
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (uv.x == chunkPosUV1.x) {
        if (uv.y == chunkPosUV1.y) {
            if (marker1 > 0.5) fragColor = vertexColor;
            else discard;
        } else if (uv.y == chunkPosUV2.y) {
            if (marker2 > 0.5) fragColor = vertexColor;
            else discard;
        } else if (uv.y == chunkPosUV3.y) {
            if (marker3 > 0.5) fragColor = vertexColor;
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (uv.x == extraUV5.x) {
        if (uv.y == extraUV5.y) {  // daytime
            if (marker0 > 0.5) fragColor = vertexColor;
            else discard;
        } else if (marker) {
            discard;
        }
    } else if (marker) {
        discard;
    }
}
