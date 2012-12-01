###
# Smart typeof function that will recognize builtin types as well as objects
# that are instances of those types.
###
typeOf = (obj) ->
    guess = typeof obj
    if guess != 'object'
        return guess
    if obj == null
        return 'null'

    # if we got 'object', we have some more work to do
    objectTypes =
        'array': Array
        'boolean': Boolean
        'number': Number
        'string': String
    for type, constructor of objectTypes
        if obj instanceof constructor
            return type

    # if we are not one of the builtin types, check to see if we have a named constructor
    constructorName = obj.constructor.name
    # If we truely are a plain-old object type, handle this now
    if constructorName == 'Object'
        return 'object'
    return constructorName

# wraps strings in quotes, otherwise does nothing
wrap = (s) ->
    ret = s
    switch typeOf(s)
        when 'string'
            ret = "'#{s}'"
        when 'array'
            ret = "[#{s.join(', ')}]"
    return ret

###
# Various methods of downloading data to the users compuer so they can save it.
# Initially DownloadManager.download will try to bounce off download.php,
# a server-side script that sends the data it receives back with approprate
# headers.  If this fails, it will try to use the blob API to and the
# 'download' attribute of an anchor to download the file with a suggested file name.
# If this fails, a dataURI is used.
###
class DownloadManager
    DOWNLOAD_SCRIPT: 'download.php'
    constructor: (@filename, @data, @mimetype='application/octet-stream') ->
    # a null status means no checks have been performed on whether that method will work
        @downloadMethodAvailable =
            serverBased: null
            blobBased: null
            dataUriBased: null

    # run through each download method and if it works,
    # use that method to download the graph.  @downloadMethodAvailable
    # starts as all null and will be set to true or false after a test has been run
    download: () =>
        if @downloadMethodAvailable.serverBased == null
            @testServerAvailability(@download)
            return
        if @downloadMethodAvailable.serverBased == true
            @downloadServerBased()
            return

        if @downloadMethodAvailable.blobBased == null
            @testBlobAvailability(@download)
            return
        if @downloadMethodAvailable.blobBased == true
            @downloadBlobBased()
            return

        if @downloadMethodAvailable.dataUriBased == null
            @testDataUriAvailability(@download)
            return
        if @downloadMethodAvailable.dataUriBased == true
            @downloadDataUriBased()
            return

    testServerAvailability: (callback = ->) =>
        $.ajax
            url: @DOWNLOAD_SCRIPT
            dataType: 'text'
            success: (data, status, response) =>
                if response.getResponseHeader('Content-Description') is 'File Transfer'
                    @downloadMethodAvailable.serverBased = true
                else
                    @downloadMethodAvailable.serverBased = false
                callback.call(this)
            error: (data, status, response) =>
                @downloadMethodAvailable.serverBased = false
                callback.call(this)

    testBlobAvailability: (callback = ->) =>
        if (window.webkitURL or window.URL) and (window.Blob or window.MozBlobBuilder or window.WebKitBlobBuilder)
            @downloadMethodAvailable.blobBased = true
        else
            @downloadMethodAvailable.blobBased = true
        callback.call(this)

    testDataUriAvailability: (callback = ->) =>
        # not sure how to check for this ...
        @downloadMethodAvailable.dataUriBased = true
        callback.call(this)

    downloadServerBased: () =>
        input1 = $('<input type="hidden"></input>').attr({name: 'filename', value: @filename})
        # encode our data in base64 so it doesn't get mangled by post (i.e., so '\n' to '\n\r' doesn't happen...)
        input2 = $('<input type="hidden"></input>').attr({name: 'data', value: btoa(@data)})
        input3 = $('<input type="hidden"></input>').attr({name: 'mimetype', value: @mimetype})
        # target=... is set to our hidden iframe so we don't change the url of our main page
        form = $('<form action="'+@DOWNLOAD_SCRIPT+'" method="post" target="downloads_iframe"></form>')
        form.append(input1).append(input2).append(input3)

        # submit the form and hope for the best!
        form.appendTo(document.body).submit().remove()

    downloadBlobBased: (errorCallback=@download) =>
        try
            # first convert everything to an arraybuffer so raw bytes in our string
            # don't get mangled
            buf = new ArrayBuffer(@data.length)
            bufView = new Uint8Array(buf)
            for i in [0...@data.length]
                bufView[i] = @data.charCodeAt(i) & 0xff

            try
                # This is the recommended method:
                blob = new Blob(buf, {type: 'application/octet-stream'})
            catch e
                # The BlobBuilder API has been deprecated in favour of Blob, but older
                # browsers don't know about the Blob constructor
                # IE10 also supports BlobBuilder, but since the `Blob` constructor
                # also works, there's no need to add `MSBlobBuilder`.
                bb = new (window.WebKitBlobBuilder || window.MozBlobBuilder)
                bb.append(buf)
                blob = bb.getBlob('application/octet-stream')

            url = (window.webkitURL || window.URL).createObjectURL(blob)

            downloadLink = $('<a></a>').attr({href: url, download: @filename})
            $(document.body).append(downloadLink)
            # trigger the file save dialog
            downloadLink[0].click()
            # clean up when we're done
            downloadLink.remove()
        catch e
            @downloadMethodAvailable.blobBased = false
            errorCallback.call(this)

    downloadDataUriBased: () =>
        document.location.href = "data:application/octet-stream;base64," + btoa(@data)

