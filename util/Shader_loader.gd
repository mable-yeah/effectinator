class_name shader_loader
##class for loading shaders, injecting fallbacks etc

##error logger
static var this_logger:shader_logger = shader_logger.new()

##reflect the state of the latest shader loaded
static var in_error_state = false

##index of first real line of the last shadr loaded
static var first_line = -1


##define a shader through a code string, used for user shaders and shaders that can't be stored in a scene
static func define_shader(Shader_code:String) -> ShaderMaterial:
	const fallback_shader =  '
			shader_type canvas_item;
			
			void fragment() {
				COLOR = vec4(1.0,0.0,1.0,1.0);
			}
	'
	
	var first = Shader_code.split('\n').get(0)
	Shader_code = _inject_fallback(Shader_code)
	first_line = Shader_code.split('\n').find(first)
	
	
	var shader = shader_layer.new() ; shader.set_code(Shader_code)
	var material = ShaderMaterial.new() ; material.set_shader(shader)
	in_error_state = shader.has_error 
	if shader.has_error: 
		shader.set_code(fallback_shader)

	return material






##returns the latest attempted shader error, or blank
static func get_error() -> String:
	if !in_error_state: this_logger.current_shader_error = ''
	return this_logger.current_shader_error

##returns the current error line index (non-corrected to injected code)
static func get_error_line() -> int:
	var err = get_error()
	if err == '': return -1
	
	var regex = RegEx.new()
	regex.compile('\\d')
	var lines = err.split('\n')
	for i in lines.size() - 1:
		var line = lines[i]
		if !line.contains('->'):continue
		var search = regex.search(line)
		if search == null:continue
		return search.strings[0].to_int()
	return -1


##returns a corrected version of the error line
static func corrected_error_line() -> int:
	var err = get_error()
	if err == '': return -1
	
	var lines = err.split('\n')
	lines = lines.slice(first_line,lines.size())
	lines.erase('    2 | uniform bool ____________ = true;')
	
	for line in lines:
		if !line.contains('->'):continue
		return lines.find(line)
	return -1


static func get_error_message() -> String:
	var err = get_error()
	if err == '': return ''
	var split:Array = err.split('\n')
	return split.back()
	





##returns premade shader functions by checking for //include = []
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


class shader_layer extends Shader:
	var has_error:bool:
		get():
			return get_shader_uniform_list().is_empty()
