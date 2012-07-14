// Interprobility layer so that a canvas context can be used just like
// a pdf context in jsPDF

function CanvasPdf() {
    this._init.apply(this, arguments);
}

CanvasPdf.prototype = {
    _init: function(canvasContext) {
        this.ctx = canvasContext;
    },

    line: function(x1, y1, x2, y2) {
        this.ctx.beginPath();
        this.ctx.moveTo(x1, y1);
        this.ctx.lineTo(x1, y2);
        this.ctx.stroke();
    },

    // TODO: make fillStyle do something
    circle: function(x, y, radius, fillStyle) {
        // if fillStyle === 'F' we should do a solid circle
        this.ctx.beginPath();
        this.ctx.arc(x, y, radius, 0, Math.PI*2);
        this.ctx.fill();
    },

    text: function(x, y, text) {
        this.ctx.fillText(text, x, y);
    }
}