###
# Set up the interface
###
$(document).ready ->
    $('.tabs').tabs()
    $('.button').button()

    # set up CodeMirror in the editing window
    window.inputArea = CodeMirror.fromTextArea($("#code")[0],
        indentWithTabs: true
        smartIndent: false # if we don't end our lines with semicolons, this will try to indent them if enabled
        mode: "text/javascript"
    )
    # when we click in the blank space below the code area,
    # we should automatically set our focus to the code area
    $('.work-area').click (evt) ->
        if evt.target is this
            inputArea.focus()
            inputArea.setCursor({line: Infinity, ch: 0})

    $('.svg-stat.editable').map(-> makeEditable(this, resizeGraph))

    # set up the callbacks
    $('#update-graph').click updateGraph
    $('#save-graph').click ->
        $('#save-dialog').dialog('open')
    $('#load-graph').click loadGraph

    $('#history-load-from-file').click historyLoadFromFile
    $('#history-clear-all').click historyClearAll

    # set up the drag-and-drop
    $('#dropcontainer').hide()
    $('body')[0].addEventListener('dragenter', FileHandler.dragEnter, false)
    $('body')[0].addEventListener('dragexit', FileHandler.dragExit, false)
    $('#dropbox')[0].addEventListener('dragover', FileHandler.dragOver, false)
    $('body')[0].addEventListener('drop', FileHandler.drop, false)
    $('#hide-dropbox').click(-> FileHandler.dragExit())

    # set up the save dialog
    $('#save-dialog').dialog
        autoOpen: false
        buttons:
            'Save': ->
                fileFormat = $('#file-format :selected').val()
                fileName = "graph.#{fileFormat}"
                saveGraph(fileName, fileFormat)
                $(this).dialog('close')

            'Cancel': ->
                $(this).dialog('close')

    # initialize everything
    resizeGraph()
    initializeGraphHistory()
    loadExamples()
    try
        loadDocumentation()
    catch e
        ''

    # patch pdfkit-www since it contains an error where it doesnt
    # compute the length of uncompressed streams...
    window.pdfkit.modules['./reference'].exports.prototype.finalize = (compress=false) ->
        # cache the finalized stream
        if @stream
            data = @stream.join '\n'
            if compress
                # create a byte array instead of passing a string to the Buffer
                # fixes a weird unicode bug.
                data = new Buffer(data.charCodeAt(i) for i in [0...data.length])
                compressedData = zlib.deflate(data)
                @finalizedStream = compressedData.toString 'binary'
                @data.Filter = 'FlateDecode'
            else
                @finalizedStream = data
            @data.Length ?= @finalizedStream.length
        else
            @finalizedStream = ''
    #pdfkit.modules['./mixins/vector'].exports.undash = ->
    PDFDocument.prototype.undash = ->
        return @addContent("[] 0 d")

    return

