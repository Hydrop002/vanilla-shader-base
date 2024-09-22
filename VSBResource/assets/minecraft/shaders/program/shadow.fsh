#version 400

uniform sampler2D DiffuseSampler;
uniform sampler2D PrevShadowSampler;
uniform sampler2D DiffuseDepthSampler;

uniform mat4 ProjMat;
uniform vec2 OutSize;
uniform float Time;

in vec2 texCoord;

float gametime;

out vec4 fragColor;

uint readFromColor0(uvec3 u1, uvec3 u2, uvec3 u3, uvec3 u4) {
    uint ux;
    ux = bitfieldInsert(ux, u1.r, 0, 8);
    ux = bitfieldInsert(ux, u1.g, 8, 8);
    ux = bitfieldInsert(ux, u1.b, 16, 8);
    ux = bitfieldInsert(ux, u2.r, 24, 8);
    return ux;
}

uint readFromColor1(uvec3 u1, uvec3 u2, uvec3 u3, uvec3 u4) {
    uint uy;
    uy = bitfieldInsert(uy, u2.g, 0, 8);
    uy = bitfieldInsert(uy, u2.b, 8, 8);
    uy = bitfieldInsert(uy, u3.r, 16, 8);
    uy = bitfieldInsert(uy, u3.g, 24, 8);
    return uy;
}

uint readFromColor2(uvec3 u1, uvec3 u2, uvec3 u3, uvec3 u4) {
    uint uz;
    uz = bitfieldInsert(uz, u3.b, 0, 8);
    uz = bitfieldInsert(uz, u4.r, 8, 8);
    uz = bitfieldInsert(uz, u4.g, 16, 8);
    uz = bitfieldInsert(uz, u4.b, 24, 8);
    return uz;
}

void main() {
    ivec2 baseUV = ivec2(floor(OutSize.x / 2.0), 0);
    ivec2 extraUV1 = ivec2(baseUV.x + 4, baseUV.y);
    ivec2 extraUV2 = ivec2(baseUV.x + 4, baseUV.y + 1);
    ivec2 extraUV3 = ivec2(baseUV.x + 4, baseUV.y + 2);
    ivec2 extraUV4 = ivec2(baseUV.x + 4, baseUV.y + 3);

    uvec3 u1, u2, u3, u4;
    u1 = uvec3(texelFetch(DiffuseSampler, extraUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, extraUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, extraUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, extraUV4, 0).rgb * 255.0);
    gametime = uintBitsToFloat(readFromColor0(u1, u2, u3, u4));  // [0,1]d

    if (mod(gametime * 300000.0, 2.0) < 1.0) {
        fragColor = texture(PrevShadowSampler, texCoord);
    } else {
        fragColor = texture(DiffuseSampler, texCoord);
        if (texture(DiffuseDepthSampler, texCoord).r > 0.9) fragColor = vec4(1.0);
    }
}
