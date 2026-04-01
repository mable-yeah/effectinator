class_name alpha_fix

#basicawwy all this bullshit just makes it so the alpha doesnt get multiplied when merging layers
#and since its a compute shader it does it fast

var device := RenderingServer.create_local_rendering_device()
var shader_file := load("res://util/compute_alphafix.glsl")
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
var shader := device.shader_create_from_spirv(shader_spirv)
var pipeline := device.compute_pipeline_create(shader)


const usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)


const format = {
	'image': Image.FORMAT_RGBAF,
	'device': RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT,
	'uniform': RenderingDevice.UNIFORM_TYPE_IMAGE
}


func fix_alpha(image: Image) -> ImageTexture:
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
	var final = ImageTexture.create_from_image(output)
	
	device.free_rid(rd_texture)
	return final
