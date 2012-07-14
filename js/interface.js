$(document).ready(function() {
    // Set up the drag and drop
    var dropbox = document.getElementById("dropbox");
    dropbox.addEventListener("dragenter", dragEnter, false);
    dropbox.addEventListener("dragexit", dragExit, false);
    dropbox.addEventListener("dragover", dragOver, false);
    dropbox.addEventListener("drop", drop, false);


    $('#tabs').tabs();
    $('.button').button();
    $('.datepicker').datepicker();
    $('#files').change(openFile);

    $('#doGraph').click(doGraph);
    $('#downloadGraph').click(downloadSVG);
    $('#gentwopoints').click(genTwoPoints);
    $('#genpointslope').click(genPointSlope);

});

function doGraph() {
        updatePicture(0);
        $('svg').append('<asciisvg>' + $('#picture1input').val() + '</asciisvg>');
}

function importSVG(svgText) {
    $('#outputNode').html(svgText);
    // if we have an embedded asciisvg command, grab it
    var previousAsciisvgCommand = $('#outputNode svg asciisvg').text();
    console.log(previousAsciisvgCommand)
    if (previousAsciisvgCommand) {
        $('#picture1input').val(previousAsciisvgCommand);
    }
    //console.log(svgText)
}

// Generate a line through the given points
function genTwoPoints(){
    var text = $('#twopoints').val();
    match = text.match(/\((.*),(.*)\)\s*;\s*\((.*),(.*)\)/);
    if (!match) {
        return;
    }

    var x1,y1,x2,y2;
    x1 = match[1];
    y1 = match[2];
    x2 = match[3];
    y2 = match[4];

    var m = (y2-y1)/(x2-x1);
    
    var outputEquation = 'plot("'+m+'*(x-('+x1+'))+('+y1+')")\n';
    outputEquation    += 'dot(['+x1+','+y1+'], "closed")\n';
    outputEquation    += 'dot(['+x2+','+y2+'], "closed")\n';

    $('#genout').val(outputEquation);
}

// Generate a line through the given points
function genPointSlope(){
    var text = $('#pointslope').val();
    match = text.match(/m=(.*)\s*;\s*\((.*),(.*)\)/);
    if (!match) {
        return;
    }

    var m,x1,y1;
    m = match[1]
    x1 = match[2];
    y1 = match[3];

    var outputEquation = 'plot("'+m+'*(x-('+x1+'))+('+y1+')")\n';
    outputEquation    += 'dot(['+x1+','+y1+'], "closed")\n';

    $('#genout').val(outputEquation);
}

function downloadSVG() {
    //document.location.href = 'data:image/svg+xml;base64,' + btoa($('#outputNode').html());

    $('#doGraph').click();
    // Prompt for a save-as dialog witht the svg data
    document.location.href = 'data:application/octet-stream;base64,' + btoa($('#outputNode').html());
}


// Decode dataURI
function decodeDataURI(dataURI) {
    var content = dataURI.indexOf(","), meta = dataURI.substr(5, content).toLowerCase(), data = decodeURIComponent(dataURI.substr(content + 1));
	
    if (/;\s*base64\s*[;,]/.test(meta)) {
        data = atob(data); // decode base64
	}
    if (/;\s*charset=[uU][tT][fF]-?8\s*[;,]/.test(meta)) {
        data = decodeURIComponent(escape(data)); // decode UTF-8
    }
	
    return data;
};



// Drag and drop functions
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
function openFile(evt) {
    var files = evt.target.files;
    if (files.length > 0) {
        handleFiles(files);
    }
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
//		$("#progressbar").progressbar({ value: loaded * 100 });
    }
}

function handleReaderLoadEnd(evt) {
    //$("#progressbar").progressbar({ value: 100 });
    if (evt.target.error) {
        $('#errorCode').html(evt.target.error + ' Error Code: ' + evt.target.error.code + ' ');
        $('#errorDialog').dialog('open');
        return;
    }
    var data = decodeDataURI(evt.target.result);
    importSVG(data);
}
