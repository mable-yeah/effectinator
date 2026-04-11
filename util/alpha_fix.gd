class_name alpha_fix

#basicawwy all this bullshit just makes it so the alpha doesnt get multiplied when merging layers
#and since its a compute shader it does it fast

var device := RenderingServer.create_local_rendering_device()
var shader_file := load("res://util/compute_alphafix.glsl")
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
var shader:RID
var pipeline:RID


const usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)


const format = {
	'image': Image.FORMAT_RGBAF,
	'device': RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT,
	'uniform': RenderingDevice.UNIFORM_TYPE_IMAGE
}


func setup():
	if shader.is_valid():return
	shader = device.shader_create_from_spirv(shader_spirv)
	pipeline = device.compute_pipeline_create(shader)


func fix_alpha(image: Image) -> ImageTexture:
	if RenderingServer.get_current_rendering_method() == 'gl_compatibility':
		return fix_alpha_noncompute(image)
	return fix_alpha_compute(image)


func fix_alpha_compute(image: Image) -> ImageTexture:
	setup()
	var texture_size = image.get_size()
	image.convert(format.image  as Image.Format)
	
	var view = RDTextureView.new()
	var texture_format = RDTextureFormat.new()
	var image_uniform = RDUniform.new()
	
	texture_format.width = texture_size.x ; texture_format.height = texture_size.y
	texture_format.usage_bits = usage_bits ; texture_format.format = format.device
	
	var rd_texture = device.texture_create(texture_format, view, [image.get_data()])
	
	image_uniform.uniform_type = format.uniform ; image_uniform.binding = 0
	image_uniform.add_id(rd_texture)

	var uniform_set = device.uniform_set_create([image_uniform], shader, 0)
	var compute_list = device.compute_list_begin()

	device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	device.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	device.compute_list_dispatch(compute_list, 32, 32, 1)
	device.compute_list_end()

	device.submit() ; device.sync()

	var data = device.texture_get_data(rd_texture, 0)
	var output = Image.create_from_data(texture_size.x, texture_size.y, false, format.image as Image.Format, data)
	output.generate_mipmaps()
	var final = ImageTexture.create_from_image(output)
	
	device.free_rid(rd_texture)
	return final




#compute shaders do not work in browsers/ when gl_compatibility is enabled
#so this is needed in that case, but it is VERY slow with larger images :p
func fix_alpha_noncompute(image:Image) -> ImageTexture:
	image.convert(Image.FORMAT_RGBA8)
	var size = image.get_size() ; var data = image.get_data()
	var i = 0
	while i < data.size():
		var color = Color(data[i],data[i + 1],data[i + 2],data[i + 3])
		if color.a > 0:
			color.a = 255 / color.a
			data[i] = clamp(color.r * color.a,0,255) 
			data[i + 1] = clamp(color.g * color.a,0,255) 
			data[i + 2] = clamp(color.b * color.a,0,255) 
		i += 4
	
	image.set_data(size.x,size.y,false,Image.FORMAT_RGBA8,data)
	image.convert(format.image as Image.Format)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
