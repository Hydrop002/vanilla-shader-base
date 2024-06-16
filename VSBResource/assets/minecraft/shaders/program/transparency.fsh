#version 400

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;

uniform mat4 ProjMat;
uniform vec2 OutSize;
uniform float Time;

in vec2 texCoord;

#define NUM_LAYERS 6

vec4 color_layers[NUM_LAYERS];
float depth_layers[NUM_LAYERS];
int active_layers = 0;

mat4 proj;
mat4 projInv;
mat3 view;
mat3 viewInv;

out vec4 fragColor;

void try_insert( vec4 color, float depth ) {
    if ( color.a == 0.0 ) {
        return;
    }

    color_layers[active_layers] = color;
    depth_layers[active_layers] = depth;

    int jj = active_layers++;
    int ii = jj - 1;
    while ( jj > 0 && depth_layers[jj] > depth_layers[ii] ) {
        float depthTemp = depth_layers[ii];
        depth_layers[ii] = depth_layers[jj];
        depth_layers[jj] = depthTemp;

        vec4 colorTemp = color_layers[ii];
        color_layers[ii] = color_layers[jj];
        color_layers[jj] = colorTemp;

        jj = ii--;
    }
}

vec3 blend( vec3 dst, vec4 src ) {
    return ( dst * ( 1.0 - src.a ) ) + src.rgb;
}

float get_depth_accum(vec2 uv) {
    color_layers[0] = texture( DiffuseSampler, uv );
    depth_layers[0] = texture( DiffuseDepthSampler, uv ).r;
    active_layers = 1;

    try_insert( texture( TranslucentSampler, uv ), texture( TranslucentDepthSampler, uv ).r );
    try_insert( texture( ItemEntitySampler, uv ), texture( ItemEntityDepthSampler, uv ).r );
    try_insert( texture( ParticlesSampler, uv ), texture( ParticlesDepthSampler, uv ).r );
    try_insert( texture( WeatherSampler, uv ), texture( WeatherDepthSampler, uv ).r );
    try_insert( texture( CloudsSampler, uv ), texture( CloudsDepthSampler, uv ).r );
    
    return depth_layers[active_layers - 1];
}

vec3 get_texel_accum(vec2 uv, inout float depthAccum) {
    depthAccum = get_depth_accum(uv);
    vec3 texelAccum = color_layers[0].rgb;
    for ( int ii = 1; ii < active_layers; ++ii ) {
        texelAccum = blend( texelAccum, color_layers[ii] );
    }
    return texelAccum;
}

float depth2dist(float depth) {
    float depth_ndc = depth * 2.0 - 1.0;
    float n = 0.05;
    float f = 768.0;
    return 2.0 * f * n / (f + n - (f - n) * depth_ndc);
}

vec3 screen2view(vec2 uv, float z) {
    vec3 pos_ndc = vec3(uv, z) * 2.0 - 1.0;
    vec4 view_pos = inverse(proj) * vec4(pos_ndc, 1.0);
    return view_pos.xyz / view_pos.w;
}

vec3 view2screen(vec3 pos) {
    vec4 pos_ndc = proj * vec4(pos, 1.0);
    pos_ndc /= pos_ndc.w;
    return (pos_ndc.xyz + 1.0) / 2.0;
}

vec3 raytrace(vec3 pos, vec3 normal) {
    vec3 refDir = reflect(normalize(pos), normal);
    vec3 stp = refDir * 0.1;
    pos += stp;
    // pos += normal * 0.075;
    vec3 screenPos;
    int j = 0;
    for (int i = 0; i < 30; ++i) {
        screenPos = view2screen(view * pos);
        if (screenPos.x < -0.05 || screenPos.x > 1.05 || screenPos.y < -0.05 || screenPos.y > 1.05) break;
        float dist = depth2dist(screenPos.z);
        // float depthDiffuse = get_depth_accum(screenPos.xy);
        float depthDiffuse = texture(DiffuseDepthSampler, screenPos.xy).r;
        float distDiffuse = depth2dist(depthDiffuse);
        float maxErr = length(stp);
        if (abs(dist - distDiffuse) < maxErr) {
            if (j++ >= 4) break;
            pos -= stp;
            stp *= 0.1;
        }
        stp *= 1.2;
        pos += stp;
    }
    return screenPos;
}

