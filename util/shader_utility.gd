class_name shader_utility


static func get_function(p_func:String):
	var index = function_names.find(p_func)
	if index == -1: return ''
	return util_func.get(index,'')

const function_names = [
	"texture_clamped",
	"rotateUV",
	"linear_burn",
	"color_burn",
	"linear_dodge",
	"color_dodge",
	"soft_light",
	"hard_light",
	"overlay",
	"exclusion",
	"difference",
	"lighten",
	"darken",
	"screen",
	"multiply",
	"swirl",
	"square_rounded",
	"square_stroke",
	"square",
	"polygon",
	"line",
	"circle",
	"border",
	'scale_uv',
	'random',
	'hue',
	'saturate'
]


const util_func = {
0:'vec4 texture_clamped(sampler2D tex, vec2 uv,float blur) {
	return (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0)  ? texture(tex,uv,blur)  : vec4(0.0);
}',

1:'vec2 rotateUV(vec2 uv, float rotation, float mid)
{
    return vec2(
      cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
      cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}',

2:'vec4 linear_burn(vec4 base, vec4 blend){
	return base + blend - 1.0;
}
',

3:'vec4 color_burn(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) / blend;
}
',

4:'vec4 linear_dodge(vec4 base, vec4 blend){
	return base + blend;
}
',


5:'vec4 color_dodge(vec4 base, vec4 blend){
	return base / (1.0 - blend);
}
',


6:'vec4 soft_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}
',


7:'vec4 hard_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
',



8:'vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
',


9:'vec4 exclusion(vec4 base, vec4 blend){
	return base + blend - 2.0 * base * blend;
}',



10:'vec4 difference(vec4 base, vec4 blend){
	return abs(base - blend);
}
',


11:'vec4 lighten(vec4 base, vec4 blend){
	return max(base, blend);
}
',


12:'vec4 darken(vec4 base, vec4 blend){
	return min(base, blend);
}
',


13:'vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}
',


14:'vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}
',


15:'float swirl(vec2 uv, float size, int arms)
{
	float angle = atan(-uv.y + 0.5, uv.x - 0.5) ;
	float len = length(uv - vec2(0.5, 0.5));
	
	return sin(len * size + angle * float(arms));
}
',


16:'vec4 square_rounded(vec2 uv, float width, float radius){
	uv = uv * 2.0 - 1.0;
	
	radius *= width; // make radius go from 0-1 instead of 0-width
	vec2 abs_uv = abs(uv.xy) - radius;
	vec2 dist = vec2(max(abs_uv.xy, 0.0));
	float square = step(width - radius, length(dist));
	return vec4(vec3(square), 1.0);
}
',


17:'vec4 square_stroke(vec2 uv, float width, float stroke_width)
{
	uv = uv * 2.0 - 1.0;
	
	vec2 abs_uv = abs(uv.xy);
	float dist = max(abs_uv.x, abs_uv.y);
	vec3 stroke = 1.0 - vec3( step(width, dist) - step(width + stroke_width, dist) );
	return vec4(vec3(stroke), 1.0);
}
',


18:'vec4 square(vec2 uv, float width)
{
	uv = uv * 2.0 - 1.0;
	
	vec2 abs_uv = abs(uv.xy);
	float square = step(width, max(abs_uv.x, abs_uv.y));
	return vec4(vec3(square), 1.0);
}
',


19:'const float TWO_PI = 6.28318530718;

vec4 polygon(vec2 uv, float width, int sides)
{
	uv = uv * 2.0 - 1.0;

	float angle = atan(uv.x, uv.y);
	float radius = TWO_PI / float(sides);
	
	float dist = cos(floor(0.5 + angle / radius) * radius - angle) * length(uv);
	float poly = step(width, dist);
	return vec4(vec3(poly), 1.0);
}
',


20:"float line(vec2 p1, vec2 p2, float width, vec2 uv)
{
	float dist = distance(p1, p2); // Distance between points
	float dist_uv = distance(p1, uv); // Distance from p1 to current pixel

	// If point is on line, according to dist, it should match current UV
	// Ideally the '0.001' should be SCREEN_PIXEL_SIZE.x, but we can't use that outside of the fragment function.
	return 1.0 - floor(1.0 - (0.001 * width) + distance (mix(p1, p2, clamp(dist_uv / dist, 0.0, 1.0)),  uv));
}
",



21:'float circle(vec2 position, float radius, float feather)
{
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}
',


22:'float border(vec2 uv, float border_width)
{
	vec2 bottom_left = step(vec2(border_width), uv);
	vec2 top_right = step(vec2(border_width), 1.0 - uv);
	return bottom_left.x * bottom_left.y * top_right.x * top_right.y;
}
',

23:'vec2 scale_uv(vec2 uv,float scale){
	uv -= 0.5;
	uv *= scale;
	uv += 0.5;
	return uv;
}
',
24:'
float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}
',
25:'
vec3 hue(vec3 color, float hue) {
    const vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return vec3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
}
',
26:'
vec3 saturate(vec3 rgb, float adjustment)
{
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}
'
}
