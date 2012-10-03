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

###
# Class that uses esprima and escodegen
# to rewrite code. Specifically, it can
# add foo.lineNumber = <num> markers before
# each function call, and prefix function
# calls and variable assignments, e.g.
# bar() -> foo.bar()
# bar = 5 -> foo.bar = 5
###
class SourceModifier
    # encloses tree in a BlockStatement if it isn't a
    # BlockStatement already
    encloseInBlock = (tree) ->
            if tree.type is 'BlockStatement'
                return tree
            else
                newElm =
                    type: 'BlockStatement'
                    body: [tree]
                return newElm

    constructor: (@source) ->

    parse: (str=@source or '') ->
        @tree = esprima.parse(str, {loc: true})
        {@assignments, @calls, @blocks} = @walk(@tree)

    generateCode: ->
        if not @tree?
            throw new Error('You must run parse() before calling generateCode()')
        return escodegen.generate(@tree)

    # Any assignment listed in the array assign
    # will be prefixed with <val>.
    # prefixKeywords is an object whose keys are each keyword that should
    # be prefixed. If prefixKeywords is null, all assignments will be prefixed
    prefixAssignments: (val='foo', prefixKeywords=null, assign=@assignments) ->
        for a in assign
            if a.type is 'Identifier' and (prefixKeywords == null or a.name of prefixKeywords)
                newNode =
                    type: 'MemberExpression'
                    object:
                        type: 'Identifier'
                        name: val
                    property: a
                a.parent.left = newNode
        return

    # Any function call listed in the array calls
    # will be prefixed with <val>.
    prefixCalls: (val='foo', prefixKeywords=null, calls=@calls) ->
        for a in calls
            if a.type is 'Identifier' and (prefixKeywords == null or a.name of prefixKeywords)
                newNode =
                    type: 'MemberExpression'
                    object:
                        type: 'Identifier'
                        name: val
                    property: a
                a.parent.callee = newNode
        return

    # In every array block of code, before any
    # function call <val>.lineNumber = <line number>
    # will be inserted
    insertLineNumbers: (val='foo', blocks=@blocks) ->
        for b in blocks
            i = 0
            while b[i]?
                node = b[i]
                if node.type is 'ExpressionStatement' and node.expression.type is 'CallExpression'
                    node = node.expression
                    # create the line assignment node
                    newNode =
                        type: 'ExpressionStatement'
                        expression:
                            type: 'AssignmentExpression'
                            operator: '='
                            left:
                                type: 'MemberExpression'
                                object:
                                    type: 'Identifier'
                                    name: val
                                property:
                                    type: 'Identifier'
                                    name: 'lineNumber'
                            right:
                                type: 'Literal'
                                value: node.loc.start.line
                    b.splice(i,0,newNode)
                    i++
                i++
        return

    # Walk the syntax tree and collect any assignments or calls
    # to top-level functions
    walk: (tree, tracked={assignments:[], calls:[], blocks:[]}) ->
        if not tree?
            return

        if typeOf(tree) is 'array'
            for e in tree
                @walk(e, tracked)
        else
            # recurse upon each node in the syntax tree
            # and record any of them we are interested in
            # TODO make the list comprehensive
            switch tree.type
                when 'Program'
                    tracked['blocks'].push tree.body
                    @walk(tree.body, tracked)
                when 'BlockStatement'
                    @walk(tree.body, tracked)
                when 'ForStatement'
                    tree.body = encloseInBlock(tree.body)
                    tracked['blocks'].push tree.body.body
                    @walk(tree.body, tracked)
                    @walk(tree.init, tracked)
                    @walk(tree.test, tracked)
                    @walk(tree.update, tracked)
                when 'ForInStatement'
                    tree.body = encloseInBlock(tree.body)
                    tracked['blocks'].push tree.body.body
                    @walk(tree.body, tracked)
                    @walk(tree.left, tracked)
                    @walk(tree.right, tracked)
                when 'WhileStatement'
                    tree.body = encloseInBlock(tree.body)
                    tracked['blocks'].push tree.body.body
                    @walk(tree.body, tracked)
                    @walk(tree.test, tracked)
                when 'IfStatement'
                    tree.consequent = encloseInBlock(tree.consequent)
                    tracked['blocks'].push tree.consequent.body
                    @walk(tree.test, tracked)
                    @walk(tree.consequent, tracked)
                when 'TryStatement'
                    tree.block = encloseInBlock(tree.block)
                    tracked['blocks'].push tree.block.body
                    @walk(tree.block, tracked)
                    @walk(tree.finalizer, tracked)
                    @walk(tree.handlers, tracked)
                when 'CatchClause'
                    tree.body = encloseInBlock(tree.body)
                    tracked['blocks'].push tree.body.body
                    @walk(tree.body, tracked)
                when 'FunctionDeclaration', 'FunctionExpression'
                    tree.body = encloseInBlock(tree.body)
                    tracked['blocks'].push tree.body.body
                    @walk(tree.body, tracked)
                when 'UpdateExpression'
                    @walk(tree.argument,tracked)
                when 'BinaryExpression'
                    @walk(tree.left,tracked)
                    @walk(tree.right,tracked)
                when 'ExpressionStatement'
                    @walk(tree.expression, tracked)
                when 'CallExpression'
                    tree.callee.parent = tree
                    tracked['calls'].push tree.callee
                    @walk(tree.arguments, tracked)
                when 'AssignmentExpression'
                    tree.left.parent = tree
                    tracked['assignments'].push tree.left
                    @walk(tree.right, tracked)
        return tracked

