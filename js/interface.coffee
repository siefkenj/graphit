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

    $('.svg-stat.editable').map(-> makeEditable(this, resizeGraph))

    # set up the callbacks
    $('#update-graph').click updateGraph
    $('#save-graph').click saveGraph
    $('#load-graph').click loadGraph

    $('#history-load-from-file').click historyLoadFromFile
    $('#history-clear-all').click historyClearAll

    # set up the drag-and-drop
    $('#dropbox').hide()
    $('body')[0].addEventListener('dragenter', FileHandler.dragEnter, false)
    $('body')[0].addEventListener('dragexit', FileHandler.dragExit, false)
    $('#dropbox')[0].addEventListener('dragover', FileHandler.dragOver, false)
    $('body')[0].addEventListener('drop', FileHandler.drop, false)

    # initialize everything
    resizeGraph()
    initializeGraphHistory()
    loadExamples()


###
# Draw the current graph to #svg-preview
###
updateGraph = ->
    try
        AsciiSVG.updatePicture(inputArea.getValue(), $("#target")[0])
    catch err
        # see if it is an error that we can highlight
        # in the code
        if err.lineNumber?
#            highlight = inputArea.markText({line: err.lineNumber, ch:0}, {line: err.lineNumber, ch:null}, 'code-error')
#            highlightedErrors.push highlight
            alert("#{err}\nline number: #{err.lineNumber}\nline: #{err.sourceLine}")
        else
            throw err
            
    $("#target").append("<asciisvg>" + inputArea.getValue() + "</asciisvg>")

###
# Saves the graph currently in the preview area
###
saveGraph = ->
    updateGraph()

    #
    # Do the local storage bit
    #

    # clone the object and unset its id
    cloned = $('#target').clone()
    htmlifiedSvg = $('<div></div>').append(cloned)
    svgText = htmlifiedSvg.html()

    graphData = new GraphData(svgText)
    graphData.onclick = loadGraphFromGraphData
    graphData.ondelete = deleteGraphFromGraphData
    thumbnail = graphData.createThumbnail()
    graphData.makeDeletable()
    $('#history-gallery .gallery-container').append(thumbnail)

    # append the graph to the list kept in local storage

    # This may be bad, but reload the storage before a save so
    # we don't overwrite data that was saved from another tab...
    $.jStorage.reInit()
    savedGraphList = $.jStorage.get('savedgraphs') or {}
    savedGraphList[graphData.hash()] = graphData.toJSON()
    $.jStorage.set('savedgraphs', savedGraphList)
    # XXX: this is for debugging/grabbing json text to use in the example file
    window.lastSavedGraph = graphData.toJSON()

    #
    # Prompt to save to the harddrive
    #

    document.location.href = "data:application/octet-stream;base64," + btoa(svgText)

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

    $('#target').attr({width: dims.width, height: dims.height})
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
        setGraphFromSvg data

    dragEnter: (evt) ->
        $('#dropbox').show()
        $('.tabs').hide()
        evt.stopPropagation()
        evt.preventDefault()
    dragExit: (evt) ->
        $('#dropbox').hide()
        $('#dropbox').removeClass('dropbox-hover')
        $('.tabs').show()
        evt.stopPropagation()
        evt.preventDefault()
    dragOver: (evt,b) ->
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

