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
	%export.pressed.connect(export_dialog)
	%save_project.pressed.connect(format_project)
	%load_project.pressed.connect(load_project)
	
	%code.text_changed.connect(
		func():
			var text = %code.text
			await get_tree().create_timer(1.5).timeout
			if %code.text != text: return
			apply_shader()
	)
	
	get_window().files_dropped.connect(on_file_dropped)
	apply_shader()


func get_dialog() -> Variant:
	var dialog = FileDialog.new() 
	if OS.get_name() == 'Web':
		dialog.free()
		dialog =  FileDialog_web.new()
	
	add_child(dialog)
	dialog.use_native_dialog = true

	dialog.close_requested.connect(
		func(): dialog.call_deferred("queue_free")
	)
	dialog.canceled.connect(
		func(): dialog.call_deferred("queue_free")
	)
	return dialog



func export_dialog():
	var dialog = get_dialog()
	dialog.title = 'pick a location to save the image'
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	
	var formats = supported_formats.keys()
	for i in formats.size():
		var format = formats[i]
		format = '*.%s' % format
		formats[i] = format
	
	if dialog is FileDialog_web: 
		formats.resize(1) ; dialog.set_data(save_image(''))
		
	
	dialog.set_filters(formats)
	
	
	dialog.popup()
	dialog.file_selected.connect(
		func(path):
			dialog.call_deferred("queue_free")
			if path == '':return
			save_image(path)
	)


func project_save_dialog(data:String):
	var dialog = get_dialog()
	dialog.title = 'pick a location to save the project'
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	
	dialog.set_filters(['*.eff']) #just bullshitting
	
	if dialog is FileDialog_web:
		dialog.set_data(data)
	dialog.popup()
	dialog.file_selected.connect(
		func(path):
			dialog.call_deferred("queue_free")
			if path == '':return
			var file = FileAccess.open(path,FileAccess.WRITE)
			file.store_string(data) ; file.close()
	)
	


func format_project():
	var layers_data:PackedStringArray = []
	for layer in layers:
		layers_data.push_back(layer.saveify())
	
	var image:Image = %sprite.texture.get_image()
	image.clear_mipmaps()
	var image_data = {
		'layers':layers_data,
		'size':[image.get_size().x,image.get_size().y],
		'format':image.get_format(),
		'data':image.get_data().hex_encode(),
		'hash':hash(image.get_data())
	}
	
	var out = JSON.stringify(image_data,"   ",false,true)
	project_save_dialog(out)

func load_project():
	%code.set_caret_line(0) ; %code.set_caret_column(0)
	var dialog = get_dialog()
	dialog.title = 'pick a .eff file'
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.set_filters(['*.eff']) #just bullshitting
	dialog.popup()
	dialog.file_selected.connect(
		func(path):
			var file_text:String = path
			dialog.call_deferred("queue_free")
			
			if !(dialog is FileDialog_web):
				var file = FileAccess.open(path,FileAccess.READ)
				if FileAccess.get_open_error() != OK: 
					print(error_string(FileAccess.get_open_error()))
					return
				file_text = file.get_as_text()
			
			for layer in layers:
				layer.free()
			layers.clear()
			
			var data:Dictionary = JSON.parse_string(file_text)
			
			var stored_layers:Array = data.get('layers',[])
			var image_data:PackedByteArray = data.get('data',PackedByteArray([0,0,0,0]).hex_encode()).hex_decode()
			var image_size:Array = data.get('size',[0.0,0.0])
			
			var image_hash:int = data.get('hash',hash(image_data)) 
			#if there is no hash, just trust the image
			
			var format:Image.Format = data.get('format',5) as Image.Format
			
			if hash(image_data) != image_hash: 
				printerr('mismatching hash, image data may be malformed')
				return 
			
			image_size.resize(2)
			if image_size.has(null): image_size[image_size.find(null)] = 0.0
			
			var image = Image.create_from_data(image_size[0],image_size[1],false,format,image_data)
			image.generate_mipmaps()
			
			var texture = ImageTexture.create_from_image(image)
			
			%sprite.texture = texture
			
			for layer in stored_layers:
				layer = JSON.parse_string(layer)
				if !(layer is Dictionary): continue
				instance_layer(layer)
			set_context()
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
	
	image.generate_mipmaps()
	var texture = ImageTexture.create_from_image(image)
	
	%sprite.texture = texture
	apply_shader()

func save_image(path):
	var image:Image = %sprite.texture.get_image()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGBA8)
	
	if path == '':
		var buffer = image.save_png_to_buffer()
		return Marshalls.raw_to_base64(buffer)
		#if the path is blank instead send in data, as JS doesnt return paths
		#so we do it backwards/before calling the file explorer
	
	var function = supported_formats.get(path.get_extension(),null)
	if function == null: 
		printerr('could not find a valid write function for "%s"' % path.get_extension())
		return
	var save_call = image.call(function.write,path)
	
	if save_call != Error.OK: print(error_string(save_call))


