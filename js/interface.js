// Generated by CoffeeScript 1.3.3
/*
# Smart typeof function that will recognize builtin types as well as objects
# that are instances of those types.
*/

var CodeError, DownloadManager, FileHandler, deleteGraphFromGraphData, displayExamples, historyClearAll, historyLoadFromFile, initializeGraphHistory, loadDocumentation, loadExamples, loadGraph, loadGraphFromGraphData, makeEditable, resizeGraph, round, saveGraph, setGraphFromSvg, typeOf, updateGraph, validateNumber, wrap,
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

wrap = function(s) {
  var ret;
  ret = s;
  switch (typeOf(s)) {
    case 'string':
      ret = "'" + s + "'";
      break;
    case 'array':
      ret = "[" + (s.join(', ')) + "]";
  }
  return ret;
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
      value: btoa(this.data)
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
    var bb, blob, buf, bufView, downloadLink, i, url, _i, _ref;
    if (errorCallback == null) {
      errorCallback = this.download;
    }
    try {
      buf = new ArrayBuffer(this.data.length);
      bufView = new Uint8Array(buf);
      for (i = _i = 0, _ref = this.data.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        bufView[i] = this.data.charCodeAt(i) & 0xff;
      }
      try {
        blob = new Blob(buf, {
          type: 'application/octet-stream'
        });
      } catch (e) {
        bb = new (window.WebKitBlobBuilder || window.MozBlobBuilder);
        bb.append(buf);
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
    return document.location.href = "data:application/octet-stream;base64," + btoa(this.data);
  };

  return DownloadManager;

})();

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
  $('.work-area').click(function(evt) {
    if (evt.target === this) {
      inputArea.focus();
      return inputArea.setCursor({
        line: Infinity,
        ch: 0
      });
    }
  });
  $('.svg-stat.editable').map(function() {
    return makeEditable(this, resizeGraph);
  });
  $('#update-graph').click(updateGraph);
  $('#save-graph').click(function() {
    return $('#save-dialog').dialog('open');
  });
  $('#load-graph').click(loadGraph);
  $('#history-load-from-file').click(historyLoadFromFile);
  $('#history-clear-all').click(historyClearAll);
  $('#dropcontainer').hide();
  $('body')[0].addEventListener('dragenter', FileHandler.dragEnter, false);
  $('body')[0].addEventListener('dragexit', FileHandler.dragExit, false);
  $('#dropbox')[0].addEventListener('dragover', FileHandler.dragOver, false);
  $('body')[0].addEventListener('drop', FileHandler.drop, false);
  $('#hide-dropbox').click(function() {
    return FileHandler.dragExit();
  });
  $('#save-dialog').dialog({
    autoOpen: false,
    buttons: {
      'Save': function() {
        var fileFormat, fileName;
        fileFormat = $('#file-format :selected').val();
        fileName = "graph." + fileFormat;
        saveGraph(fileName, fileFormat);
        return $(this).dialog('close');
      },
      'Cancel': function() {
        return $(this).dialog('close');
      }
    }
  });
  resizeGraph();
  initializeGraphHistory();
  loadExamples();
  try {
    loadDocumentation();
  } catch (e) {
    '';

  }
  window.pdfkit.modules['./reference'].exports.prototype.finalize = function(compress) {
    var compressedData, data, i, _base, _ref;
    if (compress == null) {
      compress = false;
    }
    if (this.stream) {
      data = this.stream.join('\n');
      if (compress) {
        data = new Buffer((function() {
          var _i, _ref, _results;
          _results = [];
          for (i = _i = 0, _ref = data.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
            _results.push(data.charCodeAt(i));
          }
          return _results;
        })());
        compressedData = zlib.deflate(data);
        this.finalizedStream = compressedData.toString('binary');
        this.data.Filter = 'FlateDecode';
      } else {
        this.finalizedStream = data;
      }
      return (_ref = (_base = this.data).Length) != null ? _ref : _base.Length = this.finalizedStream.length;
    } else {
      return this.finalizedStream = '';
    }
  };
  PDFDocument.prototype.undash = function() {
    return this.addContent("[] 0 d");
  };
});

