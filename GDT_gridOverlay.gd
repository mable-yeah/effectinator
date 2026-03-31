class_name GridOverlay

#FLX GRID
#originally by Richard Davey / Photon Storm
#port my mae!!!!

#this version returns a texture, how you handle it is up to u


var Cell = null #width/height of the cells
var Size = null #width/height of the Sprite

var Alternate = null #stripes or checkers

var Rotated = false #rotate for stripes

var Color1 = null
var Color2 = null


func create(CellSize:Vector2 = Vector2(10,10),SpriteSize:Vector2 = Vector2(-1,-1),AlternatePatt = true,Color1_:Color = Color.hex(0xe7e6e6ff),Color2_:Color = Color.hex(0xd9d5d5ff)):
	var SCREEN = DisplayServer.screen_get_size() 
	#not accurate as its the ACTUAL screen size rather than the game's window resolution
	#but i cant get that from here so whatevs, this is a backup after all
	
	
	if SpriteSize.x == -1:
		SpriteSize.x = SCREEN.x
	if SpriteSize.y == -1:
		SpriteSize.y = SCREEN.y
	
	if SpriteSize < CellSize:
		return null
	
	
	if Rotated:
		SpriteSize = Vector2(SpriteSize.y,SpriteSize.x)
	
	if Cell == null:
		Cell = CellSize
	
	if Size == null:
		Size = SpriteSize
	
	if Alternate == null:
		Alternate = AlternatePatt
	
	if Color1 == null:
		Color1 = Color1_
	
	if Color2 == null:
		Color2 = Color2_
	
	var grid = createGrid()
	
	if Rotated:
		grid.rotate_90(CLOCKWISE)
	
	var output = ImageTexture.create_from_image(grid);
	return output


func createGrid():
	#How many cells can we fit into the width/height? 
	#(round it UP if not even, then trim back)
	Size.x = int(Size.x)
	Size.y = int(Size.y)
	
	
	Cell.x = int(Cell.x)
	Cell.y = int(Cell.y)
	
	var rowColor = Color1
	var lastColor = Color1
	
	var grid = Image.create(int(Size.x), int(Size.y), false, Image.FORMAT_RGBA8)
	
	#swap the lastColor value if the number of cells in a row isnt even
	var y = 0
	while y <= Size.y:
		if y > 0 and lastColor == rowColor and Alternate:
			lastColor = Color2 if (lastColor == Color1) else Color1
		else: if y > 0 and lastColor != rowColor and not Alternate:
			lastColor = Color1
		
		
		var x = 0
		
		while x <= Size.x:
			if x == 0:
				rowColor = lastColor
			
			
			fillRect(grid,x,y,lastColor)
			if lastColor == Color1:
				lastColor = Color2
			else:
				lastColor = Color1
			
			x += Cell.x;
		y += Cell.y;
	
	
	return grid;

func fillRect(grid,x,y,lastColor):
	for dy in range(Cell.y):
		for dx in range(Cell.x):
			var px = x + dx
			var py = y + dy
			if px < Size.x and py < Size.y:
				grid.set_pixel(px, py, lastColor)