vec2 rand2to2(vec2 pos) {  // [-1,1]
    vec2 rand = vec2(0.0);
	rand.x = fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 238.5453);
	rand.y = fract(sin(dot(pos, vec2(0.5161573, 0.4346789))) * 252.4022);
    return rand * 2.0 - 1.0;
}

float perlin2d(vec2 pos) {  // [-1,1]
    vec2 node = floor(pos);
    vec2 t = fract(pos);
    float n00 = dot(t, rand2to2(node));
    float n01 = dot(vec2(t.x, t.y - 1.0), rand2to2(node + vec2(0.0, 1.0)));
    float n10 = dot(vec2(t.x - 1.0, t.y), rand2to2(node + vec2(1.0, 0.0)));
    float n11 = dot(t - 1.0, rand2to2(node + vec2(1.0, 1.0)));
    t = t * t * (3.0 - 2.0 * t);
    float n0 = mix(n00, n01, t.y);
    float n1 = mix(n10, n11, t.y);
    return mix(n0, n1, t.x);
}


float get_water_height(vec3 pos, vec2 offset, float time) {
    vec2 wind = vec2(time * 0.5);
    pos.xz -= pos.y * 0.2;
	float noise1 = perlin2d((pos.xz - wind) + offset) * 0.5 + 0.5;
	float noise2 = perlin2d((pos.xz + wind) * 2.6667 + offset) * 0.5 + 0.5;
	noise1 *= noise1;
	noise2 *= noise2;
	return mix(noise1, noise2, 0.25) * 0.2;
}

vec3 get_water_normal(vec3 pos, float time) {
	float he = get_water_height(pos, vec2(0.2, 0.0), time);
	float hw = get_water_height(pos, vec2(-0.2, 0.0), time);
	float hs = get_water_height(pos, vec2(0.0, 0.2), time);
	float hn = get_water_height(pos, vec2(0.0, -0.2), time);
	float dx = (hw - he) / 0.2;
	float dz = (hn - hs) / 0.2;
	vec3 normal = vec3(dx, 1.0 - (dx * dx + dz * dz), dz);
	return normalize(normal * 0.35 + vec3(0.0, 0.65, 0.0));
}

void rotate_water_normal(inout vec3 waterNormal, vec3 normal) {
    vec4 q = normalize(vec4(normal.z, 0.0, -normal.x, normal.y + 1.0));
    if (q.w < 0.001) q = vec4(0.0, 0.0, 1.0, 0.0);
    vec4 t = vec4(0.0);
    t.x = q.w * waterNormal.x + q.y * waterNormal.z - q.z * waterNormal.y;
    t.y = q.w * waterNormal.y + q.z * waterNormal.x - q.x * waterNormal.z;
    t.z = q.w * waterNormal.z + q.x * waterNormal.y - q.y * waterNormal.x;
    t.w = -q.x * waterNormal.x - q.y * waterNormal.y - q.z * waterNormal.z;
    waterNormal.x = t.x * q.w - t.w * q.x - t.y * q.z + t.z * q.y;
    waterNormal.y = t.y * q.w - t.w * q.y - t.z * q.x + t.x * q.z;
    waterNormal.z = t.z * q.w - t.w * q.z - t.x * q.y + t.y * q.x;
}

