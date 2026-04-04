# how 2 use
drop in a png, or jpg and then write shader on the code panel on the right, press merge to combine it permanently with the image

colors can also be picked by right clicking the color picker in the top left returning them as '(0.0, 0.0, 0.0, 0.0)'

## format
code wise you can drop in any code from godot shaders provided it uses the actual texture
(uniform sampler2D's arent supported yet), and the shader is a 2d/canvas_item shader

you can also cut out the shader_type header from the shader as that is automatically inserted if not found

u can also do
>//layer_name = 'example'

..to change a layer name

>//include = [function_name,other_one,also_a_func]

..to add in a pre-made function
(replace with func name from shader_utility.gd)

>//canvas_size = [0.0,0.0]

..to change the size of the canvas/exported image
(the inputted value is multiplicative not an actual resolution)

