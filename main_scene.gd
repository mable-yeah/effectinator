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
	%code.text_changed.connect(
		func():
			var text = %code.text
			await get_tree().create_timer(1.5).timeout
			if %code.text != text: return
			apply_shader()
	)
	
	#await get_tree().create_timer(0.5).timeout
	#OS.alert('warning: work in progress, features may not work as intended','haha im an error window :p')


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
