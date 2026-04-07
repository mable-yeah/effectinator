class_name shader_logger
#maybee???

const error_header = '--Main Shader--\n'
const shader_error = Logger.ErrorType.ERROR_TYPE_SHADER

var this_logger:mini_logger = mini_logger.new()
var errors:PackedStringArray = []

##contains the entire current shader error string
var current_shader_error:String = ''

##if the logger is greedy a poppup window will appear
var greedy:bool = false

func _init(is_greedy:bool = false) -> void:
	greedy = is_greedy ; OS.add_logger(this_logger)
	
	
	this_logger.error_out.connect(
		func(code,type):
			errors.append(code)
			get_shader_error(type)
	)
	
	this_logger.message_out.connect(
		func(msg,_err):
			errors.append(msg)
	)


##fills current_shader_error with.. the latest found shader error
func get_shader_error(type) -> void:
	if type != shader_error: return
	
	var this_index = errors.size()
	var header = errors.find(error_header)
	
	if header == -1: return
	
	var slices:Array = errors.slice(header,this_index) ; slices.erase(error_header)
	
	current_shader_error = ''.join(slices)
	errors.clear()
	
	
	if !greedy: return
	
	var popup_slices = slices.duplicate()
	var next_is_error:bool = false
	
	for i in popup_slices.size() - 1:
		var slice = popup_slices[i]
		if next_is_error:
			var back = popup_slices.back()
			var clamped = max(i - 5,0)
			popup_slices = popup_slices.slice(clamped,i) + [back]
			break
		
		if !slice.contains('->'):continue
		next_is_error = true
	
	popup_slices.append('\n\nError logging by mabes, blehhh')
	OS.alert(''.join(popup_slices),'Warning: shader error')





#technically i did NOT need to use signals but _log_error has wayy too many inputs
class mini_logger extends Logger:
	var mutex := Mutex.new() 
	#the docs say something about locking, other bits of code ive seen for loggers have this
	#have this so imma just do it
	
	signal message_out(message:String,is_error:bool)
	signal error_out(code:String,err_type:int)
	
	func _log_message(message, error: bool):
		mutex.lock() ; message_out.emit(message,error) ; mutex.unlock()
	
	func _log_error(_f, _fi, _l, code, _r, _ed, error_type,_sb):
		mutex.lock() ; error_out.emit(code,error_type) ; mutex.unlock()
