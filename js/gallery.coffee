###
#    Copyright (c) 2012 Jason Siefken
#
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
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
    # If we truely are a plain-old object type, handle this now
    if constructorName == 'Object'
        return 'object'
    return constructorName



###
# Stores all information about a particular graph.  Can be initialized
# with just the svg code.  Has methods to create a thumbnail of the
# graph for use in a gallery.
###
class GraphData
    onclick: null
    ondelete: null
    template: '''
		<div class='gallery-item' title='Click to load this graph'>
			<div class='gallery-thumbnail'></div>
			<div class='gallery-text-area'>
				<div class='gallery-text'>
					<div class='gallery-description'>
					<span class='label'>Description:</span>
					<span class='content'>
					This is a description of this image. It
					has lots of nice properties and so forth.
					You should really have a look!
					</span>
					</div>
					<div class='gallery-creation-date'>
					<span class='label'>Creation Date:</span>
					<span class='content'>
					July 4, 1992 at 10:23pm
					</span>
					</div>
				</div>
			</div>
			<div class='gallery-close-icon ui-state-default' title='Delete'>
			<span class='ui-icon ui-icon-close'></span>
			</div>
		</div>
              '''
    constructor: (@svgText, @description='', @creationDate = new Date()) ->
        try
            # encapsulate the svg into div tags so we can manipulate it using regular dom manipulation
            encapsulated = $('<div></div>').append(@svgText)
            encapsulatedSvg = encapsulated.find('svg')

            # extract the javascript code from the svg if its there
            @javascriptText = encapsulated.find('asciisvg').text()

            # get the dimensions and ensure our viewbox is correct so when we can scale
            @width =  Math.max(1, parseInt(encapsulatedSvg.attr('width'),10))
            @height =  Math.max(1, parseInt(encapsulatedSvg.attr('height'),10))
            
            # jquery lower-cases all attrs, so we have to do this one the old fashoned way
            encapsulatedSvg[0].setAttribute('viewBox', "0 0 #{@width} #{@height}")
            # set some other attrs so the svg can be displayed as a thumbnail properly
            # TODO: the clip attr should be set to viewBox somehow...
            encapsulatedSvg.attr({id: null, width: '100%', height: '100%'})

            @svgText = encapsulated.html()
        catch error
        
    createThumbnail: =>
        # create a thumbnail from @template
        # By default thumbnails should't have the delete button
        @thumbnail = $(@template)
        @thumbnail.click(=> @onclick?(this))
        @thumbnail.find('.gallery-thumbnail').html @svgText
        @thumbnail.find('.gallery-creation-date .content').html @creationDate.toLocaleDateString()
        @thumbnail.find('.gallery-description .content').html @description

        @thumbnail.find('.gallery-close-icon').css({display:'none'})

        return @thumbnail

    makeDeletable: =>
        deleteIcon = @thumbnail.find('.gallery-close-icon')
        deleteIcon.css({display:'block'})
        deleteIcon.button({icons: {primary: 'ui-icon-close'}, text: false})
        deleteIcon.click((event) =>
            @ondelete?(this)
            # we don't want a click and a delete event being triggered!
            event.stopPropagation()
        )

    toJSON: ->
        ret =
            svgText: @svgText
            javascriptText: @javascriptText
            name: @name
            creationDate: @creationDate.toJSON()
            width: @width
            height: @height
            description: @description
        
        return $.toJSON(ret)

    toString: ->
        return @.toJSON()

    # a hopefully unique hash that isn't too long for use in local storage
    hash: ->
        return hex_md5(@.toString())

    # return a new GraphData constructed from a stringified version of a GraphData object
    @fromJSON: (obj) ->
        if typeOf(obj) is 'string'
            obj = $.parseJSON(obj)

        ret = new GraphData
        ret.svgText = obj.svgText if obj.svgText?
        ret.javascriptText = obj.javascriptText if obj.javascriptText?
        ret.description = obj.description if obj.description?
        ret.creationDate = new Date(obj.creationDate) if obj.creationDate?
        ret.width = obj.width if obj.width?
        ret.height = obj.height if obj.height?

        return ret

