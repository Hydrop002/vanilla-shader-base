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

#define CLOUD_HEIGHT 192.0
#define CLOUD_THICKNESS 128.0
#define SUN_COLOR vec3(1.0)
#define MOON_COLOR vec3(0.75, 0.83, 1.0)

const float pi = 3.1416;
const mat3 srgb_to_xyz = mat3(
	0.4124, 0.2126, 0.0193,
	0.3576, 0.7152, 0.1192,
	0.1805, 0.0722, 0.9505
);
const mat3 xyz_to_srgb = mat3(
	3.2406, -0.9689, 0.0557,
	-1.5372, 1.8758, -0.2040,
	-0.4986, 0.0415, 1.0570
);
const vec3 luminance = vec3(srgb_to_xyz[0][1], srgb_to_xyz[1][1], srgb_to_xyz[2][1]);
const vec3 luminance_gamma = vec3(0.299, 0.587, 0.114);

const float renderDistance = 12.0;
const float fogDistance = max(renderDistance * 16.0, 32.0);
const float n = 0.05;
const float f = renderDistance * 64.0;
const float minHeight = -64.0;
const vec3 plainsSkyColor = vec3(0.4706, 0.6549, 1.0);

mat4 proj;
mat4 projInv;
mat3 view;
mat3 viewInv;
float sunAngle;
vec3 sunVec;
vec3 lightVec;
vec3 cameraPos;
float gametime;
float rainStrength;

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

