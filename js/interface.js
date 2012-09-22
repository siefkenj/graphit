// Generated by CoffeeScript 1.3.3
/*
# Smart typeof function that will recognize builtin types as well as objects
# that are instances of those types.
*/

var DownloadManager, FileHandler, deleteGraphFromGraphData, displayExamples, historyClearAll, historyLoadFromFile, initializeGraphHistory, loadExamples, loadGraph, loadGraphFromGraphData, makeEditable, resizeGraph, round, saveGraph, setGraphFromSvg, typeOf, updateGraph, validateNumber,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

typeOf = function(obj) {
  var constructor, constructorName, guess, objectTypes, type;
  guess = typeof obj;
  if (guess !== 'object') {
    return guess;
  }
  if (obj === null) {
    return 'null';
  }
  objectTypes = {
    'array': Array,
    'boolean': Boolean,
    'number': Number,
    'string': String
  };
  for (type in objectTypes) {
    constructor = objectTypes[type];
    if (obj instanceof constructor) {
      return type;
    }
  }
  constructorName = obj.constructor.name;
  if (constructorName === 'Object') {
    return 'object';
  }
  return constructorName;
};

/*
# Set up the interface
*/


$(document).ready(function() {
  $('.tabs').tabs();
  $('.button').button();
  window.inputArea = CodeMirror.fromTextArea($("#code")[0], {
    indentWithTabs: true,
    smartIndent: false,
    mode: "text/javascript"
  });
  $('.svg-stat.editable').map(function() {
    return makeEditable(this, resizeGraph);
  });
  $('#update-graph').click(updateGraph);
  $('#save-graph').click(saveGraph);
  $('#load-graph').click(loadGraph);
  $('#history-load-from-file').click(historyLoadFromFile);
  $('#history-clear-all').click(historyClearAll);
  $('#dropbox').hide();
  $('body')[0].addEventListener('dragenter', FileHandler.dragEnter, false);
  $('body')[0].addEventListener('dragexit', FileHandler.dragExit, false);
  $('#dropbox')[0].addEventListener('dragover', FileHandler.dragOver, false);
  $('body')[0].addEventListener('drop', FileHandler.drop, false);
  resizeGraph();
  initializeGraphHistory();
  return loadExamples();
});

/*
# Draw the current graph to #svg-preview
*/


updateGraph = function() {
  try {
    AsciiSVG.updatePicture(inputArea.getValue(), $("#target")[0]);
  } catch (err) {
    if (err.lineNumber != null) {
      alert("" + err + "\nline number: " + err.lineNumber + "\nline: " + err.sourceLine);
    } else {
      throw err;
    }
  }
  return $("#target").append("<asciisvg>" + inputArea.getValue() + "</asciisvg>");
};

/*
# Various methods of downloading data to the users compuer so they can save it.
# Initially DownloadManager.download will try to bounce off download.php,
# a server-side script that sends the data it receives back with approprate
# headers.  If this fails, it will try to use the blob API to and the
# 'download' attribute of an anchor to download the file with a suggested file name.
# If this fails, a dataURI is used.
*/


