function getFile() {
	//thankyou javascript for being the stupidest language ever, you only beat python to first place by having try/catch
	var loaded;
	var cancelled;
	var glb_filters;
	var input = document.createElement("input");
	input.type = "file";
	input.multiple = false;
	
	async function saveFile(data_in){
		try {
			var filters = glb_filters.split(",") 
			var options = {
				types: [
				  {
					description: "custom file",
					accept: { "application/x-myapp-data": filters },
				  },
				],
			};	
			try { 
				var decoded = Uint8Array.fromBase64(data_in);
				data_in = decoded;
			}
			catch {}
			//image files are passed in as base64, so if the string ISNT base64 just catch NOTHING and continue storing it
			
			var handle = await window.showSaveFilePicker(options);
			console.log(handle.name);
			const writable = await handle.createWritable();
			await writable.write(data_in); 

			await writable.close();
			loaded('');
		}
		catch {
			cancelled();
		}
		
	}
	
	
	var interface = {
		setCancelled:(cancelled_call) => cancelled = cancelled_call,
		setLoad:(load_call) => loaded = load_call,
		setFilters: (filters) => {
			glb_filters = filters;
			input.setAttribute("accept", glb_filters);
		},
		pop:() => input.click(),
		pop_save: async(data_in) => saveFile(data_in)
		
	}

	input.onchange = (event) => {
		var file = event.target.files[0];
		var reader = new FileReader();
		if (!file){ cancelled(); return; }
		
		reader.addEventListener("load", () => {
			loaded(reader.result);
		}
		);
		reader.readAsText(file);
		
	}
	
	input.addEventListener('cancel', () => {
		cancelled();
	});

	return interface;
}


var dialog = getFile();