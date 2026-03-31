class_name Layer
extends HBoxContainer

signal code_requested
signal erase_requested


var code:String
var Name:Button = Button.new()
var Erase:Button = Button.new()
var index = -1


func _ready() -> void:
	Erase.focus_mode = Control.FOCUS_NONE ; Name.focus_mode = Control.FOCUS_NONE
	custom_minimum_size.y = 20.0 ; Name.custom_minimum_size.x = 170 ; Erase.custom_minimum_size.x = 20.0
	Name.alignment = HORIZONTAL_ALIGNMENT_LEFT
	Erase.text = 'X'
	
	Name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	self.add_child(Name)
	self.add_child(Erase)
	
	Name.pressed.connect(func():code_requested.emit())
	Erase.pressed.connect(func():erase_requested.emit())


func set_layer_name(value:String):
	name = value ; Name.text = name
