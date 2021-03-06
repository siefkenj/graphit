// Generated by CoffeeScript 1.3.3
/*
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
*/

/*
# Smart typeof function that will recognize builtin types as well as objects
# that are instances of those types.
*/

var GraphData, typeOf,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

typeOf = window.typeOf || function(obj) {
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
# Stores all information about a particular graph.  Can be initialized
# with just the svg code.  Has methods to create a thumbnail of the
# graph for use in a gallery.
*/


GraphData = (function() {

  GraphData.prototype.onclick = null;

  GraphData.prototype.ondelete = null;

  GraphData.prototype.template = '<div class=\'gallery-item\' title=\'Click to load this graph\'>\n	<div class=\'gallery-thumbnail\'></div>\n	<div class=\'gallery-text-area\'>\n		<div class=\'gallery-text\'>\n			<div class=\'gallery-description\'>\n			<span class=\'label\'>Description:</span>\n			<span class=\'content\'>\n			This is a description of this image. It\n			has lots of nice properties and so forth.\n			You should really have a look!\n			</span>\n			</div>\n			<div class=\'gallery-creation-date\'>\n			<span class=\'label\'>Creation Date:</span>\n			<span class=\'content\'>\n			July 4, 1992 at 10:23pm\n			</span>\n			</div>\n		</div>\n	</div>\n	<div class=\'gallery-close-icon ui-state-default\' title=\'Delete\'>\n	<span class=\'ui-icon ui-icon-close\'></span>\n	</div>\n</div>';

  function GraphData(svgText, description, creationDate) {
    var encapsulated, encapsulatedSvg;
    this.svgText = svgText;
    this.description = description != null ? description : '';
    this.creationDate = creationDate != null ? creationDate : new Date();
    this.makeDeletable = __bind(this.makeDeletable, this);

    this.createThumbnail = __bind(this.createThumbnail, this);

    try {
      encapsulated = $('<div></div>').append(this.svgText);
      encapsulatedSvg = encapsulated.find('svg');
      this.javascriptText = encapsulated.find('asciisvg').text();
      this.width = Math.max(1, parseInt(encapsulatedSvg.attr('width'), 10));
      this.height = Math.max(1, parseInt(encapsulatedSvg.attr('height'), 10));
      encapsulatedSvg[0].setAttribute('viewBox', "0 0 " + this.width + " " + this.height);
      encapsulatedSvg.attr({
        id: null,
        width: '100%',
        height: '100%'
      });
      this.svgText = encapsulated.html();
    } catch (error) {

    }
  }

  GraphData.prototype.createThumbnail = function() {
    var _this = this;
    this.thumbnail = $(this.template);
    this.thumbnail.click(function() {
      return typeof _this.onclick === "function" ? _this.onclick(_this) : void 0;
    });
    this.thumbnail.find('.gallery-thumbnail').html(this.svgText);
    this.thumbnail.find('.gallery-creation-date .content').html(this.creationDate.toLocaleDateString());
    this.thumbnail.find('.gallery-description .content').html(this.description);
    this.thumbnail.find('.gallery-close-icon').css({
      display: 'none'
    });
    return this.thumbnail;
  };

  GraphData.prototype.makeDeletable = function() {
    var deleteIcon,
      _this = this;
    deleteIcon = this.thumbnail.find('.gallery-close-icon');
    deleteIcon.css({
      display: 'block'
    });
    deleteIcon.button({
      icons: {
        primary: 'ui-icon-close'
      },
      text: false
    });
    return deleteIcon.click(function(event) {
      if (typeof _this.ondelete === "function") {
        _this.ondelete(_this);
      }
      return event.stopPropagation();
    });
  };

  GraphData.prototype.toJSON = function() {
    var ret;
    ret = {
      svgText: this.svgText,
      javascriptText: this.javascriptText,
      name: this.name,
      creationDate: this.creationDate.toJSON(),
      width: this.width,
      height: this.height,
      description: this.description
    };
    return $.toJSON(ret);
  };

  GraphData.prototype.toString = function() {
    return this.toJSON();
  };

  GraphData.prototype.hash = function() {
    return hex_md5(this.svgText);
  };

  GraphData.fromJSON = function(obj) {
    var ret;
    if (typeOf(obj) === 'string') {
      obj = $.parseJSON(obj);
    }
    ret = new GraphData;
    if (obj.svgText != null) {
      ret.svgText = obj.svgText;
    }
    if (obj.javascriptText != null) {
      ret.javascriptText = obj.javascriptText;
    }
    if (obj.description != null) {
      ret.description = obj.description;
    }
    if (obj.creationDate != null) {
      ret.creationDate = new Date(obj.creationDate);
    }
    if (obj.width != null) {
      ret.width = obj.width;
    }
    if (obj.height != null) {
      ret.height = obj.height;
    }
    return ret;
  };

  return GraphData;

})();
