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

round = (num, places) ->
    p = Math.pow(10, places)
    return Math.round(num*p)/p

###
# Make a div/span editable upon click
###

makeEditable = (element, editFinishedCallback=(->return null)) ->
    createEditbox = (parent) ->
        parent = $(parent)
        editbox = $('<input type="text"></input>')
        editbox.blur ->
            me = $(this)
            parent.text(me.val())
            me.hide()
            parent.show()
            editFinishedCallback()

        editbox.keyup (event) ->
            me = $(this)
            # we pressed enter, so stop editing
            if event.keyCode is 13
                parent.text(me.val())
                me.blur()
            # we pressed escape, so restore the original value and so stop editing
            if event.keyCode is 27
                me.val(parent.text())
                me.blur()
        
        return editbox

    element = $(element)
    $(element).click ->
        me = $(this)
        # look to see if an edit box was already created for this element.
        # If not create one and store it
        editbox = $.data(this, 'editbox')
        if not editbox?
            editbox = createEditbox(me)
            $.data(this, 'editbox', editbox)
        editbox.val(me.text())
        me.after(editbox)
        editbox.show()
        editbox.focus()
        editbox.select()
        me.hide()
        

# list of all current errors that are highlighted
highlightedErrors = []
# unhighlight the error if that line was edited
unhighlightErrors = (from, to, text, next) ->
    if not from?
        for e in highlightedErrors
            e.clear()
        highlightedErrors = []

$(document).ready ->
    # set up the drag and drop
    dropbox = document.getElementById("dropbox")
    dropbox.addEventListener("dragenter", dragEnter, false)
    dropbox.addEventListener("dragexit", dragExit, false)
    dropbox.addEventListener("dragover", dragOver, false)
    dropbox.addEventListener("drop", drop, false)


    $("#tabs").tabs()
    $(".button").button()
    $(".datepicker").datepicker()
    $("#files").change openFile


    $("#doGraph").click doGraph
    $("#downloadGraph").click downloadSVG
    $("#saveGraph").click( ->
        doGraph()
        saveGraph()
    )
    $("#gentwopoints").click genTwoPoints
    $("#genpointslope").click genPointSlope

    window.inputArea = CodeMirror.fromTextArea($("#picture1input")[0],
        indentWithTabs: true
        smartIndent: false # if we don't end our lines with semicolons, this will try to indent them if enabled
        mode: "text/javascript"
    )

    $('.svg-stat.editable').map(-> makeEditable(this, resizeSvg))

    # update the graph before before so the user doesnt have to press update to see anything
    resizeSvg()

    # load any graphs in local storage
    loadGraphs()
    $('#clearLocalStorage').click(->
        $.jStorage.deleteKey('savedgraphs')
        loadGraphs()
    )

resizeSvg = (dims) ->
    if not dims?.width or dims?.height
        dims =
            width: Math.max(1, parseInt($('#svg-stat-width').text(),10))
            height: Math.max(1, parseInt($('#svg-stat-height').text(),10))
    aspect = dims.width/dims.height
    $('#svg-stat-aspect').text(round(aspect,2))

    $('#target').attr({width: dims.width, height: dims.height})
    doGraph()


###
# load the graphs from local storage
###
loadGraphs = ->
    thumnailList = $('#thumbnails ul')
    $.jStorage.reInit()
    savedGraphList = $.jStorage.get('savedgraphs') or {}
    thumnailList.empty()
    for key, graph of savedGraphList
        graph = GraphData.fromJSON(graph)
        thumbnail = graph.createThumbnail(importSVG)
        graph.makeDeletableFromLocalStorage()
        thumnailList.append(thumbnail)
    

