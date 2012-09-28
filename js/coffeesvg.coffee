###
# Reimplimentation of the asciisvg api
#
# (c) Jason Siefken
# GPL 3
###

###
# Smart typeof function that will recognize builtin types as well as objects
# that are instances of those types.
###
typeOf = window.typeOf or (obj) ->
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
    # If we truely are a plain-old object type or our constructor
    # doesn't have a name, handle this now
    if constructorName == 'Object' or not constructorName?
        return 'object'
    return constructorName

###
# Acts like a canvas, but canvas commands are converted into svg commands
###
class SvgCanvas
    KAPPA = 4.0 * ((Math.sqrt(2) - 1.0) / 3.0) # This constant is used to approximate a symmetrical arc using a cubic
    createSvgNode = (tag) ->
        return document.createElementNS('http://www.w3.org/2000/svg', tag)

    constructor: (@width=550, @height=450) ->
        @_root = createSvgNode('svg')
        @_root.setAttribute("width", @width)
        @_root.setAttribute("height", @height)
        # when we save and restore states, we add a group so that the transformation/etc
        # gets applied to all the children.  This stores the currently active group
        @_currentGroup = @_root
        @_currentPath = ''
    moveTo: (x,y) ->
        @_currentPath += "M#{x},#{y} "
    lineTo: (x,y) ->
        @_currentPath += "L#{x},#{y} "
    bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) ->
        @_currentPath += "C#{cp1x},#{cp1y},#{cp2x},#{cp2y},#{x},#{y} "
    quadraticCurveTo: (cpx, cpy, x, y) ->
        @_currentPath += "Q#{cpx},#{cpy},#{x},#{y} "
    closePath: ->
        @_currentPath += "Z"
    beginPath: ->
        @_currentPath = ''
    text: (str, x, y, textanchor) ->
        @textBaseline = 'middle'
        @textAnchor = 'middle'
        if textanchor.match('left')
            @textAnchor = 'end'
        else if textanchor.match('right')
            @textAnchor = 'start'
        @textBaseline = 'middle'
        if textanchor.match('above')
            @textBaseline = 'bottom'
        else if textanchor.match('below')
            @textBaseline = 'top'

        # svg's alignment-baseline property doesn't seem to be handled consistently,
        # so we'll hard-compute it from the fontsize
        fontsize = parseFloat(@fontsize) or 16
        dy = -fontsize/4    # by default svg lets decenders hang below the baseline, so compensate so that svg will look the same as pdf and canvas backends
        switch @textBaseline
            when 'top'
                dy = fontsize
            when 'middle'
                dy = fontsize / 2

        node = createSvgNode("text")
        node.setAttribute("x", x)
        node.setAttribute("y", y + dy)
        node.setAttribute("fill", @fillStyle)
        node.setAttribute("font-family", @fontFamily) if @fontFamily
        node.setAttribute("font-weight", @fontWeight) if @fontWeight
        node.setAttribute("font-style", @fontStyle) if @fontStyle
        node.setAttribute("font-size", @fontSize) if @fontSize
        #node.setAttribute("alignment-baseline", @textBaseline)
        node.setAttribute("text-anchor", @textAnchor)
        node.appendChild(document.createTextNode(str))
        @_currentGroup.appendChild(node)
    stroke: ->
        node = createSvgNode("path")
        node.setAttribute("d", @_currentPath)
        # this needs to be set to prevent default filling
        node.setAttribute("fill", "none")
        node.setAttribute("stroke", @strokeStyle)
        node.setAttribute("stroke-width", @lineWidth)
        node.setAttribute("stroke-linejoin", @lineJoin) if @lineJoin
        node.setAttribute("stroke-linecap", @lineCap) if @lineCap
        @_currentGroup.appendChild(node)
    fill: ->
        node = createSvgNode("path")
        node.setAttribute("d", @_currentPath)
        node.setAttribute("fill", @fillStyle)
        @_currentGroup.appendChild(node)
    fillAndStroke: ->
        node = createSvgNode("path")
        node.setAttribute("d", @_currentPath)
        node.setAttribute("fill", @fillStyle)
        node.setAttribute("stroke", @strokeStyle)
        node.setAttribute("stroke-width", @lineWidth)
        node.setAttribute("stroke-linejoin", @lineJoin) if @lineJoin
        @_currentGroup.appendChild(node)
    fillRect: (x, y, w, h) ->
        node = createSvgNode("rect")
        node.setAttribute("x", x)
        node.setAttribute("y", y)
        node.setAttribute("width", w)
        node.setAttribute("height", h)
        node.setAttribute("fill", @fillStyle)
        @_currentGroup.appendChild(node)
    strokeRect: (x, y, w, h) ->
        node = createSvgNode("path")
        node.setAttribute("x", x)
        node.setAttribute("y", y)
        node.setAttribute("width", w)
        node.setAttribute("height", h)
        node.setAttribute("stroke", @strokeStyle)
        node.setAttribute("stroke-width", @lineWidth)
        @_currentGroup.appendChild(node)
    circle: (x, y, r) ->
        @ellipse(x, y, r)
    ellipse: (x, y, r1, r2 = r1) ->
        l1 = r1 * KAPPA
        l2 = r2 * KAPPA

        @moveTo x + r1, y
        @bezierCurveTo x + r1, y + l1, x + l2, y + r2, x, y + r2
        @bezierCurveTo x - l2, y + r2, x - r1, y + l1, x - r1, y
        @bezierCurveTo x - r1, y - l1, x - l2, y - r2, x, y - r2
        @bezierCurveTo x + l2, y - r2, x + r1, y - l1, x + r1, y
        @moveTo x, y
    scale: (x, y) ->
        node = createSvgNode('g')
        node.setAttribute("transform", "scale(#{x},#{y})")
        @_currentGroup.appendChild(node)
        @_currentGroup = node
    rotate: (angle) ->
        node = createSvgNode('g')
        node.setAttribute("transform", "rotate(#{angle})")
        @_currentGroup.appendChild(node)
        @_currentGroup = node
    translate: (x, y) ->
        node = createSvgNode('g')
        node.setAttribute("transform", "translate(#{x},#{y})")
        @_currentGroup.appendChild(node)
        @_currentGroup = node
    transform: (m11, m12, m21, m22, dx, dy) ->
        node = createSvgNode('g')
        node.setAttribute("transform", "matrix(#{m11},#{m22},#{m21},#{m22},#{dx},#{dy})")
        @_currentGroup.appendChild(node)
        @_currentGroup = node
    save: ->
        @_savedNode = @_currentGroup
    restore: ->
        @_currentGroup = @_savedNode