loadDocumentation = ->
    # set up the math functions
    target = $('#mathfunctions')
    consts = []
    strconsts = []
    funcs = []
    for item,val of MathFunctions
        switch typeOf(val)
            when 'function'
                funcs.push item
            when 'string'
                strconsts.push item
            when 'number'
                consts.push item
    consts.sort()
    strconsts.sort()
    funcs.sort()
    for name in strconsts
        target.append("<li>#{name} = '#{MathFunctions[name]}'</li>")
    for name in consts
        target.append("<li>#{name} &asymp; #{MathFunctions[name]}</li>")
    for name in funcs
        target.append("<li>#{name}()</li>")

    # graphing constants
    target = $('#graphingconstants')
    consts = (c for c of nAsciiSVG.constants)
    consts.sort()
    for name in consts
        info = nAsciiSVG.constants[name]
        elm = $("<li><span class='name'>#{name}</span></li>")
        elm.append("<span class='default'>#{wrap(info.default)}</span>") if info.default
        elm.append("<span class='type'>#{info.type}</span>") if info.type
        elm.append("<span class='options'>#{(wrap(i) for i in info.options).join(', ')}</span>") if info.options
        elm.append("<span class='description'>#{info.description}</span>") if info.description
        target.append(elm)

    # graphing functions
    target = $('#graphingfunctions')
    consts = (c for c of nAsciiSVG.functions)
    consts.sort()
    for name in consts
        elm = $("<li><span class='name'>#{name}</span></li>")
        info = nAsciiSVG[name].toString()
        m = info.match(/function\s*\((.*)\)/)
        if m?
            info = m[1]
            elm.append("(#{info})")
        target.append(elm)

###
# Small collection of functions to display an error popup for
# inputArea code errors
###
CodeError =
    inputAreaLineNumbersOriginalState: false
    currentlyMarkedErrors: []
    mark: (err) ->
        CodeError.inputAreaLineNumbersOriginalState = inputArea.getOption('lineNumber')
        inputArea.setOption('lineNumbers', true)
        id = "lineerror#{err.lineNumber}"
        marker = inputArea.setMarker(err.lineNumber - 1, "<span id='#{id}' style='color:red'>!! %N%</span>")
        marker.err = err
        marker.tooltip = $("<div class='errortooltip'>#{err}<br />#{err.sourceLine}</div>")
        marker.tooltip.hide()
        $(document.body).append(marker.tooltip)
        enterHandler = (evt) ->
            # calculate the coordinates below the line number
            # where we should show the error
            elm = $(evt.currentTarget)
            {top, left} = elm.offset()
            top += elm.height()
            marker.tooltip.css({left: left, top: top, 'z-index': 1000})
            marker.tooltip.show()
        leaveHandler = ->
            marker.tooltip.hide()


        $('#'+id).hover(enterHandler, leaveHandler)
        $(document.body).append marker.tooltip
        CodeError.currentlyMarkedErrors.push marker
    unmarkAll: ->
        for marker in CodeError.currentlyMarkedErrors
            inputArea.clearMarker(marker)
            marker.tooltip.remove()
            marker.tooltip = null
        inputArea.setOption('lineNumbers', CodeError.inputAreaLineNumbersOriginalState)
        CodeError.currentlyMarkedErrors = []