DownloadManager = (function() {

  DownloadManager.prototype.DOWNLOAD_SCRIPT = 'download.php';

  function DownloadManager(filename, data, mimetype) {
    this.filename = filename;
    this.data = data;
    this.mimetype = mimetype != null ? mimetype : 'application/octet-stream';
    this.downloadDataUriBased = __bind(this.downloadDataUriBased, this);

    this.downloadBlobBased = __bind(this.downloadBlobBased, this);

    this.downloadServerBased = __bind(this.downloadServerBased, this);

    this.testDataUriAvailability = __bind(this.testDataUriAvailability, this);

    this.testBlobAvailability = __bind(this.testBlobAvailability, this);

    this.testServerAvailability = __bind(this.testServerAvailability, this);

    this.download = __bind(this.download, this);

    this.downloadMethodAvailable = {
      serverBased: null,
      blobBased: null,
      dataUriBased: null
    };
  }

  DownloadManager.prototype.download = function() {
    if (this.downloadMethodAvailable.serverBased === null) {
      this.testServerAvailability(this.download);
      return;
    }
    if (this.downloadMethodAvailable.serverBased === true) {
      this.downloadServerBased();
      return;
    }
    if (this.downloadMethodAvailable.blobBased === null) {
      this.testBlobAvailability(this.download);
      return;
    }
    if (this.downloadMethodAvailable.blobBased === true) {
      this.downloadBlobBased();
      return;
    }
    if (this.downloadMethodAvailable.dataUriBased === null) {
      this.testDataUriAvailability(this.download);
      return;
    }
    if (this.downloadMethodAvailable.dataUriBased === true) {
      this.downloadDataUriBased();
    }
  };

  DownloadManager.prototype.testServerAvailability = function(callback) {
    var _this = this;
    if (callback == null) {
      callback = function() {};
    }
    return $.ajax({
      url: this.DOWNLOAD_SCRIPT,
      dataType: 'text',
      success: function(data, status, response) {
        if (response.getResponseHeader('Content-Description') === 'File Transfer') {
          _this.downloadMethodAvailable.serverBased = true;
        } else {
          _this.downloadMethodAvailable.serverBased = false;
        }
        return callback.call(_this);
      },
      error: function(data, status, response) {
        _this.downloadMethodAvailable.serverBased = false;
        return callback.call(_this);
      }
    });
  };

  DownloadManager.prototype.testBlobAvailability = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    if ((window.webkitURL || window.URL) && (window.Blob || window.MozBlobBuilder || window.WebKitBlobBuilder)) {
      this.downloadMethodAvailable.blobBased = true;
    } else {
      this.downloadMethodAvailable.blobBased = true;
    }
    return callback.call(this);
  };

  DownloadManager.prototype.testDataUriAvailability = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    this.downloadMethodAvailable.dataUriBased = true;
    return callback.call(this);
  };

  DownloadManager.prototype.downloadServerBased = function() {
    var form, input1, input2, input3;
    input1 = $('<input type="hidden"></input>').attr({
      name: 'filename',
      value: this.filename
    });
    input2 = $('<input type="hidden"></input>').attr({
      name: 'data',
      value: this.data
    });
    input3 = $('<input type="hidden"></input>').attr({
      name: 'mimetype',
      value: this.mimetype
    });
    form = $('<form action="' + this.DOWNLOAD_SCRIPT + '" method="post" target="downloads_iframe"></form>');
    form.append(input1).append(input2).append(input3);
    return form.appendTo(document.body).submit().remove();
  };

  DownloadManager.prototype.downloadBlobBased = function(errorCallback) {
    var bb, blob, downloadLink, url;
    if (errorCallback == null) {
      errorCallback = this.download;
    }
    try {
      try {
        blob = new Blob([this.data], {
          type: 'application/octet-stream'
        });
      } catch (e) {
        bb = new (window.WebKitBlobBuilder || window.MozBlobBuilder);
        bb.append(this.data);
        blob = bb.getBlob('application/octet-stream');
      }
      url = (window.webkitURL || window.URL).createObjectURL(blob);
      downloadLink = $('<a></a>').attr({
        href: url,
        download: this.filename
      });
      $(document.body).append(downloadLink);
      downloadLink[0].click();
      return downloadLink.remove();
    } catch (e) {
      this.downloadMethodAvailable.blobBased = false;
      return errorCallback.call(this);
    }
  };

  DownloadManager.prototype.downloadDataUriBased = function() {
    console.log('daturi');
    return document.location.href = "data:application/octet-stream;base64," + btoa(this.data);
  };

  return DownloadManager;

})();

/*
# Saves the graph currently in the preview area
*/


saveGraph = function() {
  var cloned, downloadManager, graphData, htmlifiedSvg, savedGraphList, svgText, thumbnail;
  updateGraph();
  cloned = $('#target').clone();
  htmlifiedSvg = $('<div></div>').append(cloned);
  svgText = htmlifiedSvg.html();
  graphData = new GraphData(svgText);
  graphData.onclick = loadGraphFromGraphData;
  graphData.ondelete = deleteGraphFromGraphData;
  thumbnail = graphData.createThumbnail();
  graphData.makeDeletable();
  $('#history-gallery .gallery-container').append(thumbnail);
  $.jStorage.reInit();
  savedGraphList = $.jStorage.get('savedgraphs') || {};
  savedGraphList[graphData.hash()] = graphData.toJSON();
  $.jStorage.set('savedgraphs', savedGraphList);
  window.lastSavedGraph = graphData.toJSON();
  downloadManager = new DownloadManager('graph.svg', svgText, 'image/svg+xml');
  return downloadManager.download();
};

