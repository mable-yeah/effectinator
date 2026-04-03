##class for generating details about shaders, properties, value, names, defaults.. etc
class_name ShaderLoader

##define a shader through a code string, used for user shaders and shaders that can't be stored in a scene
static func define_shader(Shader_code:String) -> ShaderMaterial:
	const fallback_shader =  '
			shader_type canvas_item;
			
			void fragment() {
				COLOR = vec4(1.0,0.0,1.0,1.0);
			}
	'
	
	Shader_code = _inject_fallback(Shader_code)
	
	var shader = shader_layer.new() ; shader.set_code(Shader_code)
	var material = ShaderMaterial.new() ; material.set_shader(shader)
	if shader.has_error: shader.set_code(fallback_shader)
	
	return material




static func get_include(shader_code):
	if !shader_code.contains('include'):return []
	var regex = RegEx.new()
	
	regex.compile("\\/\\/include = \\[([\\s\\S].+,?)?\\]")
	var r_match = regex.search(shader_code)
	if r_match == null: return []
	var string:String = r_match.strings[0]
	var arr_start = string.find('[') ; var arr_end = string.find(']')
	var array = string.substr(arr_start,arr_end)
	array = array.remove_chars('[').remove_chars(']')
	
	var includes:PackedStringArray = []
	for fn_name in array.split(','):
		includes.push_back(shader_utility.get_function(fn_name))
	return includes



##injects a fallback hack into shader code so that uniform lists arent entirely empty, SHOULD NOT NEED TO BE CALLED BY ITSELF
static func _inject_fallback(Shader_code):
	#inject a uniform so if there isnt any in the shader, i can at least load a fallback
	var header =  Shader_code.find("shader_type")
	if header != -1:
		var lines:Array = Shader_code.split('\n')

		var header_position = -INF
		for code in lines:
			if code.contains("shader_type"):
				header_position = lines.find(code)
			if header_position != -INF:
				break
		#hopefully nobody ever uses this variable name, if they do.... they should not do that
		var dist = 1
		lines.insert(header_position + dist,"uniform bool ____________ = true;")
		var includes = get_include(Shader_code)
		for include in includes:
			dist += 1
			lines.insert(header_position + dist,include)
		
		Shader_code = "\n".join(lines)
	else:
		var lines:Array = Shader_code.split('\n')
		lines.push_front('shader_type canvas_item;')
		Shader_code = "\n".join(lines)
		Shader_code = _inject_fallback(Shader_code)
	return Shader_code



##packs a shader path into a material,for ease of use
static func pack_as_mat(file_path:String):
	var shaderMaterial = ShaderMaterial.new()
	shaderMaterial.shader = load(file_path)
	return shaderMaterial



class shader_layer extends Shader:
	var has_error:bool:
		get():
			return get_shader_uniform_list().is_empty()