void main() {
    float depthAccum;
    vec3 texelAccum = get_texel_accum(texCoord, depthAccum);
    fragColor = vec4( texelAccum, 1.0 );

    vec4 translucentColor = texture( TranslucentSampler, texCoord );
    float translucentDepth = texture( TranslucentDepthSampler, texCoord ).r;
    bool isWater = false;
    if (round(translucentColor.a * 255.0) == 180.0 && depthAccum == translucentDepth) isWater = true;

    ivec2 baseUV = ivec2(floor(OutSize.x / 2.0), 0);
    ivec2 posUV1 = baseUV;
    ivec2 posUV2 = ivec2(baseUV.x, baseUV.y + 1);
    ivec2 posUV3 = ivec2(baseUV.x, baseUV.y + 2);
    ivec2 posUV4 = ivec2(baseUV.x, baseUV.y + 3);
    ivec2 rotZUV1 = ivec2(baseUV.x + 1, baseUV.y);
    ivec2 rotZUV2 = ivec2(baseUV.x + 1, baseUV.y + 1);
    ivec2 rotZUV3 = ivec2(baseUV.x + 1, baseUV.y + 2);
    ivec2 rotZUV4 = ivec2(baseUV.x + 1, baseUV.y + 3);
    ivec2 rotYUV1 = ivec2(baseUV.x + 2, baseUV.y);
    ivec2 rotYUV2 = ivec2(baseUV.x + 2, baseUV.y + 1);
    ivec2 rotYUV3 = ivec2(baseUV.x + 2, baseUV.y + 2);
    ivec2 rotYUV4 = ivec2(baseUV.x + 2, baseUV.y + 3);
    ivec2 miscUV1 = ivec2(baseUV.x + 3, baseUV.y);
    ivec2 miscUV2 = ivec2(baseUV.x + 3, baseUV.y + 1);
    ivec2 miscUV3 = ivec2(baseUV.x + 3, baseUV.y + 2);
    ivec2 miscUV4 = ivec2(baseUV.x + 3, baseUV.y + 3);

    uvec3 u1, u2, u3, u4;
    uint ux, uy, uz;

    vec3 pos;  // [0,128]
    u1 = uvec3(texelFetch(DiffuseSampler, posUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, posUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, posUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, posUV4, 0).rgb * 255.0);
    ux = bitfieldInsert(ux, u1.r, 0, 8);
    ux = bitfieldInsert(ux, u1.g, 8, 8);
    ux = bitfieldInsert(ux, u1.b, 16, 8);
    ux = bitfieldInsert(ux, u2.r, 24, 8);
    pos.x = uintBitsToFloat(ux);
    uy = bitfieldInsert(uy, u2.g, 0, 8);
    uy = bitfieldInsert(uy, u2.b, 8, 8);
    uy = bitfieldInsert(uy, u3.r, 16, 8);
    uy = bitfieldInsert(uy, u3.g, 24, 8);
    pos.y = uintBitsToFloat(uy);
    uz = bitfieldInsert(uz, u3.b, 0, 8);
    uz = bitfieldInsert(uz, u4.r, 8, 8);
    uz = bitfieldInsert(uz, u4.g, 16, 8);
    uz = bitfieldInsert(uz, u4.b, 24, 8);
    pos.z = uintBitsToFloat(uz);
    vec3 viewZ;
    u1 = uvec3(texelFetch(DiffuseSampler, rotZUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, rotZUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, rotZUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, rotZUV4, 0).rgb * 255.0);
    ux = bitfieldInsert(ux, u1.r, 0, 8);
    ux = bitfieldInsert(ux, u1.g, 8, 8);
    ux = bitfieldInsert(ux, u1.b, 16, 8);
    ux = bitfieldInsert(ux, u2.r, 24, 8);
    viewZ.x = uintBitsToFloat(ux);
    uy = bitfieldInsert(uy, u2.g, 0, 8);
    uy = bitfieldInsert(uy, u2.b, 8, 8);
    uy = bitfieldInsert(uy, u3.r, 16, 8);
    uy = bitfieldInsert(uy, u3.g, 24, 8);
    viewZ.y = uintBitsToFloat(uy);
    uz = bitfieldInsert(uz, u3.b, 0, 8);
    uz = bitfieldInsert(uz, u4.r, 8, 8);
    uz = bitfieldInsert(uz, u4.g, 16, 8);
    uz = bitfieldInsert(uz, u4.b, 24, 8);
    viewZ.z = uintBitsToFloat(uz);
    vec3 viewY;
    u1 = uvec3(texelFetch(DiffuseSampler, rotYUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, rotYUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, rotYUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, rotYUV4, 0).rgb * 255.0);
    ux = bitfieldInsert(ux, u1.r, 0, 8);
    ux = bitfieldInsert(ux, u1.g, 8, 8);
    ux = bitfieldInsert(ux, u1.b, 16, 8);
    ux = bitfieldInsert(ux, u2.r, 24, 8);
    viewY.x = uintBitsToFloat(ux);
    uy = bitfieldInsert(uy, u2.g, 0, 8);
    uy = bitfieldInsert(uy, u2.b, 8, 8);
    uy = bitfieldInsert(uy, u3.r, 16, 8);
    uy = bitfieldInsert(uy, u3.g, 24, 8);
    viewY.y = uintBitsToFloat(uy);
    uz = bitfieldInsert(uz, u3.b, 0, 8);
    uz = bitfieldInsert(uz, u4.r, 8, 8);
    uz = bitfieldInsert(uz, u4.g, 16, 8);
    uz = bitfieldInsert(uz, u4.b, 24, 8);
    viewY.z = uintBitsToFloat(uz);
    vec3 viewX = cross(viewY, viewZ);
    u1 = uvec3(texelFetch(DiffuseSampler, miscUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, miscUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, miscUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, miscUV4, 0).rgb * 255.0);
    ux = bitfieldInsert(ux, u1.r, 0, 8);
    ux = bitfieldInsert(ux, u1.g, 8, 8);
    ux = bitfieldInsert(ux, u1.b, 16, 8);
    ux = bitfieldInsert(ux, u2.r, 24, 8);
    float cot = uintBitsToFloat(ux);
    uy = bitfieldInsert(uy, u2.g, 0, 8);
    uy = bitfieldInsert(uy, u2.b, 8, 8);
    uy = bitfieldInsert(uy, u3.r, 16, 8);
    uy = bitfieldInsert(uy, u3.g, 24, 8);
    float gametime = uintBitsToFloat(uy);  // [0,1200]s
    uz = bitfieldInsert(uz, u3.b, 0, 8);
    uz = bitfieldInsert(uz, u4.r, 8, 8);
    uz = bitfieldInsert(uz, u4.g, 16, 8);
    uz = bitfieldInsert(uz, u4.b, 24, 8);
    float daytime = uintBitsToFloat(uz);  // [0,1]d

    float aspect = OutSize.x / OutSize.y;
    float n = 0.05;
    float f = 768.0;
    proj = mat4(cot / aspect, 0.0, 0.0, 0.0,
                0.0, cot, 0.0, 0.0,
                0.0, 0.0, -(f + n) / (f - n), -1.0,
                0.0, 0.0, -2.0 * f * n / (f - n), 0.0);
    projInv = inverse(proj);

    viewInv = mat3(viewX, viewY, viewZ);
    view = transpose(viewInv);
    vec3 viewPos = screen2view(texCoord, depthAccum);
    vec3 worldPos = viewInv * viewPos;

    if (isWater) {
        vec3 normal = normalize(cross(dFdx(worldPos), dFdy(worldPos)));
        vec3 waterNormal = get_water_normal(worldPos - pos, gametime);
        rotate_water_normal(waterNormal, normal);
        vec3 screenPos = raytrace(worldPos, waterNormal);
        float refDepth;
        vec3 refColor = get_texel_accum(screenPos.xy, refDepth);
        float border = max(abs(screenPos.x - 0.5), abs(screenPos.y - 0.5));
        border = clamp(11.0 - border * 20.0, 0.0, 1.0);  // [0.5,0.55]->[1.0,0.0]
        if (screenPos.z > refDepth) border = 0.0;
        refColor = mix(vec3(0.4706, 0.6549, 1.0), refColor, border);
        float fresnel = pow(clamp(1.0 + dot(normalize(worldPos), normal), 0.0, 1.0), 5.0);
        fresnel = fresnel * 0.98 + 0.02;
        fragColor = vec4(mix(texelAccum, refColor, fresnel), 1.0);
    }
}