loadGraph = function() {
  var dialog, fileInput;
  if (!navigator.userAgent.match('Chrome')) {
    fileInput = $('<input type="file" id="files" name="files[]" accept="image/svg+xml" />');
    fileInput.change(function(event) {
      var files;
      files = event.target.files;
      return FileHandler.handleFiles(files);
    });
    return fileInput.trigger('click');
  } else {
    dialog = $('<div>\n    <h3>Browse for the file you wish to upload</h3>\n    <input type="file" id="files" name="files[]" accept="image/svg+xml" />\n</div>');
    $(document.body).append(dialog);
    dialog.dialog({
      height: 300,
      width: 500,
      modal: true
    });
    return dialog.find('input').change(function(event) {
      var files;
      files = event.target.files;
      FileHandler.handleFiles(files);
      return dialog.remove();
    });
  }
};

resizeGraph = function(dims) {
  var aspect;
  if (!(dims != null ? dims.width : void 0) || (dims != null ? dims.height : void 0)) {
    dims = {
      width: Math.max(1, parseInt($('#svg-stat-width').text(), 10)),
      height: Math.max(1, parseInt($('#svg-stat-height').text(), 10))
    };
  }
  aspect = dims.width / dims.height;
  $('#svg-stat-aspect').text(round(aspect, 2));
  $('#target').attr({
    width: dims.width,
    height: dims.height
  });
  return updateGraph();
};

setGraphFromSvg = function(svgText) {
  var graphData;
  graphData = new GraphData(svgText);
  inputArea.setValue(graphData.javascriptText);
  $('#svg-stat-width').text(graphData.width);
  $('#svg-stat-height').text(graphData.height);
  $('#svg-preview').html(graphData.svgText);
  return $('#svg-preview svg').attr({
    id: 'target',
    width: graphData.width,
    height: graphData.height
  });
};

initializeGraphHistory = function() {
  var graph, key, savedGraphList, thumbnail, thumnailList, _results;
  thumnailList = $('#history-gallery .gallery-container');
  $.jStorage.reInit();
  savedGraphList = $.jStorage.get('savedgraphs') || {};
  thumnailList.empty();
  _results = [];
  for (key in savedGraphList) {
    graph = savedGraphList[key];
    graph = GraphData.fromJSON(graph);
    graph.onclick = loadGraphFromGraphData;
    graph.ondelete = deleteGraphFromGraphData;
    thumbnail = graph.createThumbnail();
    graph.makeDeletable();
    _results.push(thumnailList.append(thumbnail));
  }
  return _results;
};

loadGraphFromGraphData = function(graphData) {
  if (graphData.width) {
    $('#svg-stat-width').text(graphData.width);
  }
  if (graphData.height) {
    $('#svg-stat-height').text(graphData.height);
  }
  inputArea.setValue(graphData.javascriptText);
  return resizeGraph();
};

historyLoadFromFile = function() {
  return loadGraph();
};

historyClearAll = function() {
  $('#history-gallery .gallery-container').empty();
  $.jStorage.reInit();
  return $.jStorage.set('savedgraphs', {});
};

deleteGraphFromGraphData = function(graphData) {
  var hash, savedGraphList;
  if (typeOf(graphData) === 'GraphData') {
    hash = graphData.hash();
  } else {
    hash = graphData;
  }
  $.jStorage.reInit();
  savedGraphList = $.jStorage.get('savedgraphs') || {};
  delete savedGraphList[hash];
  $.jStorage.set('savedgraphs', savedGraphList);
  if (graphData.thumbnail != null) {
    return graphData.thumbnail.remove();
  }
};