func _process(_delta: float) -> void:
	$CenterContainer.pivot_offset = $CenterContainer.size/2.0
	%reset.disabled = last_index == -1
	DisplayServer.window_set_title(monitor())

func monitor() -> String:
	if not OS.has_feature("editor"): return 'effectinator!! ^-^'
	var MEM_PEAK = OS.get_static_memory_peak_usage() 
	var MEM_static = OS.get_static_memory_usage() 
	var VRAM = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	
	var humanized = [String.humanize_size(MEM_static),String.humanize_size(MEM_PEAK),String.humanize_size(VRAM)]
	return '%s / %s | VRAM: %s' % humanized



func apply_shader(shader_code:String = current_code,idx:int = last_index):
	%SubViewport.size = get_canvas_size()
	%sprite.material = shader_loader.define_shader(shader_code)
	if idx >= 0:
		var layer = layers.get(idx)
		layer.code = shader_code
		layer.set_layer_name(get_layer_name(layer.index))

func instance_layer(map:Dictionary = {}):
	last_index = layers.size()
	var layer = Layer.new()
	%layer_list.add_child(layer)
	layers.push_back(layer)
	
	if map.is_empty():
		layer.code = current_code ; layer.index = last_index 
		layer.set_layer_name(get_layer_name(layer.index)) ; set_context()
		#this prevents already established layers from changing names after a lower layer is deleted
	else:
		layer.map(map)
	
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


func get_canvas_size():
	if %sprite.texture == null: return Vector2.ZERO
	var canvas_size = %sprite.texture.get_size()
	
	if !current_code.contains('canvas_size'): return canvas_size
	
	var regex = RegEx.new()
	regex.compile("\\/\\/canvas_size = \\[(\\d+(\\.?\\d+?)?),(\\d+(\\.?\\d+?)?)\\]")
	
	var r_match = regex.search(current_code)
	
	if r_match != null:
		var string:String = r_match.strings[0]
		var start = string.find('[') ; var end = string.find(']')
		
		if (start == -1) || (end == -1): return canvas_size
		string = string.substr(start,end)
		
		var parse = JSON.parse_string(string)
		canvas_size *= Vector2(parse[0],parse[1])
	return clamp(canvas_size,Vector2.ZERO,Vector2(4096,4096))


func _unhandled_input(event: InputEvent) -> void:
	var vector = $CenterContainer.scale
	
	var zoom = Vector2.ONE * 10.0
	if Input.is_action_pressed('ui_shift'):
		zoom *= 2.0
	
	zoom *= get_process_delta_time() * vector
	
	if !(event is InputEventMouseButton): return 
	if !event.is_pressed(): return
	
	
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		vector += zoom
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		vector -= zoom
	$CenterContainer.scale = clamp(vector,Vector2(0.05,0.05),Vector2(200,200))

func set_context(code:String = '', index:int = -1) -> void:
	current_code = code ; last_index = index ; apply_shader()


var alpha_helper:alpha_fix = alpha_fix.new()

func rewrite_pass() -> void:
	if last_index >= 0 and not Input.is_action_pressed('ui_ctrl'):
		var layer = layers.get(last_index)
		layer.erase_requested.emit()
	
	%sprite.texture = alpha_helper.fix_alpha(viewport)
	set_context()