###
# Draw the current graph to #svg-preview
###
updateGraph = ->
    try
        #AsciiSVG.updatePicture(inputArea.getValue(), $("#target_svg")[0])
        CodeError.unmarkAll()
        nAsciiSVG.updatePicture(inputArea.getValue(), $("#target")[0], 'svg')
        #nAsciiSVG.updatePicture(inputArea.getValue(), $("#target_canvas")[0],'canvas')
    catch err
        window.err = err
        # see if it is an error that we can highlight
        # in the code.
        # FIXME: This is a hack, since we assume any error
        # thrown with an appropriate line number is actually an error
        # generated by the user's code...we should do something more robust here.
        if err.lineNumber? and err.lineNumber <= inputArea.lineCount()
            CodeError.mark(err)
        else
            throw err
            
    $("#target").append("<asciisvg>" + inputArea.getValue() + "</asciisvg>")


###
# Saves the graph currently in the preview area
###
saveGraph = (fileName, fileFormat) ->
    updateGraph()

    #
    # Do the local storage bit
    #

    # clone the object and unset its id
    # so that we can use it as an svg thumbnail
    cloned = $('#target').clone()
    htmlifiedSvg = $('<div></div>').append(cloned)
    svgText = htmlifiedSvg.html()

    # This may be bad, but reload the storage before a save so
    # we don't overwrite data that was saved from another tab...
    $.jStorage.reInit()
    savedGraphList = $.jStorage.get('savedgraphs') or {}
    
    graphData = new GraphData(svgText)
    graphData.onclick = loadGraphFromGraphData
    graphData.ondelete = deleteGraphFromGraphData
    thumbnail = graphData.createThumbnail()
    graphData.makeDeletable()
    hash = graphData.hash()
    # only add to local storage if the graph doesn't already exist there
    if not savedGraphList[hash]
        $('#history-gallery .gallery-container').append(thumbnail)

        # append the graph to the list kept in local storage
        savedGraphList[graphData.hash()] = graphData.toJSON()
        $.jStorage.set('savedgraphs', savedGraphList)
    # XXX: this is for debugging/grabbing json text to use in the example file
    window.lastSavedGraph = graphData.toJSON()

    #
    # Prompt to save to the harddrive
    #
    width = parseFloat($('#svg-preview').children().attr('width'))
    height = parseFloat($('#svg-preview').children().attr('height'))
    if fileFormat is 'svg'
        downloadManager = new DownloadManager(fileName, svgText, 'image/svg+xml')
    else if fileFormat is 'pdf'
        pdfDoc = new PDFDocument({size: [width, height]})
        nAsciiSVG.ctx.playbackTo(pdfDoc, 'pdf')
        pdfDoc.info['graphitCode'] = inputArea.getValue()
        pdfRaw = pdfDoc.output()
        window.pdfDoc = pdfDoc
        downloadManager = new DownloadManager(fileName, pdfRaw, 'application/pdf')
    else if fileFormat is 'png'
        canvas = $("<canvas width='#{width}' height='#{height}'></canvas>")[0]
        ctx = canvas.getContext('2d')
        nAsciiSVG.ctx.playbackTo(ctx, 'canvas')
        data = canvas.toDataURL('image/png')
        #window.open(data)
        data = atob(data.slice('data:image/png;base64,'.length))
        downloadManager = new DownloadManager(fileName, data, 'image/png')

    downloadManager.download()

# TODO: fix so it works in chromium/chrome...Right now we use an
# ugly hack since we cannot trigger a click event on <input type=file
# in chromium
loadGraph = ->
    if !navigator.userAgent.match('Chrome')
        # do some magic to pop open a file-request dialog
        fileInput = $('<input type="file" id="files" name="files[]" accept="image/svg+xml" />')
        fileInput.change (event) ->
            files = event.target.files
            FileHandler.handleFiles(files)
        fileInput.trigger('click')
    else
        # fallback 'cause we cannot trigger a click on a file input...
        dialog = $('''
            <div>
                <h3>Browse for the file you wish to upload</h3>
                <input type="file" id="files" name="files[]" accept="image/svg+xml" />
            </div>''')
        $(document.body).append(dialog)
        dialog.dialog({ height: 300, width: 500, modal: true })
        dialog.find('input').change (event) ->
            files = event.target.files
            FileHandler.handleFiles(files)
            dialog.remove()
            