###
# save the graph to local storage
###
saveGraph = ->
    # clone the object and unset its id
    cloned = $('#target').clone()
    cloned.attr({id:null})
    width = parseInt(cloned.attr('width'), 10)
    height = parseInt(cloned.attr('height'), 10)
    cloned.attr({width: width/5, height:height/5})
    # jquery lower-cases all attrs, so we have to do this one the old fashoned way
    # set the viewbox so that things are scaled appropriately
    cloned[0].setAttribute('viewBox',"0 0 #{width} #{height}")

    # to get the text of the svg, we have to append it to an element
    # first since svg elements don't have an innerHtml...
    htmlifiedSvg = $('<div></div>').append(cloned)
    svgText = htmlifiedSvg.html()
    # use the code emdedded with the svg (which could theoretically 
    # be unrelated to the code currently in inputArea
    javascriptText = htmlifiedSvg.find('asciisvg').text()

    graphData = new GraphData(svgText, javascriptText)
    
    thumbnail = graphData.createThumbnail(importSVG)
    $('#thumbnails ul').append(thumbnail)
    graphData.makeDeletableFromLocalStorage()

    # append the graph to the list kept in local storage

    # This may be bad, but reload the storage before a save so
    # we don't overwrite data that was saved from another tab...
    $.jStorage.reInit()
    savedGraphList = $.jStorage.get('savedgraphs') or {}
    savedGraphList[graphData.hash()] = graphData
    $.jStorage.set('savedgraphs', savedGraphList)

###
# deletes a graph from local storage
#
# graph should be a GraphData.hash() string or a GraphData object
###
deleteGraph = (graph=this) ->
    if typeOf(graph) is 'GraphData'
        graph = graph.hash()
    console.log graph

    $.jStorage.reInit()
    savedGraphList = $.jStorage.get('savedgraphs') or {}
    delete savedGraphList[graph]
    $.jStorage.set('savedgraphs', savedGraphList)

doGraph = ->
    unhighlightErrors()
    try
        AsciiSVG.updatePicture inputArea.getValue(), $("#target")[0]
    catch err
        # see if it is an error that we can highlight
        # in the code
        if err.lineNumber?
            highlight = inputArea.markText({line: err.lineNumber, ch:0}, {line: err.lineNumber, ch:null}, 'code-error')
            highlightedErrors.push highlight
            alert("#{err}\nline number: #{err.lineNumber}\nline: #{err.sourceLine}")
        else
            throw err
            
    $("#target").append "<asciisvg>" + inputArea.getValue() + "</asciisvg>"

importSVG = (svgText) ->
    if typeOf(svgText) is 'GraphData'
        # if we are a GraphData object, get the actual text of the svg
        svgText = svgText.svgText
    svg = $(svgText)
    # if there is a viewbox defined, we want to use it to retrieve the original
    # dimensions of the svg from when it was created (since it is changed
    # when made into a thumbnail)
    viewBox = svg[0].getAttribute('viewBox')
    width = svg[0].getAttribute('width')
    height = svg[0].getAttribute('height')
    if viewBox?
        match = viewBox.match(/\d+ \d+ (\d+) (\d+)/)
        width = match?[1]
        height = match?[2]

    # place the svg where it should be with the right dimensions and give it
    # the id of 'target'
    svg.attr({width: width, height: height, id:'target'})
    $("#outputNode").html svg

    # if we have an embedded asciisvg command, grab it
    previousAsciisvgCommand = $("#outputNode svg asciisvg").text()
    inputArea.setValue previousAsciisvgCommand    if previousAsciisvgCommand

    # make sure our width and height properties are set correctly
    $('#svg-stat-width').text(width)
    $('#svg-stat-height').text(height)
    resizeSvg()

# Generate a line through the given points
genTwoPoints = ->
    text = $("#twopoints").val()
    match = text.match(/\((.*),(.*)\)\s*;\s*\((.*),(.*)\)/)
    return    unless match
    x1 = undefined
    y1 = undefined
    x2 = undefined
    y2 = undefined
    x1 = match[1]
    y1 = match[2]
    x2 = match[3]
    y2 = match[4]
    m = (y2 - y1) / (x2 - x1)
    outputEquation = "plot(\"" + m + "*(x-(" + x1 + "))+(" + y1 + ")\")\n"
    outputEquation += "dot([" + x1 + "," + y1 + "], \"closed\")\n"
    outputEquation += "dot([" + x2 + "," + y2 + "], \"closed\")\n"
    $("#genout").val outputEquation