loadDocumentation = function() {
  var c, consts, elm, funcs, i, info, item, m, name, strconsts, target, val, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _results;
  target = $('#mathfunctions');
  consts = [];
  strconsts = [];
  funcs = [];
  for (item in MathFunctions) {
    val = MathFunctions[item];
    switch (typeOf(val)) {
      case 'function':
        funcs.push(item);
        break;
      case 'string':
        strconsts.push(item);
        break;
      case 'number':
        consts.push(item);
    }
  }
  consts.sort();
  strconsts.sort();
  funcs.sort();
  for (_i = 0, _len = strconsts.length; _i < _len; _i++) {
    name = strconsts[_i];
    target.append("<li>" + name + " = '" + MathFunctions[name] + "'</li>");
  }
  for (_j = 0, _len1 = consts.length; _j < _len1; _j++) {
    name = consts[_j];
    target.append("<li>" + name + " &asymp; " + MathFunctions[name] + "</li>");
  }
  for (_k = 0, _len2 = funcs.length; _k < _len2; _k++) {
    name = funcs[_k];
    target.append("<li>" + name + "()</li>");
  }
  target = $('#graphingconstants');
  consts = (function() {
    var _results;
    _results = [];
    for (c in nAsciiSVG.constants) {
      _results.push(c);
    }
    return _results;
  })();
  consts.sort();
  for (_l = 0, _len3 = consts.length; _l < _len3; _l++) {
    name = consts[_l];
    info = nAsciiSVG.constants[name];
    elm = $("<li><span class='name'>" + name + "</span></li>");
    if (info["default"]) {
      elm.append("<span class='default'>" + (wrap(info["default"])) + "</span>");
    }
    if (info.type) {
      elm.append("<span class='type'>" + info.type + "</span>");
    }
    if (info.options) {
      elm.append("<span class='options'>" + (((function() {
        var _len4, _m, _ref, _results;
        _ref = info.options;
        _results = [];
        for (_m = 0, _len4 = _ref.length; _m < _len4; _m++) {
          i = _ref[_m];
          _results.push(wrap(i));
        }
        return _results;
      })()).join(', ')) + "</span>");
    }
    if (info.description) {
      elm.append("<span class='description'>" + info.description + "</span>");
    }
    target.append(elm);
  }
  target = $('#graphingfunctions');
  consts = (function() {
    var _results;
    _results = [];
    for (c in nAsciiSVG.functions) {
      _results.push(c);
    }
    return _results;
  })();
  consts.sort();
  _results = [];
  for (_m = 0, _len4 = consts.length; _m < _len4; _m++) {
    name = consts[_m];
    elm = $("<li><span class='name'>" + name + "</span></li>");
    info = nAsciiSVG[name].toString();
    m = info.match(/function\s*\((.*)\)/);
    if (m != null) {
      info = m[1];
      elm.append("(" + info + ")");
    }
    _results.push(target.append(elm));
  }
  return _results;
};

/*
# Small collection of functions to display an error popup for
# inputArea code errors
*/


CodeError = {
  inputAreaLineNumbersOriginalState: false,
  currentlyMarkedErrors: [],
  mark: function(err) {
    var enterHandler, id, leaveHandler, marker;
    CodeError.inputAreaLineNumbersOriginalState = inputArea.getOption('lineNumber');
    inputArea.setOption('lineNumbers', true);
    id = "lineerror" + err.lineNumber;
    marker = inputArea.setMarker(err.lineNumber - 1, "<span id='" + id + "' style='color:red'>!! %N%</span>");
    marker.err = err;
    marker.tooltip = $("<div class='errortooltip'>" + err + "<br />" + err.sourceLine + "</div>");
    marker.tooltip.hide();
    $(document.body).append(marker.tooltip);
    enterHandler = function(evt) {
      var elm, left, top, _ref;
      elm = $(evt.currentTarget);
      _ref = elm.offset(), top = _ref.top, left = _ref.left;
      top += elm.height();
      marker.tooltip.css({
        left: left,
        top: top,
        'z-index': 1000
      });
      return marker.tooltip.show();
    };
    leaveHandler = function() {
      return marker.tooltip.hide();
    };
    $('#' + id).hover(enterHandler, leaveHandler);
    $(document.body).append(marker.tooltip);
    return CodeError.currentlyMarkedErrors.push(marker);
  },
  unmarkAll: function() {
    var marker, _i, _len, _ref;
    _ref = CodeError.currentlyMarkedErrors;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      marker = _ref[_i];
      inputArea.clearMarker(marker);
      marker.tooltip.remove();
      marker.tooltip = null;
    }
    inputArea.setOption('lineNumbers', CodeError.inputAreaLineNumbersOriginalState);
    return CodeError.currentlyMarkedErrors = [];
  }
};