resizeGraph = (dims) ->
    if not dims?.width or dims?.height
        dims =
            width: Math.max(1, parseInt($('#svg-stat-width').text(),10))
            height: Math.max(1, parseInt($('#svg-stat-height').text(),10))
    aspect = dims.width/dims.height
    $('#svg-stat-aspect').text(round(aspect,2))

    $('#svg-preview').children().attr({width: dims.width, height: dims.height})
    updateGraph()

#
# Set the preview and sourcecode window to the svg corresponding
# to svgText
#
setGraphFromSvg = (svgText) ->
    graphData = new GraphData(svgText)
    inputArea.setValue(graphData.javascriptText)
    $('#svg-stat-width').text(graphData.width)
    $('#svg-stat-height').text(graphData.height)
    $('#svg-preview').html(graphData.svgText)
    $('#svg-preview svg').attr({id: 'target', width: graphData.width, height: graphData.height})
    

#
# Load all the graphs that are saved in localstorage
#
initializeGraphHistory = ->
    thumnailList = $('#history-gallery .gallery-container')
    $.jStorage.reInit()
    savedGraphList = $.jStorage.get('savedgraphs') or {}
    thumnailList.empty()
    for key, graph of savedGraphList
        graph = GraphData.fromJSON(graph)
        graph.onclick = loadGraphFromGraphData
        graph.ondelete = deleteGraphFromGraphData

        thumbnail = graph.createThumbnail()
        graph.makeDeletable()

        thumnailList.append(thumbnail)
#
# Loads the graph given by graphData into the preview
#
loadGraphFromGraphData = (graphData) ->
    $('#svg-stat-width').text(graphData.width) if graphData.width
    $('#svg-stat-height').text(graphData.height) if graphData.height
    inputArea.setValue(graphData.javascriptText)

    resizeGraph()

historyLoadFromFile = ->
    loadGraph()

historyClearAll = ->
    $('#history-gallery .gallery-container').empty()

    $.jStorage.reInit()
    $.jStorage.set('savedgraphs', {})

#
# Removes the graph given by graphData from localstorage and
# deletes the thumbnail
#
deleteGraphFromGraphData = (graphData) ->
    if typeOf(graphData) is 'GraphData'
        hash = graphData.hash()
    else
        hash = graphData

    # First delete from localstorage
    $.jStorage.reInit()
    savedGraphList = $.jStorage.get('savedgraphs') or {}
    delete savedGraphList[hash]
    $.jStorage.set('savedgraphs', savedGraphList)

    # Now delete the thumbnail
    if graphData.thumbnail?
        graphData.thumbnail.remove()
    