# Generate a line through the given points
genPointSlope = ->
    text = $("#pointslope").val()
    match = text.match(/m=(.*)\s*;\s*\((.*),(.*)\)/)
    return    unless match
    m = undefined
    x1 = undefined
    y1 = undefined
    m = match[1]
    x1 = match[2]
    y1 = match[3]
    outputEquation = "plot(\"" + m + "*(x-(" + x1 + "))+(" + y1 + ")\")\n"
    outputEquation += "dot([" + x1 + "," + y1 + "], \"closed\")\n"
    $("#genout").val outputEquation

downloadSVG = ->
    $("#doGraph").click()
    saveGraph()
    document.location.href = "data:application/octet-stream;base64," + btoa($("#outputNode").html())

###
# Drag and drop stuff
###
decodeDataURI = (dataURI) ->
    content = dataURI.indexOf(",")
    meta = dataURI.substr(5, content).toLowerCase()
    data = decodeURIComponent(dataURI.substr(content + 1))
    data = atob(data)    if /;\s*base64\s*[;,]/.test(meta)
    data = decodeURIComponent(escape(data))    if /;\s*charset=[uU][tT][fF]-?8\s*[;,]/.test(meta)
    data

dragEnter = (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
dragExit = (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
dragOver = (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
drop = (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    files = evt.dataTransfer.files
    count = files.length
    handleFiles files    if count > 0
openFile = (evt) ->
    files = evt.target.files
    handleFiles files    if files.length > 0
handleFiles = (files) ->
    file = files[0]
    document.getElementById("droplabel").innerHTML = "Processing " + file.name
    reader = new FileReader()
    reader.onprogress = handleReaderProgress
    reader.onloadend = handleReaderLoadEnd
    reader.readAsDataURL file
handleReaderProgress = (evt) ->
    loaded = (evt.loaded / evt.total)    if evt.lengthComputable
handleReaderLoadEnd = (evt) ->
    if evt.target.error
        $("#errorCode").html evt.target.error + " Error Code: " + evt.target.error.code + " "
        $("#errorDialog").dialog "open"
        return
    data = decodeDataURI(evt.target.result)
    importSVG data


class GraphData
    constructor: (@svgText, @javascriptText='', @name=null) ->
        @creationDate = new Date()
    createThumbnail: (callback) =>
        @thumbnail = $('''<li class="button thumbnail">
                            <div class="thumbnail-svg"></div>
                            <div class="thumbnail-caption"></div>
                         </li>''')
        @thumbnail.click(=> callback(this))
        @thumbnail.find('.thumbnail-svg').html @svgText
        @thumbnail.find('.thumbnail-caption').html @creationDate.toLocaleDateString()
        @thumbnail.button()

        return @thumbnail

    makeDeletableFromLocalStorage: ->
        @deleteButton = $('<div class="thumbnail-delete-button">X</div>')
        @deleteButton.click(=>
            deleteGraph(@)
            @thumbnail.remove()
        )

        @thumbnail.prepend(@deleteButton)
        #@deleteButton.hide()
        #@thumbnail.hover( => @deleteButton.show() )

    toString: ->
        ret =
            svgText: @svgText
            javascriptText: @javascriptText
            name: @name
            creationDate: @creationDate.toJSON()
        
        return $.toJSON(ret)

    # a hopefully unique hash that isn't too long for use in local storage
    hash: ->
        return hex_md5(@.toString())

    # return a new GraphData constructed from a stringified version of a GraphData object
    @fromJSON: (obj) ->
        if typeOf(obj) is 'string'
            obj = $.fromJSON(obj)

        ret = new GraphData
        ret.svgText = obj.svgText if obj.svgText?
        ret.javascriptText = obj.javascriptText if obj.javascriptText?
        ret.name = obj.name if obj.name?
        ret.creationDate = new Date(obj.creationDate) if obj.creationDate?

        return ret

