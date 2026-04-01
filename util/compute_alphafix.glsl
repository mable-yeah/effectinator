#[compute]
#version 450

layout(local_size_x = 32,local_size_y = 32,local_size_z = 1) in;

layout(set = 0, binding = 0,rgba32f) uniform image2D img;

void main(){
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	vec4 color = imageLoad(img, uv);
	if (color.a > 0.0) {
		color.rgb /= color.a;
	}
	imageStore(img, uv, color);
} //fuck my chud life !!