###
# Acts like a canvas context, but when issued a drawing
# command, it saves the operation and the state of lineWidth/etc...
# so that it can be replayed to an actual canvas context
###
class RecordableCanvas
    # make funcName a function that when called has its arguments and the current state recorded
    makeRecordable = (funcName, parent) ->
        parent[funcName] = (args...) ->
            state = {}
            for prop in parent._satefulVariables
                state[prop] = parent[prop]
            parent._issuedCommands.push {command: funcName, args: args, state: state}
            return

    # returns the things in object b which have different values than
    # those in object a
    objDiff = (a, b) ->
        ret = {}
        for prop of b
            if (a[prop] != b[prop]) or (b[prop] is undefined and a[prop] isnt undefined)
                ret[prop] = b[prop]
        return ret

    # returns a list of operations where
    # the state for each operation only contains the state variables that have
    # changed from the previous operation. This does not create a deep copy
    # of args
    filterStateChanges = (ops) ->
        ret = []
        if ops.length == 0
            return ret

        newCmd = {state:{}}
        cmd = ops[0]
        newCmd['command'] = cmd['command']
        newCmd['args'] = cmd['args']
        # initially add anything that is not undefined
        for assgn, val of cmd['state']
            if val?
                newCmd['state'][assgn] = val
        ret.push newCmd

        # now add everything that has changed
        for i in [1...ops.length]
            prevCmd = ops[i-1]
            cmd = ops[i]
            changedState = objDiff(prevCmd['state'], cmd['state'])
            newCmd = {state:{}}
            newCmd['command'] = cmd['command']
            newCmd['args'] = cmd['args']
            for assgn, val of changedState
                newCmd['state'][assgn] = val
            ret.push newCmd

        return ret

    constructor: (@width, @height) ->
        @_satefulVariables = ['lineWidth', 'lineCap', 'miterLimit', 'strokeStyle', 'fillStyle', 'textAlign', 'textBaseline', 'globalAlpha', 'font', 'fontFamily', 'fontSize', 'fontWeight', 'fontStyle']
        @_ctxCommands = ['scale', 'rotate', 'translate', 'transform', 'beginPath', 'closePath', 'fill', 'stroke', 'clip', 'moveTo', 'lineTo', 'quadraticCurveTo', 'bezierCurveTo', 'arcTo', 'arc', 'rect', 'text', 'strokeText', 'clearRect', 'fillRect', 'strokeRect', 'fillAndStroke', 'circle']
        # ensure that each command in the @_ctxCommands list will be recorded
        for cmd in @_ctxCommands
            makeRecordable(cmd, @)
        @_issuedCommands = []

    # Pass in a context ctx and a mode.  The recorded operations will be
    # called upon ctx in the order that they were called on RecordableCanvas
    playbackTo: (ctx, mode='string') ->
        switch mode.toLowerCase()
            when 'string'
                wrap = (s) ->
                    return if typeOf(s) is 'string' then "'#{s}'" else s
                ret = []
                for cmd in filterStateChanges(@_issuedCommands)
                    for assgn, val of cmd['state']
                        ret.push "ctx.#{assgn} = #{wrap(val)};"
                    ret.push "ctx.#{cmd['command']}(#{(wrap(s) for s in cmd['args']).join(', ')});"
                ret = ret.join('\n')
            when 'canvas'
                for cmd in filterStateChanges(@_issuedCommands)
                    for assgn, val of cmd['state']
                        ctx[assgn] = val
                    try
                        if cmd['command'] of @_playbackOverridesCanvas
                            @_playbackOverridesCanvas[cmd['command']].apply(ctx, cmd['args'])
                        else
                            ctx[cmd['command']].apply(ctx, cmd['args'])
                    catch e
                        console.log(e,cmd['command'],cmd['args'])
                ret = null
            when 'pdf'
                for cmd in filterStateChanges(@_issuedCommands)
                    try
                        # any of the assignments made need to be processed specially
                        @_playbackOverridesPdf._assignments.call(ctx, cmd['state'])

                        # playback all the commands issued giving priority to overrides
                        if cmd['command'] of @_playbackOverridesPdf
                            @_playbackOverridesPdf[cmd['command']].apply(ctx, cmd['args'])
                        else
                            ctx[cmd['command']].apply(ctx, cmd['args'])
                    catch e
                        console.log(e,cmd['command'],cmd['args'])
                ret = ctx
            when 'svg'
                for cmd in filterStateChanges(@_issuedCommands)
                    for assgn, val of cmd['state']
                        ctx[assgn] = val
                    try
                        if cmd['command'] of @_playbackOverridesSvg
                            @_playbackOverridesSvg[cmd['command']].apply(ctx, cmd['args'])
                        else
                            ctx[cmd['command']].apply(ctx, cmd['args'])
                    catch e
                        console.log(e,cmd['command'],cmd['args'])
                ret = ctx
            else
                throw new Error("Unknown mode #{mode}")
        return ret

    # any function listed in the overrides will be called instead of
    # the recorded command, but passed the same argument list.  This
    # allows for fine-tuning of playback based on the actual context
    # (such as fiddling with font metrics differently for pdfs and
    # canvas, etc.)
    _playbackOverridesCanvas:
        circle: (x, y, radius) ->
            this.arc(x, y, radius, 0, 2*Math.PI, false)
        fillAndStroke: ->
            this.fill()
            this.stroke()
        text: (str, x, y, textanchor) ->
            @textAlign = 'center'
            if textanchor.match('left')
                @textAlign = 'right'
            else if textanchor.match('right')
                @textAlign = 'left'
            @textBaseline = 'middle'
            if textanchor.match('above')
                @textBaseline = 'bottom'
            else if textanchor.match('below')
                @textBaseline = 'top'
            @fillText(str, x, y)
    _playbackOverridesPdf:
        # this isn't actually an override, but it processes a dictionary
        # of assignments and will call the appropriate pdf function for each one
        _assignments: (vars) ->
            # turn a font family, font weight, and font style into a font string
            # for the pdf builtin fonts
            getFontString = (family, weight, style) ->
                ret = 'Helvetica'
                family = family?.toLowerCase()
                weight = weight?.toLowerCase()
                style = style?.toLowerCase()
                style = 'italic' if style is 'oblique'
                switch family
                    when 'times', 'times new roman'
                        if weight is 'bold' and style is 'italic'
                            ret = 'Times-BoldItalic'
                        else if weight is 'bold'
                            ret = 'Times-Bold'
                        else if style is 'italic'
                            ret = 'Times-Italic'
                        else
                            ret = 'Times-Roman'
                    when 'courier', 'monospace'
                        if weight is 'bold' and style is 'italic'
                            ret = 'Courier-BoldOblique'
                        else if weight is 'bold'
                            ret = 'Courier-Bold'
                        else if style is 'italic'
                            ret = 'Courier-Oblique'
                        else
                            ret = 'Courier'
                    else
                        if weight is 'bold' and style is 'italic'
                            ret = 'Helvetica-BoldOblique'
                        else if weight is 'bold'
                            ret = 'Helvetica-Bold'
                        else if style is 'italic'
                            ret = 'Helvetica-Oblique'
                        else
                            ret = 'Helvetica'

            for assgn, val of vars
                switch assgn
                    when 'fillStyle'
                        if val == 'none'
                            val = 'white'
                        @fillColor(val)
                    when 'strokeStyle'
                        @strokeColor(val)
                    when 'lineWidth'
                        @lineWidth(parseFloat(val))
                    when 'fontSize'
                        @fontSize(parseFloat(val))
                    when 'fontFamily'
                        @desiredFontFamily = val
                        @font(getFontString(@desiredFontFamily, @desiredFontWeight, @desiredFontStyle))
                    when 'fontWeight'
                        @desiredFontWeight = val
                        @font(getFontString(@desiredFontFamily, @desiredFontWeight, @desiredFontStyle))
                    when 'fontStyle'
                        @desiredFontStyle = val
                        @font(getFontString(@desiredFontFamily, @desiredFontWeight, @desiredFontStyle))

        # pdfkit has a broken beginPath command.  It's also unneeded for pdfs
        # since a path is destroyed after a stroke or fill
        beginPath: ->
        fillRect: (x, y, w, h) ->
            this.moveTo(0, 0)
            this.lineTo(w, 0)
            this.lineTo(w, h)
            this.lineTo(0, h)
            this.closePath()
            this.fill()
        strokeRect: (x, y, w, h) ->
            this.moveTo(0, 0)
            this.lineTo(w, 0)
            this.lineTo(w, h)
            this.lineTo(0, h)
            this.closePath()
            this.stroke()
        text: (str, x, y, textanchor) ->
            textAlign = 'center'
            if textanchor.match('left')
                textAlign = 'right'
            else if textanchor.match('right')
                textAlign = 'left'
            textBaseline = 'middle'
            if textanchor.match('above')
                textBaseline = 'bottom'
            else if textanchor.match('below')
                textBaseline = 'top'

            # Set the font appropriately

            textHeight = @currentLineHeight()
            textWidth = @widthOfString(str)
            offset_x = 0
            offset_y = 0
            switch textAlign
                when 'right'
                    offset_x = -textWidth
                when 'center'
                    offset_x = -textWidth / 2
            switch textBaseline
                when 'bottom'
                    offset_y = -textHeight
                when 'middle'
                    offset_y = -textHeight / 2
            @text(str, x + offset_x, y + offset_y)
    _playbackOverridesSvg: {}


