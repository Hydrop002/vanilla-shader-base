#version 150

const float pi = 3.1416;
const float shadowWidth = 100.0;
const float shadowHeight = 56.25;
const float shadowNear = 0.0;
const float shadowFar = 200.0;

float get_sun_angle(float daytime) {
    float a = fract(daytime - 0.25);
    float b = 0.5 - cos(a * pi) * 0.5;
    float t = (a * 2.0 + b) / 3.0;
    return fract(t + 0.25);
}

vec4 get_shadow_position(vec3 pos, float gametime) {
    float sunAngle = get_sun_angle(gametime);  // force set daytime to gametime
    vec3 sunVec = vec3(cos(sunAngle * 2.0 * pi), sin(sunAngle * 2.0 * pi), 0.0);
    vec3 lightVec = sunAngle < 0.5 ? sunVec : -sunVec;
    vec3 rightVec = vec3(0.0, 0.0, -1.0);
    vec3 upVec = cross(lightVec, rightVec);
    mat4 view = mat4(
        rightVec.x, upVec.x, lightVec.x, 0.0,
        rightVec.y, upVec.y, lightVec.y, 0.0,
        rightVec.z, upVec.z, lightVec.z, 0.0,
        0.0, 0.0, -100.0, 1.0
    );
    mat4 proj = mat4(
        2.0 / shadowWidth, 0.0, 0.0, 0.0,
        0.0, 2.0 / shadowHeight, 0.0, 0.0,
        0.0, 0.0, -2.0 / (shadowFar - shadowNear), 0.0,
        0.0, 0.0, -(shadowFar + shadowNear) / (shadowFar - shadowNear), 1.0
    );
    vec4 pos_ndc = proj * view * vec4(pos, 1.0);
    pos_ndc.xy /= mix(1.0, length(pos_ndc.xy), 0.85);
    return pos_ndc;
}

bool is_main_frame(float gametime) {
    return mod(gametime * 300000.0, 2.0) < 1.0;
}

bool is_ui(mat4 proj) {
    return proj[2][3] == 0.0;
}

bool is_hand(float fogStart) {
    return fogStart > 10000.0;
}

vec4 encode_depth(float depth) {
    float t = depth * 255.0;
    float x = floor(t) / 255.0;
    t = fract(t) * 255.0;
    float y = floor(t) / 255.0;
    t = fract(t) * 255.0;
    float z = floor(t) / 255.0;
    return vec4(x, y, z, 1.0);
}

vec2 get_screen_size(vec2 coord, vec4 pos) {
    pos /= pos.w;
    pos = (pos + 1.0) / 2.0;
    return round(coord / pos.xy);
}

bool is_marker(vec2 coord, vec2 screenSize) {
    coord = floor(coord);
    vec2 baseUV = vec2(floor(screenSize.x / 2.0), 0.0);
    vec2 offset = coord - baseUV;
    if (offset.x >= 0.0 && offset.x <= 7.0 && offset.y >= 0.0 && offset.y <= 3.0) return true;
    else return false;
}
