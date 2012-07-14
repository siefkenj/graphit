$(document).ready(function() {
	var dropbox = document.getElementById("dropbox")

	// init event handlers
	dropbox.addEventListener("dragenter", dragEnter, false);
	dropbox.addEventListener("dragexit", dragExit, false);
	dropbox.addEventListener("dragover", dragOver, false);
	dropbox.addEventListener("drop", drop, false);

	// init the widgets
	$("#progressbar").progressbar();
});

// Decode dataURI
var decodeDataURI = function decodeDataURI (dataURI) {
	var
		content = dataURI.indexOf(",")
		,meta = dataURI.substr(5, content).toLowerCase()
		// 'data:'.length == 5
		,data = decodeURIComponent(dataURI.substr(content + 1))
	;
	
	if (/;\s*base64\s*[;,]/.test(meta)) {
		data = atob(data); // decode base64
	}
	if (/;\s*charset=[uU][tT][fF]-?8\s*[;,]/.test(meta)) {
		data = decodeURIComponent(escape(data)); // decode UTF-8
	}
	
	return data;
};


function dragEnter(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function dragExit(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function dragOver(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function drop(evt) {
	evt.stopPropagation();
	evt.preventDefault();

	var files = evt.dataTransfer.files;
	var count = files.length;

	// Only call the handler if 1 or more files was dropped.
	if (count > 0)
		handleFiles(files);
}


function handleFiles(files) {
	var file = files[0];

	document.getElementById("droplabel").innerHTML = "Processing " + file.name;

	var reader = new FileReader();

	// init the reader event handlers
	reader.onprogress = handleReaderProgress;
	reader.onloadend = handleReaderLoadEnd;

	// begin the read operation
	reader.readAsDataURL(file);
}

function handleReaderProgress(evt) {
	if (evt.lengthComputable) {
		var loaded = (evt.loaded / evt.total);

		$("#progressbar").progressbar({ value: loaded * 100 });
	}
}

function handleReaderLoadEnd(evt) {
	$("#progressbar").progressbar({ value: 100 });
        var data = decodeDataURI(evt.target.result);
        document.getElementById("droplabel").innerHTML = data;
        console.log(CSVToArray(data))
}
