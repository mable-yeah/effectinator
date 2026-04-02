class_name main_scene extends Control

var viewport:Image:
	get():
		return %SubViewport.get_texture().get_image()

var current_code:String:
	get():
		return %code.text
	set(value):
		%code.text = value

var layers:Array[Layer]
var last_index:int = -1


func _ready() -> void:

	%merge.pressed.connect(rewrite_pass)
	%layer.pressed.connect(instance_layer)
	%reset.pressed.connect(set_context)
	%save.pressed.connect(save_dialog)
	%code.text_changed.connect(
		func():
			var text = %code.text
			await get_tree().create_timer(1.5).timeout
			if %code.text != text: return
			apply_shader()
	)
	
	get_window().files_dropped.connect(on_file_dropped)
	apply_shader()
	
	


func save_dialog():
	var dialog = FileDialog.new()
	dialog.use_native_dialog = true
	dialog.title = 'pick a location to save the image'
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	var formats = supported_formats.keys()
	for i in formats.size():
		var format = formats[i]
		format = '*.%s' % format
		formats[i] = format
	dialog.set_filters(formats)
	dialog.popup()
	dialog.file_selected.connect(
		func(path):
			save_image(path)
	)


var supported_formats:Dictionary[String,format_container] = {
	'png':format_container.new('load_png_from_buffer','save_png'),
	'jpg':format_container.new('load_jpg_from_buffer','save_jpg')
}


class format_container:
	#both of these method strings should exist in Image
	var read:String
	var write:String
	
	func _init(p_read:String,p_write:String) -> void:
		read = p_read
		write = p_write


func on_file_dropped(files:PackedStringArray):
	var extensions = supported_formats.keys()
	if files.size() == 0: return
	for file in files: #if a whole bunch are dropped in, just get the first valid one
		if !extensions.has(file.get_extension()): continue
		load_image(file)
		return 
	printerr('no dropped file had any supported format')

func load_image(path:String):
	if !FileAccess.file_exists(path): printerr("file doesn't exist %s" % path.get_basename()) ; return 
	var Read = FileAccess.open(path,FileAccess.READ)
	if Read == null: printerr(error_string(FileAccess.get_open_error())) ; return
		
	var Data = Read.get_buffer(Read.get_length())
	var image = Image.new()
	
	var function = supported_formats.get(path.get_extension(),null)
	if function == null: 
		printerr('could not find a valid read function for "%s"' % path.get_extension())
		return
	image.call(function.read,Data)
	Read.close()
	
	var texture = ImageTexture.create_from_image(image)
	%sprite.texture = texture

func save_image(path):
	if FileAccess.file_exists(path):
		OS.alert('warning, file already exists and it will be overwritten','warning')
	
	var image:Image = %sprite.texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.premultiply_alpha()
	
	var function = supported_formats.get(path.get_extension(),null)
	if function == null: 
		printerr('could not find a valid write function for "%s"' % path.get_extension())
		return
	var save_call = image.call(function.write,path)
	
	if save_call != Error.OK: print(error_string(save_call))


func _process(_delta: float) -> void:
	%reset.disabled = last_index == -1
	DisplayServer.window_set_title(monitor())


func monitor() -> String:
	var MEM_PEAK = OS.get_static_memory_peak_usage() 
	var MEM_static = OS.get_static_memory_usage() 
	var VRAM = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	
	var humanized = [String.humanize_size(MEM_static),String.humanize_size(MEM_PEAK),String.humanize_size(VRAM)]
	return '%s / %s | VRAM: %s' % humanized



func apply_shader(shader_code:String = current_code,idx:int = last_index):
	%sprite.material = ShaderLoader.define_shader(shader_code)
	if idx >= 0:
		var layer = layers.get(idx)
		layer.code = shader_code
		layer.set_layer_name(get_layer_name(layer.index))

func instance_layer():
	last_index = layers.size()
	var layer = Layer.new()
	layer.code = current_code
	%layer_list.add_child(layer)
	layers.push_back(layer)
	layer.index = last_index 
	
	#this prevents already established layers from changing names after a lower layer is deleted
	layer.set_layer_name(get_layer_name(layer.index))
	
	set_context()
	
	layer.code_requested.connect(func():
		set_context(layer.code,layers.find(layer))
	)
	layer.erase_requested.connect(func():
		layer.queue_free() ; layers.erase(layer)
	)


func get_layer_name(last_known_idx:int):
	var layer_name = 'Layer %s' % last_known_idx
	
	if !current_code.contains('layer_name'): return layer_name
	
	var regex = RegEx.new()
	regex.compile("\\/\\/layer_name = '[\\s\\S]+'")
	var r_match = regex.search(current_code)
	
	if r_match != null:
		var string = r_match.strings[0]
		regex.compile("(?<=').+?(?=')")
		r_match = regex.search(string) #if this ends up as null im killing myself
		layer_name = r_match.strings[0]
	
	return layer_name




func set_context(code:String = '', index:int = -1):
	current_code = code ; last_index = index ; apply_shader()


var alpha_helper = alpha_fix.new()

func rewrite_pass() -> void:
	if last_index >= 0:
		var layer = layers.get(last_index)
		layer.erase_requested.emit()
	%sprite.texture = alpha_helper.fix_alpha(viewport)
	set_context()