FileHandler = {
  decodeDataURI: function(dataURI) {
    var content, data, meta;
    content = dataURI.indexOf(",");
    meta = dataURI.substr(5, content).toLowerCase();
    data = decodeURIComponent(dataURI.substr(content + 1));
    if (/;\s*base64\s*[;,]/.test(meta)) {
      data = atob(data);
    }
    if (/;\s*charset=[uU][tT][fF]-?8\s*[;,]/.test(meta)) {
      data = decodeURIComponent(escape(data));
    }
    return data;
  },
  handleFiles: function(files) {
    var file, reader;
    file = files[0];
    reader = new FileReader();
    reader.onprogress = FileHandler.handleReaderProgress;
    reader.onloadend = FileHandler.handleReaderLoadEnd;
    return reader.readAsDataURL(file);
  },
  handleReaderProgress: function(evt) {
    var percentLoaded;
    if (evt.lengthComputable) {
      return percentLoaded = evt.loaded / evt.total;
    }
  },
  handleReaderLoadEnd: function(evt) {
    var data;
    if (evt.target.error) {
      throw new Error(evt.target.error + " Error Code: " + evt.target.error.code + " ");
      return;
    }
    data = FileHandler.decodeDataURI(evt.target.result);
    return setGraphFromSvg(data);
  },
  dragEnter: function(evt) {
    $('#dropbox').show();
    $('.tabs').hide();
    evt.stopPropagation();
    return evt.preventDefault();
  },
  dragExit: function(evt) {
    $('#dropbox').hide();
    $('#dropbox').removeClass('dropbox-hover');
    $('.tabs').show();
    evt.stopPropagation();
    return evt.preventDefault();
  },
  dragOver: function(evt, b) {
    $('#dropbox').addClass('dropbox-hover');
    evt.stopPropagation();
    return evt.preventDefault();
  },
  drop: function(evt) {
    var count, files;
    evt.stopPropagation();
    evt.preventDefault();
    files = evt.dataTransfer.files;
    count = files.length;
    if (count > 0) {
      FileHandler.handleFiles(files);
    }
    return FileHandler.dragExit();
  }
};

loadExamples = function(url) {
  if (url == null) {
    url = 'examples/examples.json';
  }
  return $.ajax({
    url: url,
    dataType: 'text',
    success: displayExamples
  });
};

displayExamples = function(examplesJSON) {
  var exampleList, graph, graphJSON, thumbnail, _i, _len, _results;
  exampleList = $.parseJSON(examplesJSON);
  _results = [];
  for (_i = 0, _len = exampleList.length; _i < _len; _i++) {
    graphJSON = exampleList[_i];
    graph = GraphData.fromJSON(graphJSON);
    graph.onclick = function(data) {
      $('.tabs').tabs('select', '#graph');
      return loadGraphFromGraphData(data);
    };
    thumbnail = graph.createThumbnail();
    _results.push($('#examples .gallery-container').append(thumbnail));
  }
  return _results;
};

/*
# interface utility functions
*/


round = function(num, places) {
  var p;
  p = Math.pow(10, places);
  return Math.round(num * p) / p;
};

validateNumber = function(txt, positive, integer, max, min) {
  var ret;
  if (positive == null) {
    positive = true;
  }
  if (integer == null) {
    integer = true;
  }
  if (max == null) {
    max = 10e10;
  }
  if (min == null) {
    min = -10e10;
  }
  ret = 0;
  switch (typeOf(txt)) {
    case 'number':
      ret = txt;
      break;
    case 'string':
      ret = parseFloat(txt);
  }
  if (isNaN(ret)) {
    ret = 0;
  }
  if (ret > max) {
    ret = max;
  } else if (ret < min) {
    ret = min;
  }
  if (positive) {
    ret = Math.abs(ret);
  }
  if (integer) {
    ret = Math.round(ret);
  }
  return ret;
};

makeEditable = function(element, editFinishedCallback) {
  var previousValue;
  if (editFinishedCallback == null) {
    editFinishedCallback = (function() {
      return null;
    });
  }
  element = $(element);
  previousValue = element.html();
  element.live('focus', function() {
    var $this;
    $this = $(this);
    $this.data('before', $this.html());
    $this.data('initial-text', $this.html());
    return $this;
  });
  element.live('blur keyup paste', function() {
    var $this;
    $this = $(this);
    if ($this.data('before') !== $this.html()) {
      $this.data('before', $this.html());
      $this.trigger('change');
    }
    return $this;
  });
  element.keydown(function(event) {
    var $this;
    $this = $(this);
    if (event.which === 13) {
      $(this).blur();
      event.stopPropagation();
    }
    if (event.which === 27) {
      $this.html($this.data('initial-text'));
      $this.blur();
      return event.stopPropagation();
    }
  });
  return element.blur(function(event) {
    var $this, num, text;
    $this = $(this);
    text = $this.text();
    num = validateNumber(text);
    if (num === 0) {
      $this.html($this.data('initial-text'));
    } else {
      $this.html('' + num);
    }
    if ($this.html() !== previousValue) {
      previousValue = $this.html();
      return editFinishedCallback($this.html());
    }
  });
};
