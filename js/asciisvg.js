/* ASCIIsvg.js
==============
JavaScript routines to dynamically generate Scalable Vector Graphics
using a mathematical xy-coordinate system (y increases upwards) and
very intuitive JavaScript commands (no programming experience required).
ASCIIsvg.js is good for learning math and illustrating online math texts.
Works with Internet Explorer+Adobe SVGviewer and SVG enabled Mozilla/Firefox.

Version of Sept 12, 2009 (c) Peter Jipsen http://www.chapman.edu/~jipsen
Latest version at http://www.chapman.edu/~jipsen/svg/ASCIIsvg.js
If you use it on a webpage, please send the URL to jipsen@chapman.edu

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License (at http://www.gnu.org/copyleft/gpl.html) 
for more details.*/

/* encapulate everything in a function's scope.  The only command
 * we really need is updatePicture, so just give ourselves that */

AsciiSVG = (function(){
window.drawingCommands = [];

var currentLineNumber = -1;
var checkIfSVGavailable = true;
var notifyIfNoSVG = true;
var alertIfNoSVG = false;
var xunitlength = 20; // pixels
var yunitlength = 20; // pixels
var origin = [0, 0]; // in pixels (default is bottom left corner)
var defaultwidth = 300;
defaultheight = 200;
defaultborder = 0;
var border = defaultborder;
var strokewidth, strokedasharray, stroke, fill;
var fontstyle, fontfamily, fontsize, fontweight, fontstroke, fontfill;
var markerstrokewidth = "1";
var markerstroke = "black";
var markerfill = "yellow";
var markersize = 4;
var marker = "none";
var arrowfill = stroke;
var dotradius = 4;
var ticklength = 4;
var axesstroke = "black";
var gridstroke = "grey";
var above = "above";
var below = "below";
var left = "left";
var right = "right";
var aboveleft = "aboveleft";
var aboveright = "aboveright";
var belowleft = "belowleft";
var belowright = "belowright";
var cpi = "\u03C0",
    ctheta = "\u03B8";
var pi = Math.PI,
    ln = Math.log,
    e = Math.E;
var arcsin = Math.asin,
    arccos = Math.acos,
    arctan = Math.atan;
var sec = function (x) {
        return 1 / Math.cos(x)
    };
var csc = function (x) {
        return 1 / Math.sin(x)
    };
var cot = function (x) {
        return 1 / Math.tan(x)
    };
var xmin, xmax, ymin, ymax, xscl, yscl, xgrid, ygrid, xtick, ytick, initialized;
var isIE = document.createElementNS == null;
var picture, svgpicture, doc, width, height, a, b, c, d, i, n, p, t, x, y;
var arcsec = function (x) {
        return arccos(1 / x)
    };
var arccsc = function (x) {
        return arcsin(1 / x)
    };
var arccot = function (x) {
        return arctan(1 / x)
    };
var sinh = function (x) {
        return (Math.exp(x) - Math.exp(-x)) / 2
    };
var cosh = function (x) {
        return (Math.exp(x) + Math.exp(-x)) / 2
    };
var tanh = function (x) {
        return (Math.exp(x) - Math.exp(-x)) / (Math.exp(x) + Math.exp(-x))
    };
var sech = function (x) {
        return 1 / cosh(x)
    };
var csch = function (x) {
        return 1 / sinh(x)
    };
var coth = function (x) {
        return 1 / tanh(x)
    };
var arcsinh = function (x) {
        return ln(x + Math.sqrt(x * x + 1))
    };
var arccosh = function (x) {
        return ln(x + Math.sqrt(x * x - 1))
    };
var arctanh = function (x) {
        return ln((1 + x) / (1 - x)) / 2
    };
var sech = function (x) {
        return 1 / cosh(x)
    };
var csch = function (x) {
        return 1 / sinh(x)
    };
var coth = function (x) {
        return 1 / tanh(x)
    };
var arcsech = function (x) {
        return arccosh(1 / x)
    };
var arccsch = function (x) {
        return arcsinh(1 / x)
    };
var arccoth = function (x) {
        return arctanh(1 / x)
    };
var sign = function (x) {
        return (x == 0 ? 0 : (x < 0 ? -1 : 1))
    };

function factorial(x, n) {
    if (n == null) n = 1;
    for (var i = x - n; i > 0; i -= n) x *= i;
    return (x < 0 ? NaN : (x == 0 ? 1 : x));
}

function C(x, k) {
    var res = 1;
    for (var i = 0; i < k; i++) res *= (x - i) / (k - i);
    return res;
}

function chop(x, n) {
    if (n == null) n = 0;
    return Math.floor(x * Math.pow(10, n)) / Math.pow(10, n);
}

function ran(a, b, n) {
    if (n == null) n = 0;
    return chop((b + Math.pow(10, -n) - a) * Math.random() + a, n);
}

function myCreateElementXHTML(t) {
    if (isIE) return document.createElement(t);
    else return document.createElementNS("http://www.w3.org/1999/xhtml", t);
}

function less(x, y) {
    return x < y
} // used for scripts in XML files
// since IE does not handle CDATA well
function setText(st, id) {
    var node = document.getElementById(id);
    if (node != null) if (node.childNodes.length != 0) node.childNodes[0].nodeValue = st;
    else node.appendChild(document.createTextNode(st));
}

function myCreateElementSVG(t) {
    if (isIE) return doc.createElement(t);
    else return doc.createElementNS("http://www.w3.org/2000/svg", t);
}

// Evaluates a paragraph of javascript code, emitting an error on
// error with the linenumber of the associated error
function evalMath(src) {
    try {
        with(Math) {
            eval(src);
        }
    } catch (err) {
        throw err;
    }
    /*
    var lines = src.split('\n');
    var currentLineNumber = 0;
    var evalLineSize = 1;
    var currentError = null;
    while (lines.length > 0) {
        var evalLine = lines.unshift();
        try {
            with(Math) {
                eval(evalLine);
                // If we made it this far, the line evaluated properly
                currentLineNumber += evalLineSize;
                evalLineSize = 1;
                currentError = null;
                evalLine = null;
            }
        } catch (err) {
            // If we encountered a syntax error, add another line to the source code,
            // 'cause it might be a multi-line
            currentError = {lineNumber: currentLineNumber, sourceLine: evalLine};
            evalLine += lines.unshift();
            evalLineSize += 1;
        }
    }
    // If we made it this far and evalLine is set, we might not have tried executing it yet.
    if (evalLine) {
        try {
            with(Math) {
                eval(evalLine);
                currentError = null;
                evalLine = null;
            }
        } catch (err) {
            currentError = {lineNumber: currentLineNumber, sourceLine: evalLine};
        }
    }

    if (currentError) {
        throw currentError;
    }
    */
}

// cannot call the param picture, 'cause that's a global variable!
function switchTo(picture_xxx) {
    //alert(id);

    // We now pass the picture element directly in
//    picture = document.getElementById(id);
    picture = picture_xxx;
    width = picture.getAttribute("width") - 0;
    height = picture.getAttribute("height") - 0;
    strokewidth = "1" // pixel
    stroke = "black"; // default line color
    fill = "none"; // default fill color
    marker = "none";
    if ((picture.nodeName == "EMBED" || picture.nodeName == "embed") && isIE) {
        svgpicture = picture.getSVGDocument().getElementById("root");
        doc = picture.getSVGDocument();
    } else {
        svgpicture = picture;
        doc = document;
    }
    xunitlength = svgpicture.getAttribute("xunitlength") - 0;
    yunitlength = svgpicture.getAttribute("yunitlength") - 0;
    xmin = svgpicture.getAttribute("xmin") - 0;
    xmax = svgpicture.getAttribute("xmax") - 0;
    ymin = svgpicture.getAttribute("ymin") - 0;
    ymax = svgpicture.getAttribute("ymax") - 0;
    origin = [svgpicture.getAttribute("ox") - 0, svgpicture.getAttribute("oy") - 0];
}

function updatePicture(src, target) {
    //alert(typeof obj)

    // We now pass the source directly into updatePicture
//    var src = document.getElementById((typeof obj == "string" ? obj : "picture" + (obj + 1) + "input")).value;
    xmin = null;
    xmax = null;
    ymin = null;
    ymax = null;
    xscl = null;
    xgrid = null;
    yscl = null;
    ygrid = null;
    initialized = false;
    switchTo(target);
    src = src.replace(/plot\(\x20*([^\"f\[][^\n\r]+?)\,/g, "plot\(\"$1\",");
    src = src.replace(/plot\(\x20*([^\"f\[][^\n\r]+)\)/g, "plot(\"$1\")");
    src = src.replace(/([0-9])([a-zA-Z])/g, "$1*$2");
    src = src.replace(/\)([\(0-9a-zA-Z])/g, "\)*$1");

    evalMath(src);
}

function initPicture(x_min, x_max, y_min, y_max) {
    if (!initialized) {
        strokewidth = "1"; // pixel
        strokedasharray = null;
        stroke = "black"; // default line color
        fill = "none"; // default fill color
        //fontstyle = "italic"; // default shape for text labels
        fontstyle = "normal"; // default shape for text labels
        fontfamily = "sans"; // default font
        fontsize = "16"; // default size
        fontweight = "normal";
        fontstroke = "none"; // default font outline color
        fontfill = "none"; // default font color
        marker = "none";
        initialized = true;
        if (x_min != null) xmin = x_min;
        if (x_max != null) xmax = x_max;
        if (y_min != null) ymin = y_min;
        if (y_max != null) ymax = y_max;
        if (xmin == null) xmin = -5;
        if (xmax == null) xmax = 5;
        if (typeof xmin != "number" || typeof xmax != "number" || xmin >= xmax) {
            throw new Error("Picture requires at least two numbers: xmin < xmax");
        } else if (y_max != null 
                   && (typeof y_min != "number" || typeof y_max != "number" || y_min >= y_max)) {
            throw new Error("initPicture(xmin,xmax,ymin,ymax) requires numbers ymin < ymax");
        } else {
            if (width == null) width = picture.getAttribute("width");
            else picture.setAttribute("width", width);
            if (width == null || width == "") width = defaultwidth;
            if (height == null) height = picture.getAttribute("height");
            else picture.setAttribute("height", height);
            if (height == null || height == "") height = defaultheight;
            xunitlength = (width - 2 * border) / (xmax - xmin);
            yunitlength = xunitlength;
            if (ymin == null) {
                origin = [-xmin * xunitlength + border, height / 2];
                ymin = -(height - 2 * border) / (2 * yunitlength);
                ymax = -ymin;
            } else {
                if (ymax != null) yunitlength = (height - 2 * border) / (ymax - ymin);
                else ymax = (height - 2 * border) / yunitlength + ymin;
                origin = [-xmin * xunitlength + border, -ymin * yunitlength + border];
            }
            var qnode = myCreateElementSVG("svg");
            qnode.setAttribute("id", picture.getAttribute("id"));
            qnode.setAttribute("width", picture.getAttribute("width"));
            qnode.setAttribute("height", picture.getAttribute("height"));
            if (picture.parentNode != null) picture.parentNode.replaceChild(qnode, picture);
            else svgpicture.parentNode.replaceChild(qnode, svgpicture);
            svgpicture = qnode;
            doc = document;

            svgpicture.setAttribute("xunitlength", xunitlength);
            svgpicture.setAttribute("yunitlength", yunitlength);
            svgpicture.setAttribute("xmin", xmin);
            svgpicture.setAttribute("xmax", xmax);
            svgpicture.setAttribute("ymin", ymin);
            svgpicture.setAttribute("ymax", ymax);
            svgpicture.setAttribute("ox", origin[0]);
            svgpicture.setAttribute("oy", origin[1]);
            var node = myCreateElementSVG("rect");
            node.setAttribute("x", "0");
            node.setAttribute("y", "0");
            node.setAttribute("width", width);
            node.setAttribute("height", height);
            node.setAttribute("style", "stroke-width:1;fill:white");
            svgpicture.appendChild(node);
            border = defaultborder;
        }
    }
}

// included for backwards compatibility
function setBorder(){}

function line(p, q, id) { // segment connecting points p,q (coordinates in units)
    var node;
    if (id != null) node = doc.getElementById(id);
    if (node == null) {
        node = myCreateElementSVG("path");
        node.setAttribute("id", id);
        svgpicture.appendChild(node);
    }
    node.setAttribute("d", "M" + (p[0] * xunitlength + origin[0]) + "," + (height - p[1] * yunitlength - origin[1]) + "L" + (q[0] * xunitlength + origin[0]) + "," + (height - q[1] * yunitlength - origin[1]));
    node.setAttribute("stroke-width", strokewidth);
    if (strokedasharray != null) node.setAttribute("stroke-dasharray", strokedasharray);
    node.setAttribute("stroke", stroke);
    node.setAttribute("fill", fill);
    if (marker == "dot" || marker == "arrowdot") {
        ASdot(p, markersize, markerstroke, markerfill);
        if (marker == "arrowdot") arrowhead(p, q);
        ASdot(q, markersize, markerstroke, markerfill);
    } else if (marker == "arrow") arrowhead(p, q);
}

function path(plist, id, c) {
    if (c == null) c = "";
    var node, st, i;
    if (id != null) node = doc.getElementById(id);
    if (node == null) {
        node = myCreateElementSVG("path");
        node.setAttribute("id", id);
        svgpicture.appendChild(node);
    }
    if (typeof plist == "string") st = plist;
    else {
        st = "M";
        st += (plist[0][0] * xunitlength + origin[0]) + "," + (height - plist[0][1] * yunitlength - origin[1]) + "L" + c;
        for (i = 1; i < plist.length; i++)
        st += (plist[i][0] * xunitlength + origin[0]) + "," + (height - plist[i][1] * yunitlength - origin[1]) + "L";
    }
    node.setAttribute("d", st);
    node.setAttribute("stroke-width", strokewidth);
    if (strokedasharray != null) node.setAttribute("stroke-dasharray", strokedasharray);
    node.setAttribute("stroke", stroke);
    node.setAttribute("fill", fill);
    if (marker == "dot" || marker == "arrowdot") {
        for (i = 0; i < plist.length; i++) {
            if (c != "C" && c != "T" || i != 1 && i != 2) ASdot(plist[i], markersize, markerstroke, markerfill);
        }
    }

//    node.setAttribute('onclick', 'AsciiSVG.clickCallback('+currentLineNumber+')')
//    node.setAttribute('onmouseover', 'AsciiSVG.mouseoverCallback.call(this,'+currentLineNumber+')')
}

function curve(plist, id) {
    path(plist, id, "T");
}

function circle(center, radius, id) { // coordinates in units
    var node;
    if (id != null) node = doc.getElementById(id);
    if (node == null) {
        node = myCreateElementSVG("circle");
        node.setAttribute("id", id);
        svgpicture.appendChild(node);
    }
    node.setAttribute("cx", center[0] * xunitlength + origin[0]);
    node.setAttribute("cy", height - center[1] * yunitlength - origin[1]);
    node.setAttribute("r", radius * xunitlength);
    node.setAttribute("stroke-width", strokewidth);
    node.setAttribute("stroke", stroke);
    node.setAttribute("fill", fill);
}

function loop(p, d, id) {
    // d is a direction vector e.g. [1,0] means loop starts in that direction
    if (d == null) d = [1, 0];
    path([p, [p[0] + d[0], p[1] + d[1]],
        [p[0] - d[1], p[1] + d[0]], p], id, "C");
    if (marker == "arrow" || marker == "arrowdot") arrowhead([p[0] + Math.cos(1.4) * d[0] - Math.sin(1.4) * d[1], p[1] + Math.sin(1.4) * d[0] + Math.cos(1.4) * d[1]], p);
}

function arc(start, end, radius, id) { // coordinates in units
    var node, v;
    //alert([fill, stroke, origin, xunitlength, yunitlength, height])
    if (id != null) node = doc.getElementById(id);
    if (radius == null) {
        v = [end[0] - start[0], end[1] - start[1]];
        radius = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
    }
    if (node == null) {
        node = myCreateElementSVG("path");
        node.setAttribute("id", id);
        svgpicture.appendChild(node);
    }
    node.setAttribute("d", "M" + (start[0] * xunitlength + origin[0]) + "," + (height - start[1] * yunitlength - origin[1]) + " A" + radius * xunitlength + "," + radius * yunitlength + " 0 0,0 " + (end[0] * xunitlength + origin[0]) + "," + (height - end[1] * yunitlength - origin[1]));
    node.setAttribute("stroke-width", strokewidth);
    node.setAttribute("stroke", stroke);
    node.setAttribute("fill", fill);
    if (marker == "arrow" || marker == "arrowdot") {
        u = [(end[1] - start[1]) / 4, (start[0] - end[0]) / 4];
        v = [(end[0] - start[0]) / 2, (end[1] - start[1]) / 2];
        //alert([u,v])
        v = [start[0] + v[0] + u[0], start[1] + v[1] + u[1]];
    } else v = [start[0], start[1]];
    if (marker == "dot" || marker == "arrowdot") {
        ASdot(start, markersize, markerstroke, markerfill);
        if (marker == "arrowdot") arrowhead(v, end);
        ASdot(end, markersize, markerstroke, markerfill);
    } else if (marker == "arrow") arrowhead(v, end);
}

function ellipse(center, rx, ry, id) { // coordinates in units
    var node;
    if (id != null) node = doc.getElementById(id);
    if (node == null) {
        node = myCreateElementSVG("ellipse");
        node.setAttribute("id", id);
        svgpicture.appendChild(node);
    }
    node.setAttribute("cx", center[0] * xunitlength + origin[0]);
    node.setAttribute("cy", height - center[1] * yunitlength - origin[1]);
    node.setAttribute("rx", rx * xunitlength);
    node.setAttribute("ry", ry * yunitlength);
    node.setAttribute("stroke-width", strokewidth);
    node.setAttribute("stroke", stroke);
    node.setAttribute("fill", fill);
}

function rect(p, q, id, rx, ry) { // opposite corners in units, rounded by radii
    var node;
    if (id != null) node = doc.getElementById(id);
    if (node == null) {
        node = myCreateElementSVG("rect");
        node.setAttribute("id", id);
        svgpicture.appendChild(node);
    }
    node.setAttribute("x", p[0] * xunitlength + origin[0]);
    node.setAttribute("y", height - q[1] * yunitlength - origin[1]);
    node.setAttribute("width", (q[0] - p[0]) * xunitlength);
    node.setAttribute("height", (q[1] - p[1]) * yunitlength);
    if (rx != null) node.setAttribute("rx", rx * xunitlength);
    if (ry != null) node.setAttribute("ry", ry * yunitlength);
    node.setAttribute("stroke-width", strokewidth);
    node.setAttribute("stroke", stroke);
    node.setAttribute("fill", fill);
}

function text(p, st, pos, id, fontsty) {
    var textanchor = "middle";
    var dx = 0;
    var dy = fontsize / 3;
    if (pos != null) {
        if (pos.slice(0, 5) == "above") dy = -fontsize / 2;
        if (pos.slice(0, 5) == "below") dy = fontsize - 0;
        if (pos.slice(0, 5) == "right" || pos.slice(5, 10) == "right") {
            textanchor = "start";
            dx = fontsize / 2;
        }
        if (pos.slice(0, 4) == "left" || pos.slice(5, 9) == "left") {
            textanchor = "end";
            dx = -fontsize / 2;
        }
    }
    var node;
    if (id != null) node = doc.getElementById(id);
    if (node == null) {
        node = myCreateElementSVG("text");
        node.setAttribute("id", id);
        svgpicture.appendChild(node);
        node.appendChild(doc.createTextNode(st));
    }
    node.lastChild.nodeValue = st;
    node.setAttribute("x", p[0] * xunitlength + origin[0] + dx);
    node.setAttribute("y", height - p[1] * yunitlength - origin[1] + dy);
    node.setAttribute("font-style", (fontsty != null ? fontsty : fontstyle));
    node.setAttribute("font-family", fontfamily);
    node.setAttribute("font-size", fontsize);
    node.setAttribute("font-weight", fontweight);
    node.setAttribute("text-anchor", textanchor);
    if (fontstroke != "none") node.setAttribute("stroke", fontstroke);
    if (fontfill != "none") node.setAttribute("fill", fontfill);
    return p;
}

function ASdot(center, radius, s, f) { // coordinates in units, radius in pixel
    if (s == null) s = stroke;
    if (f == null) f = fill;
    var node = myCreateElementSVG("circle");
    node.setAttribute("cx", center[0] * xunitlength + origin[0]);
    node.setAttribute("cy", height - center[1] * yunitlength - origin[1]);
    node.setAttribute("r", radius);
    node.setAttribute("stroke-width", strokewidth);
    node.setAttribute("stroke", s);
    node.setAttribute("fill", f);
    svgpicture.appendChild(node);
}

function dot(center, typ, label, pos, id) {
    var node;
    var cx = center[0] * xunitlength + origin[0];
    var cy = height - center[1] * yunitlength - origin[1];
    if (id != null) node = doc.getElementById(id);
    if (typ == "+" || typ == "-" || typ == "|") {
        if (node == null) {
            node = myCreateElementSVG("path");
            node.setAttribute("id", id);
            svgpicture.appendChild(node);
        }
        if (typ == "+") {
            node.setAttribute("d", " M " + (cx - ticklength) + " " + cy + " L " + (cx + ticklength) + " " + cy + " M " + cx + " " + (cy - ticklength) + " L " + cx + " " + (cy + ticklength));
            node.setAttribute("stroke-width", .5);
            node.setAttribute("stroke", axesstroke);
        } else {
            if (typ == "-") node.setAttribute("d", " M " + (cx - ticklength) + " " + cy + " L " + (cx + ticklength) + " " + cy);
            else node.setAttribute("d", " M " + cx + " " + (cy - ticklength) + " L " + cx + " " + (cy + ticklength));
            node.setAttribute("stroke-width", strokewidth);
            node.setAttribute("stroke", stroke);
        }
    } else {
        if (node == null) {
            node = myCreateElementSVG("circle");
            node.setAttribute("id", id);
            svgpicture.appendChild(node);
        }
        node.setAttribute("cx", cx);
        node.setAttribute("cy", cy);
        node.setAttribute("r", dotradius);
        node.setAttribute("stroke-width", strokewidth);
        node.setAttribute("stroke", stroke);
        node.setAttribute("fill", (typ == "open" ? "white" : stroke));
    }
    if (label != null) text(center, label, (pos == null ? "below" : pos), (id == null ? id : id + "label"))
}

function arrowhead(p, q) { // draw arrowhead at q (in units)
    var up;
    var v = [p[0] * xunitlength + origin[0], height - p[1] * yunitlength - origin[1]];
    var w = [q[0] * xunitlength + origin[0], height - q[1] * yunitlength - origin[1]];
    var u = [w[0] - v[0], w[1] - v[1]];
    var d = Math.sqrt(u[0] * u[0] + u[1] * u[1]);
    if (d > 0.00000001) {
        u = [u[0] / d, u[1] / d];
        up = [-u[1], u[0]];
        var node = myCreateElementSVG("path");
        node.setAttribute("d", "M " + (w[0] - 15 * u[0] - 4 * up[0]) + "L" + (w[1] - 15 * u[1] - 4 * up[1]) + " L " + (w[0] - 3 * u[0]) + "L" + (w[1] - 3 * u[1]) + " L " + (w[0] - 15 * u[0] + 4 * up[0]) + "L" + (w[1] - 15 * u[1] + 4 * up[1]) + " z");
        node.setAttribute("stroke-width", markerstrokewidth);
        node.setAttribute("stroke", stroke); /*was markerstroke*/
        node.setAttribute("fill", stroke); /*was arrowfill*/
        svgpicture.appendChild(node);
    }
}

function chopZ(st) {
    var k = st.indexOf(".");
    if (k == -1) return st;
    for (var i = st.length - 1; i > k && st.charAt(i) == "0"; i--);
    if (i == k) i--;
    return st.slice(0, i + 1);
}

function grid(dx, dy) { // for backward compatibility
    axes(dx, dy, null, dx, dy)
}

function noaxes() {
    if (!initialized) initPicture();
}

function axes(dx, dy, labels, gdx, gdy) {
    //xscl=x is equivalent to xtick=x; xgrid=x; labels=true;
    var x, y, ldx, ldy, lx, ly, lxp, lyp, pnode, st;
    if (!initialized) initPicture();
    if (typeof dx == "string") {
        labels = dx;
        dx = null;
    }
    if (typeof dy == "string") {
        gdx = dy;
        dy = null;
    }
    if (xscl != null) {
        dx = xscl;
        gdx = xscl;
        labels = dx
    }
    if (yscl != null) {
        dy = yscl;
        gdy = yscl
    }
    if (xtick != null) {
        dx = xtick
    }
    if (ytick != null) {
        dy = ytick
    }
    //alert(null)
    dx = (dx == null ? xunitlength : dx * xunitlength);
    dy = (dy == null ? dx : dy * yunitlength);
    //fontsize = Math.min(dx / 2, dy / 2, 16); //alert(fontsize)
    // let's make the axis font a little bigger
    //fontsize = 20;
    ticklength = fontsize / 4;
    if (xgrid != null) gdx = xgrid;
    if (ygrid != null) gdy = ygrid;
    if (gdx != null) {
        gdx = (typeof gdx == "string" ? dx : gdx * xunitlength);
        gdy = (gdy == null ? dy : gdy * yunitlength);
        pnode = myCreateElementSVG("path");
        st = "";
        for (x = origin[0]; x < width; x = x + gdx) {
            st += " M" + x + ",0" + "L" + x + "," + height;
        }
        for (x = origin[0] - gdx; x > 0; x = x - gdx) {
            st += " M" + x + ",0" + "L" + x + "," + height;
        }
        for (y = height - origin[1]; y < height; y = y + gdy) {
            st += " M0," + y + "L" + width + "," + y;
        }
        for (y = height - origin[1] - gdy; y > 0; y = y - gdy) {
            st += " M0," + y + "L" + width + "," + y;
        }
        pnode.setAttribute("d", st);
        pnode.setAttribute("stroke-width", .5);
        pnode.setAttribute("stroke", gridstroke);
        pnode.setAttribute("fill", fill);
        svgpicture.appendChild(pnode);
    }
    pnode = myCreateElementSVG("path");
    st = "M0," + (height - origin[1]) + "L" + width + "," + (height - origin[1]) + " M" + origin[0] + ",0 " + origin[0] + "," + height;
    for (x = origin[0] + dx; x < width; x = x + dx) {
        st += " M" + x + "," + (height - origin[1] + ticklength) + "L" + x + "," + (height - origin[1] - ticklength);
    }
    for (x = origin[0] - dx; x > 0; x = x - dx) {
        st += " M" + x + "," + (height - origin[1] + ticklength) + "L" + x + "," + (height - origin[1] - ticklength);
    }
    for (y = height - origin[1] + dy; y < height; y = y + dy) {
        st += " M" + (origin[0] + ticklength) + "," + y + "L" + (origin[0] - ticklength) + "," + y;
    }
    for (y = height - origin[1] - dy; y > 0; y = y - dy) {
        st += " M" + (origin[0] + ticklength) + "," + y + "L" + (origin[0] - ticklength) + "," + y;
    }
    if (labels != null) with(Math) {
        ldx = dx / xunitlength;
        ldy = dy / yunitlength;
        lx = (xmin > 0 || xmax < 0 ? xmin : 0);
        ly = (ymin > 0 || ymax < 0 ? ymin : 0);
        lxp = (ly == 0 ? "below" : "above");
        lyp = (lx == 0 ? "left" : "right");
        var ddx = floor(1.1 - log(ldx) / log(10)) + 1;
        var ddy = floor(1.1 - log(ldy) / log(10)) + 1;
        for (x = ldx; x <= xmax; x = x + ldx) {
            text([x, ly], chopZ(x.toFixed(ddx)), lxp);
        }
        for (x = -ldx; xmin <= x; x = x - ldx) {
            text([x, ly], chopZ(x.toFixed(ddx)), lxp);
        }
        for (y = ldy; y <= ymax; y = y + ldy) {
            text([lx, y], chopZ(y.toFixed(ddy)), lyp);
        }
        for (y = -ldy; ymin <= y; y = y - ldy) {
            text([lx, y], chopZ(y.toFixed(ddy)), lyp);
        }
    }
    pnode.setAttribute("d", st);
    pnode.setAttribute("stroke-width", .5);
    pnode.setAttribute("stroke", axesstroke);
    pnode.setAttribute("fill", fill);
    svgpicture.appendChild(pnode);
}

function mathjs(st) {
    //translate a math formula to js function notation
    // a^b --> pow(a,b)
    // na --> n*a
    // (...)d --> (...)*d
    // n! --> factorial(n)
    // sin^-1 --> arcsin etc.
    //while ^ in string, find term on left and right
    //slice and concat new formula string
    st = st.replace(/\s/g, "");
    if (st.indexOf("^-1") != -1) {
        st = st.replace(/sin\^-1/g, "arcsin");
        st = st.replace(/cos\^-1/g, "arccos");
        st = st.replace(/tan\^-1/g, "arctan");
        st = st.replace(/sec\^-1/g, "arcsec");
        st = st.replace(/csc\^-1/g, "arccsc");
        st = st.replace(/cot\^-1/g, "arccot");
        st = st.replace(/sinh\^-1/g, "arcsinh");
        st = st.replace(/cosh\^-1/g, "arccosh");
        st = st.replace(/tanh\^-1/g, "arctanh");
        st = st.replace(/sech\^-1/g, "arcsech");
        st = st.replace(/csch\^-1/g, "arccsch");
        st = st.replace(/coth\^-1/g, "arccoth");
    }
    st = st.replace(/^e$/g, "(E)");
    st = st.replace(/^e([^a-zA-Z])/g, "(E)$1");
    st = st.replace(/([^a-zA-Z])e([^a-zA-Z])/g, "$1(E)$2");
    st = st.replace(/([0-9])([\(a-zA-Z])/g, "$1*$2");
    st = st.replace(/\)([\(0-9a-zA-Z])/g, "\)*$1");
    var i, j, k, ch, nested;
    while ((i = st.indexOf("^")) != -1) {
        //find left argument
        if (i == 0) return "Error: missing argument";
        j = i - 1;
        ch = st.charAt(j);
        if (ch >= "0" && ch <= "9") { // look for (decimal) number
            j--;
            while (j >= 0 && (ch = st.charAt(j)) >= "0" && ch <= "9") j--;
            if (ch == ".") {
                j--;
                while (j >= 0 && (ch = st.charAt(j)) >= "0" && ch <= "9") j--;
            }
        } else if (ch == ")") { // look for matching opening bracket and function name
            nested = 1;
            j--;
            while (j >= 0 && nested > 0) {
                ch = st.charAt(j);
                if (ch == "(") nested--;
                else if (ch == ")") nested++;
                j--;
            }
            while (j >= 0 && (ch = st.charAt(j)) >= "a" && ch <= "z" || ch >= "A" && ch <= "Z")
            j--;
        } else if (ch >= "a" && ch <= "z" || ch >= "A" && ch <= "Z") { // look for variable
            j--;
            while (j >= 0 && (ch = st.charAt(j)) >= "a" && ch <= "z" || ch >= "A" && ch <= "Z")
            j--;
        } else {
            return "Error: incorrect syntax in " + st + " at position " + j;
        }
        //find right argument
        if (i == st.length - 1) {
            return "Error: missing argument";
        }
        k = i + 1;
        ch = st.charAt(k);
        if (ch >= "0" && ch <= "9" || ch == "-") { // look for signed (decimal) number
            k++;
            while (k < st.length && (ch = st.charAt(k)) >= "0" && ch <= "9") {
                k++;
            }
            if (ch == ".") {
                k++;
                while (k < st.length && (ch = st.charAt(k)) >= "0" && ch <= "9") {
                    k++;
                }
            }
        } else if (ch == "(") { // look for matching closing bracket and function name
            nested = 1;
            k++;
            while (k < st.length && nested > 0) {
                ch = st.charAt(k);
                if (ch == "(") nested++;
                else if (ch == ")") nested--;
                k++;
            }
        } else if (ch >= "a" && ch <= "z" || ch >= "A" && ch <= "Z") { // look for variable
            k++;
            while (k < st.length && (ch = st.charAt(k)) >= "a" && ch <= "z" || ch >= "A" && ch <= "Z") k++;
        } else {
            return "Error: incorrect syntax in " + st + " at position " + k;
        }
        st = st.slice(0, j + 1) + "pow(" + st.slice(j + 1, i) + "," + st.slice(i + 1, k) + ")" + st.slice(k);
    }
    while ((i = st.indexOf("!")) != -1) {
        //find left argument
        if (i == 0) return "Error: missing argument";
        j = i - 1;
        ch = st.charAt(j);
        if (ch >= "0" && ch <= "9") { // look for (decimal) number
            j--;
            while (j >= 0 && (ch = st.charAt(j)) >= "0" && ch <= "9") j--;
            if (ch == ".") {
                j--;
                while (j >= 0 && (ch = st.charAt(j)) >= "0" && ch <= "9") j--;
            }
        } else if (ch == ")") { // look for matching opening bracket and function name
            nested = 1;
            j--;
            while (j >= 0 && nested > 0) {
                ch = st.charAt(j);
                if (ch == "(") nested--;
                else if (ch == ")") nested++;
                j--;
            }
            while (j >= 0 && (ch = st.charAt(j)) >= "a" && ch <= "z" || ch >= "A" && ch <= "Z")
            j--;
        } else if (ch >= "a" && ch <= "z" || ch >= "A" && ch <= "Z") { // look for variable
            j--;
            while (j >= 0 && (ch = st.charAt(j)) >= "a" && ch <= "z" || ch >= "A" && ch <= "Z")
            j--;
        } else {
            return "Error: incorrect syntax in " + st + " at position " + j;
        }
        st = st.slice(0, j + 1) + "factorial(" + st.slice(j + 1, i) + ")" + st.slice(i + 1);
    }
    return st;
}

function plot(fun, x_min, x_max, points, id) {
    var pth = [];
    var f = function (x) {
            return x
        },
        g = fun;
    var name = null;
    if (typeof fun == "string") eval("g = function(x){ with(Math) return " + mathjs(fun) + " }");
    else if (typeof fun == "object") {
        eval("f = function(t){ with(Math) return " + mathjs(fun[0]) + " }");
        eval("g = function(t){ with(Math) return " + mathjs(fun[1]) + " }");
    }
    if (typeof x_min == "string") {
        name = x_min;
        x_min = xmin
    } else name = id;
    var min = (x_min == null ? xmin : x_min);
    var max = (x_max == null ? xmax : x_max);
    var inc = max - min - 0.000001 * (max - min);
    inc = (points == null ? inc / 200 : inc / points);
    var gt;

    // when graphing a function, stop plotting if the function
    // goes off the screen and make separate paths for each on-screen component
    var inbounds = function(p) {
        if (isNaN(p[1]) || Math.abs(p[1]) == "Infinity" || p[1] < ymin || p[1] > ymax) {
            return false;
        }
        return true;
    }
    var precomputed = [];
    for (var t = min; t <= max; t += inc) {
        precomputed.push([f(t),g(t)]);
    }

    var pth = [], p, pf, pb;
    var paths = [];
    var n = precomputed.length;
    for (var i = 0; i < n; i++) {
        p = precomputed[i];
        pf = precomputed[i+1];
        pb = precomputed[i-1];
        if (pf && inbounds(p) === false && inbounds(pf) === true) {
            paths.push(pth);
            pth = [];
            pth.push(p);
        } else if (pb && inbounds(p) === false && inbounds(pb) === true) {
            pth.push(p);
            paths.push(pth);
            pth = [];
        } else if (inbounds(p)) {
            pth.push(p);
        }
    }
    paths.push(pth);

    // draw each of our paths now
    for (var i = 0; i < paths.length; i++) {
        if (paths[i].length > 0) {
            path(paths[i], name);
        }
    }
    return p;
}

function slopefield(fun, dx, dy) {
    var g = fun;
    if (typeof fun == "string") eval("g = function(x,y){ with(Math) return " + mathjs(fun) + " }");
    var gxy, x, y, u, v, dz;
    if (dx == null) dx = 1;
    if (dy == null) dy = 1;
    dz = Math.sqrt(dx * dx + dy * dy) / 6;
    var x_min = Math.ceil(xmin / dx);
    var y_min = Math.ceil(ymin / dy);
    var pointList = []
    // generate all the line segments for our slopefeild
    for (x = x_min; x <= xmax; x += dx) {
        for (y = y_min; y <= ymax; y += dy) {
            gxy = g(x, y);
            if (!isNaN(gxy)) {
                if (Math.abs(gxy) == "Infinity") {
                    u = 0;
                    v = dz;
                } else {
                    u = dz / Math.sqrt(1 + gxy * gxy);
                    v = gxy * u;
                }
                pointList.push([x - u, y - v]);
                pointList.push([x + u, y + v]);
            }
        }
    }
    // Convert them directly into a path for efficiency.
    var pathStr = ''
    for (var i = 0; i < pointList.length; i += 2) {
        pathStr += 'M' + (pointList[i][0] * xunitlength + origin[0]) + ','
                       + (height - pointList[i][1] * yunitlength - origin[1]) + ' '
                       + (pointList[i+1][0] * xunitlength + origin[0]) + ','
                       + (height - pointList[i+1][1] * yunitlength - origin[1]) + '';
    }
    path(pathStr);
}

// return an object containing updatePicture, since that is all that is needed
return {
        updatePicture: updatePicture,  // function you should call
        'about': 'AsciiSVG.updatePicture(<source code>, <svg element to render to>);\nNode, all contents of the svg will be erased and re-rendered with this command',
        clickCallback: function(){},  // function that gets called every time an svg element is clicked
        mouseoverCallback: function(){}  // function that gets called every time an svg element is clicked
        };

})();