float linear_step(float a, float b, float x) {
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

vec3 linear_to_gamma(vec3 color) {
    return pow(color, vec3(1.0 / 2.2));
}

vec3 gamma_to_linear(vec3 color) {
    return pow(color, vec3(2.2));
}

float get_sun_angle(float daytime) {
    float a = fract(daytime - 0.25);
    float b = 0.5 - cos(a * pi) * 0.5;
    float t = (a * 2.0 + b) / 3.0;
    return fract(t + 0.25);
}

vec4 get_sunrise_color(float sunHeight) {
    float h = clamp(sunHeight, -0.4, 0.4) / 0.4 * 0.5 + 0.5;
    vec4 color;
    color.r = h * 0.3 + 0.7;
    color.g = h * h * 0.7 + 0.2;
    color.b = 0.2;
    color.a = 1.0 - (1.0 - sin(h * pi)) * 0.99;
    color.a *= color.a;
    return color;
}

float rand2to1(vec2 pos) {  // [0,1]
	vec3 rand = fract(pos.xyx * 0.1031);
    rand += dot(rand, rand.yzx + 33.33);
    return fract((rand.x + rand.y) * rand.z);
}

vec2 rand2to2(vec2 pos) {  // [0,1]
    vec3 rand = fract(vec3(pos.xyx) * vec3(0.1031, 0.1030, 0.0973));
    rand += dot(rand, rand.yzx + 33.33);
    return fract((rand.xx + rand.yz) * rand.zy);
}

vec2 rand3to2(vec3 pos) {  // [0,1]
	pos = fract(pos * vec3(0.1031, 0.1030, 0.0973));
    pos += dot(pos, pos.yzx + 33.33);
    return fract((pos.xx + pos.yz) * pos.zy);
}

vec3 rand3to3(vec3 pos) {  // [0,1]
    pos = fract(pos * vec3(0.1031, 0.1030, 0.0973));
    pos += dot(pos, pos.yxz + 33.33);
    return fract((pos.xxy + pos.yxx) * pos.zyx);
}

float perlin2d(vec2 pos) {  // [-1,1]
    vec2 node = floor(pos);
    vec2 t = fract(pos);
    float n00 = dot(t, rand2to2(node) * 2.0 - 1.0);
    float n01 = dot(vec2(t.x, t.y - 1.0), rand2to2(node + vec2(0.0, 1.0)) * 2.0 - 1.0);
    float n10 = dot(vec2(t.x - 1.0, t.y), rand2to2(node + vec2(1.0, 0.0)) * 2.0 - 1.0);
    float n11 = dot(t - 1.0, rand2to2(node + vec2(1.0, 1.0)) * 2.0 - 1.0);
    t = t * t * (3.0 - 2.0 * t);
    float n0 = mix(n00, n01, t.y);
    float n1 = mix(n10, n11, t.y);
    return mix(n0, n1, t.x);
}

float perlin3d(vec3 pos) {  // [-1,1]
    vec3 node = floor(pos);
    vec3 t = fract(pos);
    float n000 = dot(t, rand3to3(node) * 2.0 - 1.0);
    float n001 = dot(vec3(t.x, t.y, t.z - 1.0), rand3to3(node + vec3(0.0, 0.0, 1.0)) * 2.0 - 1.0);
    float n010 = dot(vec3(t.x, t.y - 1.0, t.z), rand3to3(node + vec3(0.0, 1.0, 0.0)) * 2.0 - 1.0);
    float n011 = dot(vec3(t.x, t.y - 1.0, t.z - 1.0), rand3to3(node + vec3(0.0, 1.0, 1.0)) * 2.0 - 1.0);
    float n100 = dot(vec3(t.x - 1.0, t.y, t.z), rand3to3(node + vec3(1.0, 0.0, 0.0)) * 2.0 - 1.0);
    float n101 = dot(vec3(t.x - 1.0, t.y, t.z - 1.0), rand3to3(node + vec3(1.0, 0.0, 1.0)) * 2.0 - 1.0);
    float n110 = dot(vec3(t.x - 1.0, t.y - 1.0, t.z), rand3to3(node + vec3(1.0, 1.0, 0.0)) * 2.0 - 1.0);
    float n111 = dot(t - 1.0, rand3to3(node + 1.0) * 2.0 - 1.0);
    t = t * t * (3.0 - 2.0 * t);
    float n00 = mix(n000, n001, t.z);
    float n01 = mix(n010, n011, t.z);
    float n10 = mix(n100, n101, t.z);
    float n11 = mix(n110, n111, t.z);
    float n0 = mix(n00, n01, t.y);
    float n1 = mix(n10, n11, t.y);
    return mix(n0, n1, t.x);
}

float worley2d(vec2 pos) {  // [0,1.414]
    vec2 base = floor(pos);
    float minDist = 999.0;
    for (int i = -1; i <= 1; ++i) {
        for (int j = -1; j <= 1; ++j) {
            vec2 node = base + vec2(i, j);
            vec2 p = node + rand2to2(node);
            float dist = distance(pos, p);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

float worley3d(vec3 pos) {  // [0,1.732]
    vec3 base = floor(pos);
    float minDist = 999.0;
    for (int i = -1; i <= 1; ++i) {
        for (int j = -1; j <= 1; ++j) {
            for(int k = -1; k <= 1; ++k) {
                vec3 node = base + vec3(i, j, k);
                vec3 p = node + rand3to3(node);
                float dist = distance(pos, p);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

float get_water_height(vec3 pos, vec2 offset) {
    vec2 wind = vec2(gametime * 0.5);
    pos.xz -= pos.y * 0.2;
    float noise1 = perlin2d((pos.xz - wind) + offset) * 0.5 + 0.5;
    float noise2 = perlin2d((pos.xz + wind) * 2.6667 + offset) * 0.5 + 0.5;
    noise1 *= noise1;
    noise2 *= noise2;
    return mix(noise1, noise2, 0.25) * 0.2;
}

vec3 get_water_normal(vec3 pos) {
    float he = get_water_height(pos, vec2(0.2, 0.0));
    float hw = get_water_height(pos, vec2(-0.2, 0.0));
    float hs = get_water_height(pos, vec2(0.0, 0.2));
    float hn = get_water_height(pos, vec2(0.0, -0.2));
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

float get_cloud_density(vec3 pos) {  // [0,1]
    if (pos.y < CLOUD_HEIGHT || pos.y > CLOUD_HEIGHT + CLOUD_THICKNESS) return 0.0;
    float altitude_fraction = (pos.y - CLOUD_HEIGHT) / CLOUD_THICKNESS;

    vec2 wind_velocity = 4.0 * vec2(0.866, 0.5);
    pos.xz += wind_velocity * (gametime + 5.0 * pow(altitude_fraction, 2.0));

    float noise = perlin2d(0.00512 * pos.xz) * 0.5 + 0.5;
    float amount = 1.0 - rainStrength;
    float density = 1.2 * linear_step(0.2, 1.0, noise * noise) * linear_step(0.5, 0.75, amount);
    density -= pow(linear_step(0.2, 1.0, altitude_fraction), 1.5) * 0.6;
    density *= smoothstep(0.0, 0.1, altitude_fraction);
    density *= smoothstep(0.0, 0.1, 1.0 - altitude_fraction);
    if (density < 1e-6) return 0.0;

    vec3 wind = vec3(wind_velocity * gametime * 4.0, 0.0).xzy;
    float worley_0 = perlin3d((pos + 0.2 * wind) * 0.0256) * 0.5 + 0.5;
    float worley_1 = perlin3d((pos + 0.4 * wind) * 0.16) * 0.5 + 0.5;
    float detail_fade = 0.20 * smoothstep(0.85, 1.0, 1.0 - altitude_fraction)
                      - 0.35 * smoothstep(0.05, 0.5, altitude_fraction) + 0.6;
    float t = clamp(1.0 - density, 0.0, 1.0);
    density -= 0.25 * worley_0 * worley_0 * t * (2.0 - t);
    t = clamp(1.0 - density, 0.0, 1.0);
    density -= 0.1 * worley_1 * worley_1 * t * (2.0 - t) * detail_fade;

    density = max(density, 0.0);
    density = 1.0 - pow(max(1.0 - density, 0.0), 7.0);
    return pow(density, 0.2);
}

float henyey_greenstein_phase(float cosTheta, float g) {
	float gg = g * g;
	return 0.25 / pi * (1.0 - gg) / pow(1.0 + gg - 2.0 * g * cosTheta, 1.5);
}

float klein_nishina_phase(float cosTheta, float e) {
	return e / (2.0 * pi * (e - e * cosTheta + 1.0) * log(2.0 * e + 1.0));
}

float single_scattering_phase(float cosTheta) {
    return 0.8 * klein_nishina_phase(cosTheta, 2600.0)
	     + 0.2 * henyey_greenstein_phase(cosTheta, -0.2);
}

float multi_scattering_phase(float cosTheta, vec3 g) {
    return 0.65 * henyey_greenstein_phase(cosTheta, g.x)
	     + 0.10 * henyey_greenstein_phase(cosTheta, g.y)
	     + 0.25 * henyey_greenstein_phase(cosTheta, -g.z);
}

float raymarch_light(vec3 start, vec3 dir, float dither, int count) {
	float stpLen = 0.1 * CLOUD_THICKNESS / float(count);
	vec3 rayPos = start;
	vec3 stp = dir * stpLen;
	float optical_depth = 0.0;
	for (int i = 0; i < count; ++i, rayPos += stp) {
        stpLen *= 2.0;
		stp *= 2.0;
		optical_depth += get_cloud_density(rayPos + stp * dither) * stpLen;
	}
	return optical_depth;
}

vec3 raymarch(vec3 start, vec3 dir, float len) {
    int count = 40;
    float stpLen = len / float(count);
    vec3 stp = dir * stpLen;
    float sunlight = 0.0;
    float skylight = 0.0;
    float transmittance = 1.0;
    float extinction_coeff = 0.08;  // absorption + scattering
    float scattering_coeff = extinction_coeff * (1.0 - 0.33 * rainStrength);
    float vol = dot(dir, lightVec);
    bool intersect = false;
    float bottom_fade = 1.0;
    float horizon_fade = 1.0;
    for (int i = 0; i < count; ++i) {
        if (transmittance < 0.075) break;
        vec3 rayPos = start + stp * (float(i) + rand2to1(gl_FragCoord.xy));
        float altitude_fraction = (rayPos.y - CLOUD_HEIGHT) / CLOUD_THICKNESS;
        float density = get_cloud_density(rayPos);
        if (density < 1e-6) continue;
        else if (!intersect) {
            intersect = true;
            bottom_fade = mix(clamp(altitude_fraction * 5.0, 0.0, 1.0), 1.0, max(max(1.0 - abs(sunVec.y) * 10.0, vol), 0.0));
            horizon_fade = linear_step(5000.0, 1000.0, distance(rayPos.xz, cameraPos.xz));
        }
        float step_optical_depth = density * stpLen;
		float step_transmittance = exp(-step_optical_depth * extinction_coeff);
        vec2 rand = rand3to2(rayPos);
        float light_optical_depth = raymarch_light(rayPos, lightVec, rand.x, 6);
        float sky_optical_depth = raymarch_light(rayPos, vec3(0.0, 1.0, 0.0), rand.y, 2);
        
        vec2 total_radiance = vec2(0.0);
        float extinction_multi = extinction_coeff;
        float scattering_multi = scattering_coeff;
        float powder_effect = 2.0 * pi * density / (2.0 * density + 0.15);
        powder_effect = mix(powder_effect, 1.0, 0.8 * pow(vol * 0.5 + 0.5, 2.0));
        float probability = single_scattering_phase(vol);
        vec3 g = pow(vec3(0.6, 0.9, 0.3), vec3(1.0 + light_optical_depth));
        for (int j = 0; j < 8; ++j) {
            total_radiance.x += scattering_multi * exp(-light_optical_depth * extinction_multi * 0.33) * probability;
            total_radiance.y += scattering_multi * exp(-sky_optical_depth * extinction_multi * 0.33) * 0.25 / pi;
            float x = clamp(scattering_coeff / 0.1, 0.0, 1.0);
            scattering_multi *= 0.55 * mix((x + x * 0.33) / (1.0 + x * 0.33), 1.0, vol * 0.5 + 0.5) * powder_effect;
            extinction_multi *= 0.5;
            g *= 0.5;
            powder_effect = mix(powder_effect, sqrt(powder_effect), 0.5);
            probability = multi_scattering_phase(vol, g);
        }
        total_radiance *= (1.0 - step_transmittance) / extinction_coeff;  // ?
        sunlight += total_radiance.x * transmittance;
        skylight += total_radiance.y * transmittance;

        transmittance *= step_transmittance;
    }
    transmittance = linear_step(0.075, 1.0, transmittance);
    transmittance = mix(1.0, transmittance, bottom_fade);
    sunlight *= bottom_fade;
    skylight *= bottom_fade;
    transmittance = mix(1.0, transmittance, horizon_fade);
    sunlight *= horizon_fade;
    skylight *= horizon_fade;
    return vec3(sunlight, skylight, transmittance);
}

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
    ivec2 fovYUV1 = ivec2(baseUV.x + 3, baseUV.y);
    ivec2 fovYUV2 = ivec2(baseUV.x + 3, baseUV.y + 1);
    ivec2 extraUV1 = ivec2(baseUV.x + 4, baseUV.y);
    ivec2 extraUV2 = ivec2(baseUV.x + 4, baseUV.y + 1);
    ivec2 extraUV3 = ivec2(baseUV.x + 4, baseUV.y + 2);
    ivec2 extraUV4 = ivec2(baseUV.x + 4, baseUV.y + 3);
    ivec2 fogUV1 = ivec2(baseUV.x + 5, baseUV.y);
    ivec2 fogUV2 = ivec2(baseUV.x + 5, baseUV.y + 1);
    ivec2 fogUV3 = ivec2(baseUV.x + 5, baseUV.y + 2);
    ivec2 fogUV4 = ivec2(baseUV.x + 5, baseUV.y + 3);
    ivec2 chunkPosUV1 = ivec2(baseUV.x + 6, baseUV.y);
    ivec2 chunkPosUV2 = ivec2(baseUV.x + 6, baseUV.y + 1);
    ivec2 chunkPosUV3 = ivec2(baseUV.x + 6, baseUV.y + 2);
    ivec2 extraUV5 = ivec2(baseUV.x + 7, baseUV.y);
    ivec2 extraUV6 = ivec2(baseUV.x + 7, baseUV.y + 1);
    ivec2 extraUV7 = ivec2(baseUV.x + 7, baseUV.y + 2);

    uvec3 u1, u2, u3, u4;

    u1 = uvec3(texelFetch(DiffuseSampler, posUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, posUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, posUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, posUV4, 0).rgb * 255.0);
    cameraPos.x = uintBitsToFloat(readFromColor0(u1, u2, u3, u4));
    cameraPos.y = uintBitsToFloat(readFromColor1(u1, u2, u3, u4));
    cameraPos.z = uintBitsToFloat(readFromColor2(u1, u2, u3, u4));
    float chunkPosX = dot(round(texelFetch(DiffuseSampler, chunkPosUV1, 0).rgb * 255.0), vec3(65536.0, 256.0, 1.0)) - 8388608.0;
    float chunkPosY = dot(round(texelFetch(DiffuseSampler, chunkPosUV2, 0).rgb * 255.0), vec3(65536.0, 256.0, 1.0)) - 8388608.0;
    float chunkPosZ = dot(round(texelFetch(DiffuseSampler, chunkPosUV3, 0).rgb * 255.0), vec3(65536.0, 256.0, 1.0)) - 8388608.0;
    cameraPos += vec3(chunkPosX, chunkPosY, chunkPosZ) * 16.0;
    vec3 viewZ;
    u1 = uvec3(texelFetch(DiffuseSampler, rotZUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, rotZUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, rotZUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, rotZUV4, 0).rgb * 255.0);
    viewZ.x = uintBitsToFloat(readFromColor0(u1, u2, u3, u4));
    viewZ.y = uintBitsToFloat(readFromColor1(u1, u2, u3, u4));
    viewZ.z = uintBitsToFloat(readFromColor2(u1, u2, u3, u4));
    vec3 viewY;
    u1 = uvec3(texelFetch(DiffuseSampler, rotYUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, rotYUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, rotYUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, rotYUV4, 0).rgb * 255.0);
    viewY.x = uintBitsToFloat(readFromColor0(u1, u2, u3, u4));
    viewY.y = uintBitsToFloat(readFromColor1(u1, u2, u3, u4));
    viewY.z = uintBitsToFloat(readFromColor2(u1, u2, u3, u4));
    vec3 viewX = cross(viewY, viewZ);
    u1 = uvec3(texelFetch(DiffuseSampler, fovYUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, fovYUV2, 0).rgb * 255.0);
    float cot = uintBitsToFloat(readFromColor0(u1, u2, u3, u4));
    u1 = uvec3(texelFetch(DiffuseSampler, extraUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, extraUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, extraUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, extraUV4, 0).rgb * 255.0);
    gametime = uintBitsToFloat(readFromColor0(u1, u2, u3, u4));  // [0,1200]s
    float fogStart = uintBitsToFloat(readFromColor1(u1, u2, u3, u4));
    float fogEnd = uintBitsToFloat(readFromColor2(u1, u2, u3, u4));
    bool inWater = false;
    bool inLava = false;
    bool inPowderSnow = false;
    float waterVision = 0.0;
    if (fogStart == -8.0) {
        inWater = true;
        waterVision = fogEnd / 96.0;  // todo swamp
    } else if (fogStart == 0.25 && fogEnd == 1.0 || fogStart == 0.0 && fogEnd == 5.0) {
        inLava = true;
    } else if (fogStart == 0.0 && fogEnd == 2.0) {
        inPowderSnow = true;
    }
    vec3 fogColor;
    u1 = uvec3(texelFetch(DiffuseSampler, fogUV1, 0).rgb * 255.0);
    u2 = uvec3(texelFetch(DiffuseSampler, fogUV2, 0).rgb * 255.0);
    u3 = uvec3(texelFetch(DiffuseSampler, fogUV3, 0).rgb * 255.0);
    u4 = uvec3(texelFetch(DiffuseSampler, fogUV4, 0).rgb * 255.0);
    fogColor.r = uintBitsToFloat(readFromColor0(u1, u2, u3, u4));
    fogColor.g = uintBitsToFloat(readFromColor1(u1, u2, u3, u4));
    fogColor.b = uintBitsToFloat(readFromColor2(u1, u2, u3, u4));
    rainStrength = 0.0;  // todo sun alpha
    float daytime = dot(round(texelFetch(DiffuseSampler, extraUV5, 0).rgb * 255.0), vec3(65536.0, 256.0, 1.0)) / 24000.0;  // [0,1]d
    sunAngle = get_sun_angle(daytime);  // [0,1]
    sunVec = vec3(cos(sunAngle * 2.0 * pi), sin(sunAngle * 2.0 * pi), 0.0);  // eye->sun
    lightVec = sunAngle < 0.5 ? sunVec : -sunVec;
    vec3 skyColor = plainsSkyColor * clamp(sunVec.y * 2.0 + 0.5, 0.0, 1.0);
    vec4 sunriseColor = get_sunrise_color(sunVec.y);

    float aspect = OutSize.x / OutSize.y;
    proj = mat4(cot / aspect, 0.0, 0.0, 0.0,
                0.0, cot, 0.0, 0.0,
                0.0, 0.0, -(f + n) / (f - n), -1.0,
                0.0, 0.0, -2.0 * f * n / (f - n), 0.0);
    projInv = inverse(proj);

    viewInv = mat3(viewX, viewY, viewZ);
    view = transpose(viewInv);
    vec3 viewPos = screen2view(texCoord, depthAccum);
    vec3 worldPos = viewInv * viewPos;
    vec3 worldDir = normalize(worldPos);
    float worldDist = length(worldPos);
    if (worldDist > f * 0.9) worldDist = 10000.0;

    if (isWater) {
        vec3 normal = normalize(cross(dFdx(worldPos), dFdy(worldPos)));
        vec3 waterNormal = get_water_normal(cameraPos + worldPos);
        rotate_water_normal(waterNormal, normal);
        vec3 screenPos = raytrace(worldPos, waterNormal);
        float refDepth;
        vec3 refColor = get_texel_accum(screenPos.xy, refDepth);
        float border = max(abs(screenPos.x - 0.5), abs(screenPos.y - 0.5));
        border = clamp(11.0 - border * 20.0, 0.0, 1.0);  // [0.5,0.55]->[1.0,0.0]
        if (screenPos.z > refDepth) border = 0.0;
        refColor = mix(skyColor, refColor, border);
        float fresnel = pow(clamp(1.0 + dot(worldDir, normal), 0.0, 1.0), 5.0);
        fresnel = fresnel * 0.98 + 0.02;
        fragColor.rgb = mix(texelAccum, refColor, fresnel);
    }
    vec3 scattering = vec3(0.0, 0.0, 1.0);
    if (cameraPos.y < CLOUD_HEIGHT) {
        float bottomDist = (CLOUD_HEIGHT - cameraPos.y) / worldDir.y;
        if (worldDir.y > 0.0 && worldDist > bottomDist) {
            vec3 rayStart = cameraPos + worldDir * bottomDist;
            float topDist = (CLOUD_HEIGHT + CLOUD_THICKNESS - cameraPos.y) / worldDir.y;
            float rayLength = min(topDist, worldDist) - bottomDist;
            scattering = raymarch(rayStart, worldDir, rayLength);
        }
    } else if (cameraPos.y > CLOUD_HEIGHT + CLOUD_THICKNESS) {
        float topDist = (cameraPos.y - CLOUD_HEIGHT - CLOUD_THICKNESS) / -worldDir.y;
        if (worldDir.y < 0.0 && worldDist > topDist) {
            vec3 rayStart = cameraPos + worldDir * topDist;
            float bottomDist = (cameraPos.y - CLOUD_HEIGHT) / -worldDir.y;
            float rayLength = min(bottomDist, worldDist) - topDist;
            scattering = raymarch(rayStart, worldDir, rayLength);
        }
    } else {
        if (worldDir.y > 0.0) {
            float dist = (CLOUD_HEIGHT + CLOUD_THICKNESS - cameraPos.y) / worldDir.y;
            float rayLength = min(dist, worldDist);
            scattering = raymarch(cameraPos, worldDir, rayLength);
        } else {
            float dist = (cameraPos.y - CLOUD_HEIGHT) / -worldDir.y;
            float rayLength = min(dist, worldDist);
            scattering = raymarch(cameraPos, worldDir, rayLength);
        }
    }
    float sunIntensity = clamp(sunVec.y * 10.0, 0.0, 1.0);
    float moonIntensity = clamp(-sunVec.y * 10.0, 0.0, 1.0);
    vec3 lightColor = gamma_to_linear(sunAngle < 0.5 ? mix(SUN_COLOR, sunriseColor.rgb, sunriseColor.a) * sunIntensity : MOON_COLOR * moonIntensity);
    vec3 cloudColor = scattering.x * lightColor + scattering.y * gamma_to_linear(mix(skyColor, sunriseColor.rgb, sunriseColor.a * 0.5));
    fragColor.rgb = gamma_to_linear(fragColor.rgb);
    fragColor.rgb = cloudColor + fragColor.rgb * scattering.z;
    fragColor.rgb = linear_to_gamma(fragColor.rgb);
}