###
# All the useful math functions
###
MathFunctions =
    random: Math.random
    tan: Math.tan
    min: Math.min
    PI: Math.PI
    sqrt: Math.sqrt
    E: Math.E
    SQRT1_2: Math.SQRT1_2
    ceil: Math.ceil
    atan2: Math.atan2
    cos: Math.cos
    LN2: Math.LN2
    LOG10E: Math.LOG10E
    exp: Math.exp
    round: (n, places) ->
        shift = Math.pow(10, places)
        return Math.round(n*shift) / shift
    atan: Math.atan
    max: Math.max
    pow: Math.pow
    LOG2E: Math.LOG2E
    log: Math.log
    LN10: Math.LN10
    floor: Math.floor
    SQRT2: Math.SQRT2
    asin: Math.asin
    acos: Math.acos
    sin: Math.sin
    abs: Math.abs
    cpi: "\u03C0"
    ctheta: "\u03B8"
    pi: Math.PI
    ln: Math.log
    e: Math.E
    sign: (x) ->
        (if x is 0 then 0 else ((if x < 0 then -1 else 1)))
    arcsin: Math.asin
    arccos: Math.acos
    arctan: Math.atan
    sinh: (x) ->
        (Math.exp(x) - Math.exp(-x)) / 2
    cosh: (x) ->
        (Math.exp(x) + Math.exp(-x)) / 2
    tanh: (x) ->
        (Math.exp(x) - Math.exp(-x)) / (Math.exp(x) + Math.exp(-x))
    arcsinh: (x) ->
        ln x + Math.sqrt(x * x + 1)
    arccosh: (x) ->
        ln x + Math.sqrt(x * x - 1)
    arctanh: (x) ->
        ln((1 + x) / (1 - x)) / 2
    sech: (x) ->
        1 / cosh(x)
    csch: (x) ->
        1 / sinh(x)
    coth: (x) ->
        1 / tanh(x)
    arcsech: (x) ->
        arccosh 1 / x
    arccsch: (x) ->
        arcsinh 1 / x
    arccoth: (x) ->
        arctanh 1 / x
    sec: (x) ->
        1 / Math.cos(x)
    csc: (x) ->
        1 / Math.sin(x)
    cot: (x) ->
        1 / Math.tan(x)
    arcsec: (x) ->
        arccos 1 / x
    arccsc: (x) ->
        arcsin 1 / x
    arccot: (x) ->
        arctan 1 / x

