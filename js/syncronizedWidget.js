
// Keeps multiple input widgets' data syncronized between them
function SyncronizedWidget() {
    this._init.apply(this, arguments);
}
SyncronizedWidget.prototype = {
    // @divs = list of divs where syncronized widgets should be inserted
    _init: function(divs) {
        this.divs = $(divs);
        this.value = null;
    },

    // Add the widget code that should be cloned into each 
    // div. Currently accepts
    //  * <input type='text'>
    //  * <input type='check'>
    addContent: function(content) {
        this.syncronizedElms = [];

        $(this.divs).each(function(i, item) {
            var newElm = $(content).clone();
            // Make sure it has a unique ID
            if (newElm.attr('id') && i > 0) {
                newElm.attr('id', newElm.attr('id') + '-syncronizedCopy-' + i);
            }
            $(item).append(newElm);
            this.syncronizedElms.push(newElm);
            newElm.change(this.elmChanged.bind(this));
        }.bind(this));

        this.type = $(content).prop('tagName').toLowerCase();
        if (this.type === 'input') {
            this.type = this.type + '_' + $(content).attr('type').toLowerCase();
        }

        // After we have manipulated the dom, call an elmChanged event so
        // all data starts out syncronized
        this.elmChanged({ currentTarget: content });
    },

    elmChanged: function(evt) {
        if (this.type === 'input_text') {
            this.value = $(evt.currentTarget).val();
        }
        if (this.type === 'input_checkbox') {
            // make sure this.value is a boolean value
            this.value = !!$(evt.currentTarget).prop('checked');
        }
        if (this.type === 'select') {
            this.value = $(evt.currentTarget).find('option:selected').val();
        }
//        console.log(evt)
        this.updateElms(this.value);
    },

    updateElms: function(val) {
        $(this.syncronizedElms).each(function(i, item) {
            if (this.type === 'input_text') {
                $(item).attr('value', val);
            }
            if (this.type === 'input_checkbox') {
                $(item).attr('checked', val);
            }
            if (this.type === 'select') {
                $(item).find('option:[value="'+val+'"]').attr('selected', true);
            }
        }.bind(this));
    }
}
