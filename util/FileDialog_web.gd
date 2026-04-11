class_name FileDialog_web ; extends Node
##fallback for FileDialog, to use the native explorer instead of the built in one
##which gets limited to internal res files

var access:FileDialog.Access
var file_mode:FileDialog.FileMode = FileDialog.FILE_MODE_SAVE_FILE
var use_native_dialog:bool = false

var title = ''
var filters:PackedStringArray = []:
	set(value):
		for i in value.size():
			var filter = value[i]
			value[i] = filter.remove_chars('*')
		filters = value

@warning_ignore("unused_signal")
signal close_requested
signal canceled
signal file_selected(path:String)

var JS_instance:JavaScriptObject

var data_in:String

var selected_callback:JavaScriptObject
var cancelled_callback:JavaScriptObject

var JS_source:String:
	get():
		var script = FileAccess.open('res://util/FileDialog_webhandler.js',FileAccess.READ)
		var code = script.get_as_text() ; script.close()
		return code 
	#the javascript is stored seperately just cause i wanted to use visual studio to edit it


func _init():
	JavaScriptBridge.eval(JS_source, true)
	JS_instance = JavaScriptBridge.get_interface("dialog")
	
	
	selected_callback = JavaScriptBridge.create_callback(selected)
	JS_instance.setLoad(selected_callback)
	
	cancelled_callback = JavaScriptBridge.create_callback(cancelled)
	JS_instance.setCancelled(cancelled_callback)

func selected(...args):
	if args.is_empty(): file_selected.emit('') ; return 
	file_selected.emit(args[0].front())


func cancelled(_args):
	canceled.emit()

func set_data(data:Variant):
	data_in = data

func popup():
	if file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		JS_instance.pop_save(data_in) ; return
	JS_instance.pop()

func set_filters(p_filters:PackedStringArray):
	filters = p_filters
	JS_instance.setFilters(','.join(filters)) 