###
# The AsciiSVG object. When asciisvg
# code is evaled, it is first preparsed and any keyword belonging
# to the public api is prefixed so that it is actually an attribute
# access.  For example "plot(...)" would get turned
# into "api.plot(...)". This is a workaround since we can't define dynamic scope
# in javascript without using the With statement.  Note, all MathFunctions
# are added to the api
#
# In general, methods starting with _ are for device coordinates
###
class AsciiSVG
    # XXX super ugly hack to make sure all math functions are defined
    # and available via closure to any method call
    arr = []
    for item of MathFunctions
        arr.push "#{item} = MathFunctions.#{item}"
    eval "var #{arr.join(',')}"
    # end hack

    round = (n, places) ->
        shift = Math.pow(10, places)
        return Math.round(n*shift) / shift
    api = {}
    _toDeviceCoordinates: (p) ->
        return [p[0]*@_xunitlength + @_origin[0], api.height - p[1]*@_yunitlength - @_origin[1]]
    constants:
        xmin: {default: -5, type: 'number', description: ''}
        xmax: {default: 5, type: 'number', description: ''}
        ymin: {default: -5, type: 'number', description: ''}
        ymax: {default: 5, type: 'number', description: ''}
        border: {default: 0, type: 'number', description: ''}
        width: {default: null, type: 'number', description: ''}
        height: {default: null, type: 'number', description: ''}
        fontsize: {default: null, type: 'number', description: ''}
        fontfamily: {default: 'sans', type: 'string', description: ''}
        fontstyle: {default: 'normal', type: 'string', description: '', options: ['normal', 'italic']}
        fontweight: {default: 'normal', type: 'string', description: '', options: ['normal', 'bold']}
        fontfill: {default: 'black', type: 'color', description: ''}
        fontstroke: {default: 'none', type: 'color', description: ''}
        markersize: {default: 4, type: 'number', description: 'The size of an arrowhead'}
        marker: {default: null, type: 'number', description: '', options: ['arrow', 'dot', 'arrowdot']}
        stroke: {default: 'black', type: 'color', description: ''}
        strokewidth: {default: 1, type: 'number', description: ''}
        background: {default: 'white', type: 'color', description: ''}
        gridstroke: {default: '#aaaaaa', type: 'color', description: ''} #light-gray
        fill: {default: 'none', type: 'color', description: ''}
        axesstroke: {default: 'black', type: 'color', description: ''}
        ticklength: {default: 4, type: 'number', description: 'The length of the ticks that mark the units along the axes'}
        dotradius: {default: 4, type: 'number', description: ''}
    functions:
        initPicture: {}
        axes: {}
        plot: {}
        dot: {}
        line: {}
        text: {}
        setBorder: {description: 'Does nothing; exists for backwards compatibility'}
        rect: {}
        circle: {}
        path: {}
        slopefield: {}

    constructor: ->
        api = {}
        # populate the api with all the available asciisvg commands
        for item,val of @constants
            api[item] = val.default
        for item of @functions
            api[item] = @[item].bind(this)

    _xunitlength: 1
    _yunitlength: 1
    _origin: [0, 0]
    _resetDefaults: ->
        @_xunitlength = 1
        @_yunitlength = 1
        for item,val of @constants
            api[item] = val.default

    # returns the api object which stores all public
    # variables and functions
    getApi: ->
        return api

    updatePicture: (src=@src, target, renderMode='svg') ->
        @_resetDefaults()
        if typeOf(target) == 'string'
            target = document.getElementById(target)
        api.width = parseInt(target.getAttribute('width'))
        api.height = parseInt(target.getAttribute('height'))
        id = target.getAttribute('id')
        @ctx = new RecordableCanvas(api.width, api.height)

        @initPicture()
        array_raw = src
        array_raw = array_raw.replace(/plot\(\x20*([^\"f\[][^\n\r]+?)\,/g,"plot\(\"$1\",")
        array_raw = array_raw.replace(/plot\(\x20*([^\"f\[][^\n\r]+)\)/g,"plot(\"$1\")")
        array_raw = array_raw.replace(/([0-9])([a-zA-Z])/g,"$1*$2")
        array_raw = array_raw.replace(/\)([\(0-9a-zA-Z])/g,"\)*$1")

        # preprocess the array to prefix anything in our api
        # with api.<prop>, since you cannot dynamically set the scope in js without
        # using the With statement (which doesn't exist in coffeescript)
        source = new SourceModifier(array_raw)
        source.parse()
        source.prefixAssignments('api', api)
        source.prefixCalls('api', api)
        eval(source.generateCode())

        switch renderMode
            when 'canvas'
                canvas = $("<canvas width='"+api.width+"' height='"+api.height+"' id='"+id+"' />")[0]
                canvas_ctx = canvas.getContext('2d')
                @ctx.playbackTo(canvas_ctx, 'canvas')
                target.parentNode.replaceChild(canvas, target)
            when 'svg'
                svgCanvas = new SvgCanvas(api.width, api.height)
                @ctx.playbackTo(svgCanvas, 'svg')
                svgCanvas._root.setAttribute('id', id)
                target.parentNode.replaceChild(svgCanvas._root, target)
        return
    initPicture: (x_min, x_max, y_min=x_min, y_max=x_max) ->
        api.xmin = x_min if x_min?
        api.xmax = x_max if x_max?
        api.ymin = y_min if y_min?
        api.ymax = y_max if y_max?

        if api.xmin >= api.xmax or api.ymin >= api.ymax
            throw new Error("Dimensions [#{[api.xmin,api.xmax,api.ymin,api.ymax]}] are not valid")

        @_xunitlength = (api.width - 2 * api.border) / (api.xmax - api.xmin)
        @_yunitlength = (api.height - 2 * api.border) / (api.ymax - api.ymin)
        @_origin = [-api.xmin * @_xunitlength + api.border, -api.ymin * @_yunitlength + api.border]
        @ctx.width = api.width
        @ctx.height = api.height

        @_noaxes()
    # textanchor may be above, aboveleft, aboveright, left, right, below, belowleft, belowright
    text: (pos, str, textanchor='center', angle=0, padding=4) ->
        computed_fontsize = api.fontsize or constants.fontsize.default
        p = @_toDeviceCoordinates(pos)

        if angle != 0
            throw new Error('rotations not yet supported')
            @ctx.rotate(angle/(2*pi))

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

        @ctx.font = "#{api.fontstyle} #{api.fontweight} #{computed_fontsize}px #{api.fontfamily}"
        @ctx.fontFamily = api.fontfamily
        @ctx.fontSize = computed_fontsize
        @ctx.fontWeight = api.fontweight
        @ctx.fontStyle = api.fontstyle
        @ctx.fillStyle = api.fontfill
        @ctx.text(str, p[0]+padding_x, p[1]+padding_y, textanchor)

        return pos
    setBorder: ->
    axes: (dx, dy, labels, griddx, griddy, units) ->
        tickdx = if dx? then dx * @_xunitlength else @_xunitlength
        tickdy = if dy? then dy * @_yunitlength else @_yunitlength
        api.fontsize = api.fontsize or min(tickdx/2, tickdy/2, 16)

        # if we pass in griddx and nothing for griddy,
        # assume we want griddx=griddy
        if typeOf(griddx) is 'number' and griddy == undefined
            griddy = griddx

        # draw the grid
        if griddx? or griddy?
            @ctx.beginPath()
            @ctx.strokeStyle = api.gridstroke
            @ctx.lineWidth = 0.5
            @ctx.fillStyle = api.fill

            if griddx? and griddx > 0
                x = MathFunctions.ceil(api.xmin/griddx)*griddx # x-axis
                while x < api.xmax
                    p = @_toDeviceCoordinates([x,0])
                    @ctx.moveTo(p[0], 0)
                    @ctx.lineTo(p[0], api.height)
                    x += griddx
            if griddy? and griddy > 0
                y = MathFunctions.ceil(api.ymin/griddy)*griddy # x-axis
                while y < api.ymax
                    p = @_toDeviceCoordinates([0,y])
                    @ctx.moveTo(0, p[1])
                    @ctx.lineTo(api.width, p[1])
                    y += griddy
            @ctx.stroke()

        # draw the axes
        if dx? or dy?
            @ctx.beginPath()
            @ctx.strokeStyle = api.axesstroke
            @ctx.fillStyle = api.fill
            @ctx.lineWidth = 1

            p = @_toDeviceCoordinates([0,0])
            @ctx.moveTo(0, p[1])
            @ctx.lineTo(api.width, p[1])
            @ctx.moveTo(p[0], 0)
            @ctx.lineTo(p[0], api.height)
            if dx? and dx > 0
                x = MathFunctions.ceil(api.xmin/dx)*dx # x-axis
                while x < api.xmax
                    # don't put a marker at the origin
                    if x == 0
                        x += dx
                    p = @_toDeviceCoordinates([x,0])
                    @ctx.moveTo(p[0], p[1]-api.ticklength)
                    @ctx.lineTo(p[0], p[1]+api.ticklength)
                    x += dx
            if dy? and dy > 0
                y = MathFunctions.ceil(api.ymin/dy)*dy # y-axis
                while y < api.ymax
                    if y == 0
                        y += dy
                    p = @_toDeviceCoordinates([0,y])
                    @ctx.moveTo(p[0]-api.ticklength, p[1])
                    @ctx.lineTo(p[0]+api.ticklength, p[1])
                    y += dy
            @ctx.stroke()

        # labels
        if labels?
            xunits = yunits = ''

            labeldecimals_x = Math.floor(1.1 - Math.log(dx)) + 1
            labeldecimals_y = Math.floor(1.1 - Math.log(dy)) + 1
            # if the x-axis/y-axis is shown, put labels below/left, otherwise above/right
            padding = 2*api.ticklength/@_yunitlength
            labelposition_x = if (api.ymin > 0 or api.ymax < 0) then api.ymin + padding else -padding
            padding = 2*api.ticklength/@_xunitlength
            labelposition_y = if (api.xmin > 0 or api.xmax < 0) then api.xmin + padding else -padding
            labelplacement_x = if (api.ymin > 0 or api.ymax < 0) then 'above' else 'below'
            labelplacement_y = if (api.xmin > 0 or api.xmax < 0) then 'right' else 'left'

            x = Math.ceil(api.xmin/dx) * dx
            while x < api.xmax
                # don't label the origin
                if x == 0
                    x += dx
                @text([x,labelposition_x], "#{round(x,labeldecimals_x)}#{xunits}", labelplacement_x)
                x += dx
            y = Math.ceil(api.ymin/dy) * dy
            while y < api.ymax
                # don't label the origin
                if y == 0
                    y += dy
                @text([labelposition_y,y], "#{round(y,labeldecimals_y)}#{yunits}", labelplacement_y)
                y += dy
        return
    _noaxes: ->
        @ctx.fillStyle = api.background
        @ctx.fillRect(0, 0, api.width, api.height)
        return
    rect: (corner1, corner2) ->
        @_rect(@_toDeviceCoordinates(corner1), @_toDeviceCoordinates(corner2))
        return
    _rect: (corner1, corner2) ->
        @ctx.beginPath()
        @ctx.moveTo(corner1[0],corner1[1])
        @ctx.lineTo(corner1[0],corner2[1])
        @ctx.lineTo(corner2[0],corner2[1])
        @ctx.lineTo(corner2[0],corner1[1])
        @ctx.closePath()
        @ctx.fillStyle = api.fill
        @ctx.strokeStyle = api.stroke
        if api.fill? and api.fill != 'none'
            @ctx.fillAndStroke()
        else
            @ctx.stroke()
        return
    circle: (center, radius, filled=false) ->
        p = @_toDeviceCoordinates(center)
        radius = radius*@_xunitlength

        @ctx.beginPath()
        @ctx.lineWidth = api.strokewidth
        @ctx.strokeStyle = api.stroke
        @ctx.fillStyle = api.fill
        @ctx.circle(p[0], p[1], radius)
        if filled
            @ctx.fillAndStroke()
        else
            @ctx.stroke()
        return
    dot: (center, type, label, textanchor='below', angle) ->
        p = @_toDeviceCoordinates(center)
        @ctx.strokeStyle = api.stroke
        @ctx.lineWidth = api.strokewidth

        switch type
            when '+'
                @ctx.beginPath()
                @ctx.moveTo(p[0] - api.ticklength, p[1])
                @ctx.lineTo(p[0] + api.ticklength, p[1])
                @ctx.moveTo(p[0], p[1] - api.ticklength)
                @ctx.lineTo(p[0], p[1] + api.ticklength)
                @ctx.stroke()
            when '-'
                @ctx.beginPath()
                @ctx.moveTo(p[0] - api.ticklength, p[1])
                @ctx.lineTo(p[0] + api.ticklength, p[1])
                @ctx.stroke()
            when '|'
                @ctx.beginPath()
                @ctx.moveTo(p[0], p[1] - api.ticklength)
                @ctx.lineTo(p[0], p[1] + api.ticklength)
                @ctx.stroke()
            else
                # we don't want filling in this dot to affect how things are filled in general,
                # so save the state and restore it after drawing the dot
                prevFill = api.fill
                if type?.match('open')
                    api.fill = api.background
                else if type?.match('closed')
                    api.fill = api.stroke
                @circle(center, api.dotradius/@_xunitlength, true)
                api.fill = prevFill
        if label?
            @text(center, label, textanchor, angle, api.dotradius+1)
        return
    line: (start, end) ->
        @ctx.lineWidth = api.strokewidth
        @ctx.strokeStyle = api.stroke
        @_line(@_toDeviceCoordinates(start), @_toDeviceCoordinates(end))
        if api.marker in ['dot', 'arrowdot']
            @dot(start)
            @arrowhead(start,end) if api.marker is 'arrowdot'
            @dot(start)
        return
    _line: (start, end) ->
        @ctx.beginPath()
        @ctx.moveTo(start[0],start[1])
        @ctx.lineTo(end[0],end[1])
        @ctx.stroke()
        return
    path: (plist) ->
        p = @_toDeviceCoordinates(plist[0])

        @ctx.beginPath()
        @ctx.lineWidth = api.strokewidth
        @ctx.strokeStyle = api.stroke
        @ctx.fillStyle = api.fill
        @ctx.moveTo(p[0],p[1])

        for p in plist[1..]
            p = @_toDeviceCoordinates(p)
            @ctx.lineTo(p[0],p[1])
        @ctx.stroke()

        if api.marker in ['dot', 'arrowdot']
            for p in plist
                @dot(p)
        return
    plot: (func, x_min=api.xmin, x_max=api.xmax, samples=200) ->
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
            plotDiameter = Math.max(1e-6, api.ymax - api.ymin, api.xmax - api.xmin)
            return Math.min(Math.max(x, api.ymin - plotDiameter*100), api.ymax + plotDiameter*100)

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
        inc = Math.max(0.0000001, (x_max-x_min)/samples)
        for t in [x_min..x_max] by inc
            # svg and pdf don't know how to handle points that are too extreme,
            # so threshold our function values before we actually plot them
            p = [threshold(f(t)),threshold(g(t))]
            points.push p if isNaN(p[0]) == false and isNaN(p[1]) == false

        # when graphing a function, we ony want to plot
        # the pieces that are on screen, so split the graph up into its
        # connected components.
        inbounds = (p) ->
            if p[1] > api.ymin and p[1] < api.ymax and p[0] > api.xmin and p[0] < api.xmax
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
                @path(p)
        return
    slopefield: (func, dx=1, dy=1) ->
        g = func
        if typeOf(func) is 'string'
            eval("g = function(x,y){ return #{mathjs(func)} }")
        dz = sqrt(dx*dx+dy*dy)/4
        x_min = Math.ceil(api.xmin / dx) * dx
        y_min = Math.ceil(api.ymin / dy) * dy
        pointList = []

        for x in [x_min..api.xmax] by dx
            for y in [y_min..api.ymax] by dy
                gxy = g(x,y)
                if not isNaN(gxy)
                    if abs(gxy) == Infinity
                        u = 0
                        v = dz
                    else
                        u = dz / sqrt(1 + gxy*gxy)
                        v = gxy * u
                    if api.xmin <= x <= api.xmax and api.ymin <= y <= api.ymax
                        pointList.push [[x-u,y-v],[x+u,y+v]]
        for l in pointList
            @line(l[0],l[1])
        return
    arrowhead: (p, q, size=api.markersize) ->
        @_arrowhead(@_toDeviceCoordinates(p), @_toDeviceCoordinates(q), size)
    _arrowhead: (p, q, size) ->
        u = [p[0]-q[0], p[1]-q[1]]
        d = Math.sqrt(u[0]*u[0] + u[1]*u[1])
        if d > 1e-7
            u = [-u[0]/d, -u[1]/d]
            uperp = [-u[1], u[0]]
            @ctx.lineWidth = size
            @ctx.strokeStyle = api.stroke
            @ctx.fillStyle = api.stroke
            @ctx.beginPath()
            @ctx.moveTo(q[0]-15*u[0]-4*uperp[0], q[1]-15*u[1]-4*uperp[1])
            @ctx.lineTo(q[0]-3*u[0], q[1]-3*u[1])
            @ctx.lineTo(q[0]-15*u[0]+4*uperp[0], q[1]-15*u[1]+4*uperp[1])
            @ctx.closePath()
            @ctx.fillAndStroke()
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

# TODO: we should fix interface.coffee to keep its own instance of AsciiSVG,
# but for now, let's just emulate the old behavior
window.nAsciiSVG = new AsciiSVG