/*
# Draw the current graph to #svg-preview
*/


updateGraph = function() {
  try {
    CodeError.unmarkAll();
    nAsciiSVG.updatePicture(inputArea.getValue(), $("#target")[0], 'svg');
  } catch (err) {
    window.err = err;
    if ((err.lineNumber != null) && err.lineNumber <= inputArea.lineCount()) {
      CodeError.mark(err);
    } else {
      throw err;
    }
  }
  return $("#target").append("<asciisvg>" + inputArea.getValue() + "</asciisvg>");
};

/*
# Saves the graph currently in the preview area
*/


saveGraph = function(fileName, fileFormat) {
  var canvas, cloned, ctx, data, downloadManager, graphData, hash, height, htmlifiedSvg, pdfDoc, pdfRaw, savedGraphList, svgText, thumbnail, width;
  updateGraph();
  cloned = $('#target').clone();
  htmlifiedSvg = $('<div></div>').append(cloned);
  svgText = htmlifiedSvg.html();
  $.jStorage.reInit();
  savedGraphList = $.jStorage.get('savedgraphs') || {};
  graphData = new GraphData(svgText);
  graphData.onclick = loadGraphFromGraphData;
  graphData.ondelete = deleteGraphFromGraphData;
  thumbnail = graphData.createThumbnail();
  graphData.makeDeletable();
  hash = graphData.hash();
  if (!savedGraphList[hash]) {
    $('#history-gallery .gallery-container').append(thumbnail);
    savedGraphList[graphData.hash()] = graphData.toJSON();
    $.jStorage.set('savedgraphs', savedGraphList);
  }
  window.lastSavedGraph = graphData.toJSON();
  width = parseFloat($('#svg-preview').children().attr('width'));
  height = parseFloat($('#svg-preview').children().attr('height'));
  if (fileFormat === 'svg') {
    downloadManager = new DownloadManager(fileName, svgText, 'image/svg+xml');
  } else if (fileFormat === 'pdf') {
    pdfDoc = new PDFDocument({
      size: [width, height]
    });
    nAsciiSVG.ctx.playbackTo(pdfDoc, 'pdf');
    pdfDoc.info['graphitCode'] = inputArea.getValue();
    pdfRaw = pdfDoc.output();
    window.pdfDoc = pdfDoc;
    downloadManager = new DownloadManager(fileName, pdfRaw, 'application/pdf');
  } else if (fileFormat === 'png') {
    canvas = $("<canvas width='" + width + "' height='" + height + "'></canvas>")[0];
    ctx = canvas.getContext('2d');
    nAsciiSVG.ctx.playbackTo(ctx, 'canvas');
    data = canvas.toDataURL('image/png');
    data = atob(data.slice('data:image/png;base64,'.length));
    downloadManager = new DownloadManager(fileName, data, 'image/png');
  }
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
  $('#svg-preview').children().attr({
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
    var code, data, height, m, width;
    if (evt.target.error) {
      throw new Error(evt.target.error + " Error Code: " + evt.target.error.code + " ");
      return;
    }
    data = FileHandler.decodeDataURI(evt.target.result);
    if (data.slice(0, 4) === '%PDF') {
      m = data.match(/\/graphitCode \(([\s\S]*?[^\\])\)/);
      if (!(m != null)) {
        throw new Error("Could not extract graphit code from PDF");
      }
      m = m[1];
      code = m.replace(/\\\(/g, '(').replace(/\\\)/g, ')').replace(/\\\\/g, '\\');
      m = data.match(/\/MediaBox [0 0 (\d+) (\d+)]/);
      if (m != null) {
        width = m[1];
        height = m[2];
      } else {
        width = 550;
        height = 450;
      }
      resizeGraph({
        width: width,
        height: height
      });
      inputArea.setValue(code);
      updateGraph();
      return;
    }
    return setGraphFromSvg(data);
  },
  dragEnter: function(evt) {
    $('#dropcontainer').show();
    $('.tabs').hide();
    $('#forkme').hide();
    evt.stopPropagation();
    return evt.preventDefault();
  },
  dragExit: function(evt) {
    $('#dropcontainer').hide();
    $('#dropbox').removeClass('dropbox-hover');
    $('.tabs').show();
    $('#forkme').show();
    if (evt != null) {
      evt.stopPropagation();
      return evt.preventDefault();
    }
  },
  dragOver: function(evt, b) {
    if (!(evt != null)) {
      $('#dropbox').removeClass('dropbox-hover');
      return;
    }
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