FileHandler =
    decodeDataURI: (dataURI) ->
        content = dataURI.indexOf(",")
        meta = dataURI.substr(5, content).toLowerCase()
        data = decodeURIComponent(dataURI.substr(content + 1))
        data = atob(data)    if /;\s*base64\s*[;,]/.test(meta)
        data = decodeURIComponent(escape(data))    if /;\s*charset=[uU][tT][fF]-?8\s*[;,]/.test(meta)
        data
    
    handleFiles: (files) ->
        file = files[0]
        #document.getElementById("droplabel").innerHTML = "Processing " + file.name
        reader = new FileReader()
        reader.onprogress = FileHandler.handleReaderProgress
        reader.onloadend = FileHandler.handleReaderLoadEnd
        reader.readAsDataURL file
    
    handleReaderProgress: (evt) ->
        percentLoaded = (evt.loaded / evt.total) if evt.lengthComputable
    
    handleReaderLoadEnd: (evt) ->
        if evt.target.error
            throw new Error(evt.target.error + " Error Code: " + evt.target.error.code + " ")
            return
        data = FileHandler.decodeDataURI(evt.target.result)
        # process the data depending on the file format
        if data[0...4] is '%PDF'
            # [\s\S] is equivalent to . but it matches newlines aswell
            m = data.match(/\/graphitCode \(([\s\S]*?[^\\])\)/)
            if not m?
                throw new Error("Could not extract graphit code from PDF")
            # grab the match
            m = m[1]
            # replace all escaped parens with unescaped ones
            # as well as escaped backslashes
            code = m.replace(/\\\(/g, '(').replace(/\\\)/g, ')').replace(/\\\\/g,'\\')
            # look for the width and height
            m = data.match(/\/MediaBox [0 0 (\d+) (\d+)]/)
            if m?
                width = m[1]
                height = m[2]
            else
                width = 550
                height = 450
            resizeGraph({width:width, height:height})
            inputArea.setValue(code)
            updateGraph()
            return
        setGraphFromSvg data

    dragEnter: (evt) ->
        $('#dropcontainer').show()
        $('.tabs').hide()
        evt.stopPropagation()
        evt.preventDefault()
    dragExit: (evt) ->
        $('#dropcontainer').hide()
        $('#dropbox').removeClass('dropbox-hover')
        $('.tabs').show()
        if evt?
            evt.stopPropagation()
            evt.preventDefault()
    dragOver: (evt,b) ->
        if not evt?
            $('#dropbox').removeClass('dropbox-hover')
            return
        $('#dropbox').addClass('dropbox-hover')
        evt.stopPropagation()
        evt.preventDefault()
    drop: (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        files = evt.dataTransfer.files
        count = files.length
        FileHandler.handleFiles files if count > 0
        # fake the exit of a drag event...
        FileHandler.dragExit()

#
# Load all examples from examples/examples.json and
# put them in the Examples tab
#
loadExamples = (url='examples/examples.json') ->
    $.ajax
        url: url
        dataType: 'text'
        success: displayExamples

displayExamples = (examplesJSON) ->
    exampleList = $.parseJSON(examplesJSON)
    for graphJSON in exampleList
        graph = GraphData.fromJSON(graphJSON)
        graph.onclick = (data) ->
            # switch to the Graph tab and then load the graph
            $('.tabs').tabs('select', '#graph')
            loadGraphFromGraphData(data)
        thumbnail = graph.createThumbnail()
        $('#examples .gallery-container').append(thumbnail)
        



###
# interface utility functions
###

# rounds to the desired number of decimal places
round = (num, places) ->
    p = Math.pow(10, places)
    return Math.round(num*p)/p

# take text or a number and make sure it's valid
validateNumber = (txt, positive=true, integer=true, max=10e10, min=-10e10) ->
    ret = 0
    switch typeOf(txt)
        when 'number'
            ret = txt
        when 'string'
            ret = parseFloat(txt)
    # verify that the number is in range and isnt NaN
    if isNaN(ret)
        ret = 0
    if ret > max
        ret = max
    else if ret < min
        ret = min

    ret = Math.abs(ret) if positive
    ret = Math.round(ret) if integer
    return ret

makeEditable = (element, editFinishedCallback=(->return null)) ->
    element = $(element)
    previousValue = element.html()

    # set up a change event for contenteditable elements
    element.live 'focus', ->
        $this = $(this)
        $this.data 'before', $this.html()
        $this.data 'initial-text', $this.html()
        return $this
    element.live 'blur keyup paste', ->
        $this = $(this)
        if $this.data('before') isnt $this.html()
            $this.data 'before', $this.html()
            $this.trigger('change')
        return $this

    # on enter or esc we are done editing
    element.keydown (event) ->
        $this = $(this)
        # we pressed enter
        if event.which is 13
            $(this).blur()
            event.stopPropagation()
        # we pressed escape
        if event.which is 27
            $this.html($this.data('initial-text'))
            $this.blur()
            event.stopPropagation()

    # on blur, validate 
    element.blur (event) ->
        $this = $(this)
        text = $this.text()
        num = validateNumber(text)
        # setting dims to 0 shouldn't be allowed
        if num is 0
            $this.html $this.data('initial-text')
        else
            $this.html(''+num)

        if $this.html() isnt previousValue
            previousValue = $this.html()
            editFinishedCallback($this.html())