window.nAsciiSVG = (->
    ###
    # All the useful math functions
    ###
    random = Math.random
    tan = Math.tan
    min = Math.min
    PI = Math.PI
    sqrt = Math.sqrt
    E = Math.E
    SQRT1_2 = Math.SQRT1_2
    ceil = Math.ceil
    atan2 = Math.atan2
    cos = Math.cos
    LN2 = Math.LN2
    LOG10E = Math.LOG10E
    exp = Math.exp
    round = (n, places) ->
        shift = Math.pow(10, places)
        return Math.round(n*shift) / shift
    atan = Math.atan
    max = Math.max
    pow = Math.pow
    LOG2E = Math.LOG2E
    log = Math.log
    LN10 = Math.LN10
    floor = Math.floor
    SQRT2 = Math.SQRT2
    asin = Math.asin
    acos = Math.acos
    sin = Math.sin
    abs = Math.abs
    cpi = "\u03C0"
    ctheta = "\u03B8"
    pi = Math.PI
    ln = Math.log
    e = Math.E
    sign = (x) ->
        (if x is 0 then 0 else ((if x < 0 then -1 else 1)))
    arcsin = Math.asin
    arccos = Math.acos
    arctan = Math.atan
    sinh = (x) ->
        (Math.exp(x) - Math.exp(-x)) / 2
    cosh = (x) ->
        (Math.exp(x) + Math.exp(-x)) / 2
    tanh = (x) ->
        (Math.exp(x) - Math.exp(-x)) / (Math.exp(x) + Math.exp(-x))
    arcsinh = (x) ->
        ln x + Math.sqrt(x * x + 1)
    arccosh = (x) ->
        ln x + Math.sqrt(x * x - 1)
    arctanh = (x) ->
        ln((1 + x) / (1 - x)) / 2
    sech = (x) ->
        1 / cosh(x)
    csch = (x) ->
        1 / sinh(x)
    coth = (x) ->
        1 / tanh(x)
    arcsech = (x) ->
        arccosh 1 / x
    arccsch = (x) ->
        arcsinh 1 / x
    arccoth = (x) ->
        arctanh 1 / x
    sec = (x) ->
        1 / Math.cos(x)
    csc = (x) ->
        1 / Math.sin(x)
    cot = (x) ->
        1 / Math.tan(x)
    arcsec = (x) ->
        arccos 1 / x
    arccsc = (x) ->
        arcsin 1 / x
    arccot = (x) ->
        arctan 1 / x

    ctx = null

    # defaults
    xmin = -5
    xmax = 5
    ymin = -5
    ymax = 5
    border = 0
    xunitlength = yunitlength = 1
    origin = [0,0]
    width = null
    height = null
    fontsize = null
    fontfamily = 'sans'
    fontstyle = 'normal'
    fontweight = 'normal'
    fontfill = 'black'
    fontstroke = 'none'

    markersize = 4
    marker = null
    defaultfontsize = 16
    stroke = 'black'
    strokewidth = 1
    background = 'white'
    gridstroke = '#aaaaaa' #light-gray
    fill = 'none'
    axesstroke = 'black'
    ticklength = 4
    dotradius = 4

    resetDefaults = ->
        # defaults
        xmin = -5
        xmax = 5
        ymin = -5
        ymax = 5
        border = 0
        xunitlength = yunitlength = 1
        origin = [0,0]
        width = null
        height = null
        fontsize = null
        fontfamily = 'sans'
        fontstyle = 'normal'
        fontweight = 'normal'
        fontfill = 'black'
        fontstroke = 'none'

        markersize = 4
        marker = null
        defaultfontsize = 16
        stroke = 'black'
        strokewidth = 1
        gridstroke = '#aaaaaa'
        fill = 'yellow'
        axesstroke = 'black'
        ticklength = 4

    toDeviceCoordinates = (p) ->
        return [p[0]*xunitlength + origin[0], height - p[1]*yunitlength - origin[1]]

    updatePicture = (src, target, renderMode='svg') ->
        resetDefaults()
        if typeOf(target) == 'string'
            target = document.getElementById(target)
        width = parseInt(target.getAttribute('width'))
        height = parseInt(target.getAttribute('height'))
        id = target.getAttribute('id')
        ctx = new RecordableCanvas(width, height)

        initPicture()
        array_raw = src
        array_raw = array_raw.replace(/plot\(\x20*([^\"f\[][^\n\r]+?)\,/g,"plot\(\"$1\",")
        array_raw = array_raw.replace(/plot\(\x20*([^\"f\[][^\n\r]+)\)/g,"plot(\"$1\")")
        array_raw = array_raw.replace(/([0-9])([a-zA-Z])/g,"$1*$2")
        array_raw = array_raw.replace(/\)([\(0-9a-zA-Z])/g,"\)*$1")

        eval(array_raw)

        switch renderMode
            when 'canvas'
                canvas = $("<canvas width='"+width+"' height='"+height+"' id='"+id+"' />")[0]
                canvas_ctx = canvas.getContext('2d')
                ctx.playbackTo(canvas_ctx, 'canvas')
                target.parentNode.replaceChild(canvas, target)
            when 'svg'
                svgCanvas = new SvgCanvas(width, height)
                ctx.playbackTo(svgCanvas, 'svg')
                svgCanvas._root.setAttribute('id', id)
                target.parentNode.replaceChild(svgCanvas._root, target)
        return

    initPicture = (x_min, x_max, y_min=x_min, y_max=x_max) ->
        xmin = x_min if x_min?
        xmax = x_max if x_max?
        ymin = y_min if y_min?
        ymax = y_max if y_max?

        if xmin >= xmax or ymin >= ymax
            throw new Error("Dimensions [#{[xmin,xmax,ymin,ymax]}] are not valid")

        xunitlength = (width - 2 * border) / (xmax - xmin)
        yunitlength = (height - 2 * border) / (ymax - ymin)
        origin = [-xmin * xunitlength + border, -ymin * yunitlength + border]
        ctx.width = width
        ctx.height = height

        noaxes()

    # textanchor may be above, aboveleft, aboveright, left, right, below, belowleft, belowright
    text = (pos, str, textanchor='center', angle=0, padding=4) ->
        computed_fontsize = fontsize or defaultfontsize
        p = toDeviceCoordinates(pos)

        if angle != 0
            throw new Error('rotations not yet supported')
            ctx.rotate(angle/(2*pi))

        # if text is left/right/above/below we need to give it a little bit
        # of padding so we don't overlap with the coordinates we requested
        padding_x = 0
        padding_y = 0
        if textanchor.match('left')
            padding_x -= padding + 3 if padding > 0
        if textanchor.match('right')
            padding_x += padding + 3 if padding > 0
        if textanchor.match('above')
            padding_y -= padding
        if textanchor.match('below')
            padding_y += padding

        ctx.font = "#{fontstyle} #{fontweight} #{computed_fontsize}px #{fontfamily}"
        ctx.fontFamily = fontfamily
        ctx.fontSize = computed_fontsize
        ctx.fontWeight = fontweight
        ctx.fontStyle = fontstyle
        ctx.fillStyle = fontfill
        ctx.text(str, p[0]+padding_x, p[1]+padding_y, textanchor)

        return pos


    setBorder = (width, color) ->
        border = width if width?
        stroke = color if color?

    noaxes = ->
        ctx.fillStyle = background
        ctx.fillRect(0, 0, width, height)

    axes = (dx, dy, labels, griddx, griddy, units) ->
        tickdx = if dx? then dx * xunitlength else xunitlength
        tickdy = if dy? then dy * yunitlength else yunitlength
        fontsize = fontsize or min(tickdx/2, tickdy/2, 16)

        # if we pass in griddx and nothing for griddy,
        # assume we want griddx=griddy
        if typeOf(griddx) is 'number' and griddy == undefined
            griddy = griddx

        # draw the grid
        if griddx? or griddy?
            ctx.beginPath()
            ctx.strokeStyle = gridstroke
            ctx.lineWidth = 0.5
            ctx.fillStyle = fill

            if griddx? and griddx > 0
                x = ceil(xmin/griddx)*griddx # x-axis
                while x < xmax
                    p = toDeviceCoordinates([x,0])
                    ctx.moveTo(p[0], 0)
                    ctx.lineTo(p[0], height)
                    x += griddx
            if griddy? and griddy > 0
                y = ceil(ymin/griddy)*griddy # x-axis
                while y < ymax
                    p = toDeviceCoordinates([0,y])
                    ctx.moveTo(0, p[1])
                    ctx.lineTo(width, p[1])
                    y += griddy
            ctx.stroke()

        # draw the axes
        if dx? or dy?
            ctx.beginPath()
            ctx.strokeStyle = axesstroke
            ctx.fillStyle = fill
            ctx.lineWidth = 1

            p = toDeviceCoordinates([0,0])
            ctx.moveTo(0, p[1])
            ctx.lineTo(width, p[1])
            ctx.moveTo(p[0], 0)
            ctx.lineTo(p[0], height)
            if dx? and dx > 0
                x = ceil(xmin/dx)*dx # x-axis
                while x < xmax
                    # don't put a marker at the origin
                    if x == 0
                        x += dx
                    p = toDeviceCoordinates([x,0])
                    ctx.moveTo(p[0], p[1]-ticklength)
                    ctx.lineTo(p[0], p[1]+ticklength)
                    x += dx
            if dy? and dy > 0
                y = ceil(ymin/dy)*dy # y-axis
                while y < ymax
                    if y == 0
                        y += dy
                    p = toDeviceCoordinates([0,y])
                    ctx.moveTo(p[0]-ticklength, p[1])
                    ctx.lineTo(p[0]+ticklength, p[1])
                    y += dy
            ctx.stroke()

        # labels
        if labels?
            xunits = yunits = ''

            labeldecimals_x = floor(1.1 - log(dx)) + 1
            labeldecimals_y = floor(1.1 - log(dy)) + 1
            # if the x-axis/y-axis is shown, put labels below/left, otherwise above/right
            padding = 2*ticklength/yunitlength
            labelposition_x = if (ymin > 0 or ymax < 0) then ymin + padding else -padding
            padding = 2*ticklength/xunitlength
            labelposition_y = if (xmin > 0 or xmax < 0) then xmin + padding else -padding
            labelplacement_x = if (ymin > 0 or ymax < 0) then 'above' else 'below'
            labelplacement_y = if (xmin > 0 or xmax < 0) then 'right' else 'left'

            x = ceil(xmin/dx) * dx
            while x < xmax
                # don't label the origin
                if x == 0
                    x += dx
                text([x,labelposition_x], "#{round(x,labeldecimals_x)}#{xunits}", labelplacement_x)
                x += dx
            y = ceil(ymin/dy) * dy
            while y < ymax
                # don't label the origin
                if y == 0
                    y += dy
                text([labelposition_y,y], "#{round(y,labeldecimals_y)}#{yunits}", labelplacement_y)
                y += dy
        return

    rect = (corner1, corner2) ->
        corner1 = toDeviceCoordinates(corner1)
        corner2 = toDeviceCoordinates(corner2)
        ctx.beginPath()
        ctx.moveTo(corner1[0],corner1[1])
        ctx.lineTo(corner1[0],corner2[1])
        ctx.lineTo(corner2[0],corner2[1])
        ctx.lineTo(corner2[0],corner1[1])
        ctx.closePath()
        ctx.fillStyle = fill
        ctx.strokeStyle = stroke
        if fill? and fill != 'none'
            ctx.fillAndStroke()
        else
            ctx.stroke()

    circle = (center, radius, filled=false) ->
        p = toDeviceCoordinates(center)
        radius = radius*xunitlength

        ctx.beginPath()
        ctx.lineWidth = strokewidth
        ctx.strokeStyle = stroke
        ctx.fillStyle = fill
        ctx.circle(p[0], p[1], radius)
        if filled
            ctx.fillAndStroke()
        else
            ctx.stroke()
        return

    dot = (center, type, label, textanchor='below', angle) ->
        p = toDeviceCoordinates(center)
        ctx.strokeStyle = stroke
        ctx.lineWidth = strokewidth

        switch type
            when '+'
                ctx.beginPath()
                ctx.moveTo(p[0] - ticklength, p[1])
                ctx.lineTo(p[0] + ticklength, p[1])
                ctx.moveTo(p[0], p[1] - ticklength)
                ctx.lineTo(p[0], p[1] + ticklength)
                ctx.stroke()
            when '-'
                ctx.beginPath()
                ctx.moveTo(p[0] - ticklength, p[1])
                ctx.lineTo(p[0] + ticklength, p[1])
                ctx.stroke()
            when '|'
                ctx.beginPath()
                ctx.moveTo(p[0], p[1] - ticklength)
                ctx.lineTo(p[0], p[1] + ticklength)
                ctx.stroke()
            else
                # we don't want filling in this dot to affect how things are filled in general,
                # so save the state and restore it after drawing the dot
                prevFill = fill
                if type?.match('open')
                    fill = background
                else if type?.match('closed')
                    fill = stroke
                circle(center, dotradius/xunitlength, true)
                fill = prevFill
        if label?

            text(center, label, textanchor, angle, dotradius+1)

    #TODO fix
    arrowhead = (p, q, size=markersize) ->
        p = toDeviceCoordinates(p)
        q = toDeviceCoordinates(q)
        u = [p[0]-q[0], p[1]-q[1]]
        d = Math.sqrt(u[0]*u[0] + u[1]*u[1])
        if d > 1e-7
            u = [-u[0]/d, -u[1]/d]
            uperp = [-u[1], u[0]]
            ctx.lineWidth = size
            ctx.strokeStyle = stroke
            ctx.fillStyle = stroke
            ctx.beginPath()
            ctx.moveTo(q[0]-15*u[0]-4*uperp[0], q[1]-15*u[1]-4*uperp[1])
            ctx.lineTo(q[0]-3*u[0], q[1]-3*u[1])
            ctx.lineTo(q[0]-15*u[0]+4*uperp[0], q[1]-15*u[1]+4*uperp[1])
            ctx.closePath()
            ctx.fillAndStroke()
        return


    line = (p, q) ->
        u = toDeviceCoordinates(p)
        v = toDeviceCoordinates(q)

        ctx.beginPath()
        ctx.lineWidth = strokewidth
        ctx.strokeStyle = stroke
        ctx.fillStyle = fill
        ctx.moveTo(u[0], u[1])
        ctx.lineTo(v[0], v[1])
        ctx.stroke()
        if marker in ['dot', 'arrowdot']
            dot(p)
            arrowhead(p,q) if marker is 'arrowdot'
            dot(q)

    path = (plist) ->
        p = toDeviceCoordinates(plist[0])

        ctx.beginPath()
        ctx.lineWidth = strokewidth
        ctx.strokeStyle = stroke
        ctx.fillStyle = fill
        ctx.moveTo(p[0],p[1])

        for p in plist[1..]
            p = toDeviceCoordinates(p)
            ctx.lineTo(p[0],p[1])
        ctx.stroke()

        if marker in ['dot', 'arrowdot']
            for p in plist
                dot(p)
        return

    plot = (func, x_min=xmin, x_max=xmax, samples=200) ->
        toFunc = (func) ->
            switch typeOf(func)
                when 'string'
                    ret = null
                    eval("ret = function(x){ return #{mathjs(func)} }")
                when 'function'
                    ret = func
                else
                    throw new Error("Unknown function type '#{func}'")
            return ret

        # values that are too extreme relative to our plot we wan to
        # round down a bit
        threshold = (x) ->
            plotDiameter = max(1e-6, ymax - ymin, xmax - xmin)
            return min(max(x, ymin - plotDiameter*100), ymax + plotDiameter*100)

        f = (x) -> x
        g = null
        switch typeOf(func)
            when 'string', 'function'
                g = toFunc(func)
            when 'array'
                f = toFunc(func[0])
                g = toFunc(func[1])
            else
                throw new Error("Unknown function type '#{func}'")

        points = []
        inc = max(0.0000001, (x_max-x_min)/samples)
        for t in [x_min..x_max] by inc
            # svg and pdf don't know how to handle points that are too extreme,
            # so threshold our function values before we actually plot them
            p = [threshold(f(t)),threshold(g(t))]
            points.push p if isNaN(p[0]) == false and isNaN(p[1]) == false

        # when graphing a function, we ony want to plot
        # the pieces that are on screen, so split the graph up into its
        # connected components.
        inbounds = (p) ->
            if p[1] > ymin and p[1] < ymax and p[0] > xmin and p[0] < xmax
                return true
            return false
        paths = []
        workingPath = []
        for p,i in points
            pNext = points[i+1]
            pPrevious = points[i-1]
            pInBounds = inbounds(p)
            if pNext and pInBounds is false and inbounds(pNext) is true
                paths.push workingPath
                workingPath = []
                workingPath.push p
            else if pPrevious and pInBounds is false and inbounds(pPrevious) is true
                workingPath.push p
                paths.push workingPath
                workingPath = []
            else if pInBounds
                workingPath.push p
        paths.push workingPath

        for p in paths
            if p.length > 0
                path(p)
        return

    slopefield = (func, dx=1, dy=1) ->
        g = func
        if typeOf(func) is 'string'
            eval("g = function(x,y){ return #{mathjs(func)} }")
        dz = sqrt(dx*dx+dy*dy)/4
        x_min = ceil(xmin / dx) * dx
        y_min = ceil(ymin / dy) * dy
        pointList = []

        for x in [x_min..xmax] by dx
            for y in [y_min..ymax] by dy
                gxy = g(x,y)
                if not isNaN(gxy)
                    if abs(gxy) == Infinity
                        u = 0
                        v = dz
                    else
                        u = dz / sqrt(1 + gxy*gxy)
                        v = gxy * u
                    if xmin <= x <= xmax and ymin <= y <= ymax
                        pointList.push [[x-u,y-v],[x+u,y+v]]
        for l in pointList
            line(l[0],l[1])
        return


    mathjs = (st) ->
        # Working (from ASCIISVG) - remains uncleaned for javaSVG.
        st = st.replace(/\s/g, "")
        unless st.indexOf("^-1") is -1
            st = st.replace(/sin\^-1/g, "arcsin")
            st = st.replace(/cos\^-1/g, "arccos")
            st = st.replace(/tan\^-1/g, "arctan")
            st = st.replace(/sec\^-1/g, "arcsec")
            st = st.replace(/csc\^-1/g, "arccsc")
            st = st.replace(/cot\^-1/g, "arccot")
            st = st.replace(/sinh\^-1/g, "arcsinh")
            st = st.replace(/cosh\^-1/g, "arccosh")
            st = st.replace(/tanh\^-1/g, "arctanh")
            st = st.replace(/sech\^-1/g, "arcsech")
            st = st.replace(/csch\^-1/g, "arccsch")
            st = st.replace(/coth\^-1/g, "arccoth")
        st = st.replace(/^e$/g, "(E)")
        st = st.replace(/^e([^a-zA-Z])/g, "(E)$1")
        st = st.replace(/([^a-zA-Z])e([^a-zA-Z])/g, "$1(E)$2")
        st = st.replace(/([0-9])([\(a-zA-Z])/g, "$1*$2")
        st = st.replace(/\)([\(0-9a-zA-Z])/g, ")*$1")
        i = undefined
        j = undefined
        k = undefined
        ch = undefined
        nested = undefined
        until (i = st.indexOf("^")) is -1

            #find left argument
            throw new Error("missing argument for '^'")    if i is 0
            j = i - 1
            ch = st.charAt(j)
            if ch >= "0" and ch <= "9" # look for (decimal) number
                j--
                j--    while j >= 0 and (ch = st.charAt(j)) >= "0" and ch <= "9"
                if ch is "."
                    j--
                    j--    while j >= 0 and (ch = st.charAt(j)) >= "0" and ch <= "9"
            else if ch is ")" # look for matching opening bracket and function name
                nested = 1
                j--
                while j >= 0 and nested > 0
                    ch = st.charAt(j)
                    if ch is "("
                        nested--
                    else nested++    if ch is ")"
                    j--
                j--    while j >= 0 and (ch = st.charAt(j)) >= "a" and ch <= "z" or ch >= "A" and ch <= "Z"
            else if ch >= "a" and ch <= "z" or ch >= "A" and ch <= "Z" # look for variable
                j--
                j--    while j >= 0 and (ch = st.charAt(j)) >= "a" and ch <= "z" or ch >= "A" and ch <= "Z"
            else
                throw new Error("incorrect syntax in " + st + " at position " + j)

            #find right argument
            throw new Error("missing argument")    if i is st.length - 1
            k = i + 1
            ch = st.charAt(k)
            if ch >= "0" and ch <= "9" or ch is "-" # look for signed (decimal) number
                k++
                k++    while k < st.length and (ch = st.charAt(k)) >= "0" and ch <= "9"
                if ch is "."
                    k++
                    k++    while k < st.length and (ch = st.charAt(k)) >= "0" and ch <= "9"
            else if ch is "(" # look for matching closing bracket and function name
                nested = 1
                k++
                while k < st.length and nested > 0
                    ch = st.charAt(k)
                    if ch is "("
                        nested++
                    else nested--    if ch is ")"
                    k++
            else if ch >= "a" and ch <= "z" or ch >= "A" and ch <= "Z" # look for variable
                k++
                k++    while k < st.length and (ch = st.charAt(k)) >= "a" and ch <= "z" or ch >= "A" and ch <= "Z"
            else
                throw new Error("incorrect syntax in " + st + " at position " + k)
            st = st.slice(0, j + 1) + "pow(" + st.slice(j + 1, i) + "," + st.slice(i + 1, k) + ")" + st.slice(k)
        until (i = st.indexOf("!")) is -1

            #find left argument
            throw new Error("missing argument for '!'")    if i is 0
            j = i - 1
            ch = st.charAt(j)
            if ch >= "0" and ch <= "9" # look for (decimal) number
                j--
                j--    while j >= 0 and (ch = st.charAt(j)) >= "0" and ch <= "9"
                if ch is "."
                    j--
                    j--    while j >= 0 and (ch = st.charAt(j)) >= "0" and ch <= "9"
            else if ch is ")" # look for matching opening bracket and function name
                nested = 1
                j--
                while j >= 0 and nested > 0
                    ch = st.charAt(j)
                    if ch is "("
                        nested--
                    else nested++    if ch is ")"
                    j--
                j--    while j >= 0 and (ch = st.charAt(j)) >= "a" and ch <= "z" or ch >= "A" and ch <= "Z"
            else if ch >= "a" and ch <= "z" or ch >= "A" and ch <= "Z" # look for variable
                j--
                j--    while j >= 0 and (ch = st.charAt(j)) >= "a" and ch <= "z" or ch >= "A" and ch <= "Z"
            else
                throw new Error("incorrect syntax in " + st + " at position " + j)
            st = st.slice(0, j + 1) + "factorial(" + st.slice(j + 1, i) + ")" + st.slice(i + 1)
        return st


    return {updatePicture: updatePicture, initPicture: initPicture, ctx: (-> ctx), axes:axes, plot:plot}
)()
