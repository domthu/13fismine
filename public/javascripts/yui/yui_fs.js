//(function() {
var yuiDom = null; //YAHOO.util.Dom;
    //yuiEvent = YAHOO.util.Event;
//})();

function init_yui_editor_fs(id_textarea, _myconfig) {
//  yuiEvent.observe(window, 'load', load_yui_editor_fs(id_textarea, _myconfig));
//}
//function load_yui_editor_fs(id_textarea, _myconfig) {

  if (yuiDom == null) {
    yuiDom = YAHOO.util.Dom;
  }

    var myEditor = new YAHOO.widget.Editor(id_textarea, _myconfig);
    myEditor.on('toolbarLoaded', function() {
        var codeConfig = {
            type: 'push', label: 'Edit HTML Code', value: 'editcode'
        };
        this.toolbar.addButtonToGroup(codeConfig, 'insertitem');

        this.toolbar.on('editcodeClick', function() {
            var ta = this.get('element'),
                iframe = this.get('iframe').get('element');

            var classes = iframe.className.split(" ");
            if(classes.indexOf("editor-hidden") > -1) {
            //if (state == 'on') {
                //state = 'off';
                this.toolbar.set('disabled', false);
                this.setEditorHTML(ta.value);
                if (!this.browser.ie) {
                    this._setDesignMode('on');
                }

                yuiDom.removeClass(iframe, 'editor-hidden');
                yuiDom.addClass(ta, 'editor-hidden');
                this.show();
                this._focusWindow();
            } else {
                //state = 'on';
                this.cleanHTML();
                yuiDom.addClass(iframe, 'editor-hidden');
                yuiDom.removeClass(ta, 'editor-hidden');
                this.toolbar.set('disabled', true);
                this.toolbar.getButtonByValue('editcode').set('disabled', false);
                this.toolbar.selectButton('editcode');
                this.dompath.innerHTML = 'Editing HTML Code';
                this.hide();
            }
            return false;
        }, this, true);

        this.on('cleanHTML', function(ev) {
            this.get('element').value = ev.html;
        }, this, true);

        this.on('afterRender', function() {
            var wrapper = this.get('editor_wrapper');
            wrapper.appendChild(this.get('element'));
            this.setStyle('width', '100%');
            this.setStyle('height', '100%');
            this.setStyle('visibility', '');
            this.setStyle('top', '');
            this.setStyle('left', '');
            this.setStyle('position', '');

            this.addClass('editor-hidden');
        }, this, true);
    }, myEditor, true);
    myEditor.render();

    //Set new hidden field for cleaned html
    //http://www.packtpub.com/article/yui-2-8-rich-text-editor
    //Event.on('form1', 'submit', function (ev) {
    //    var html = myEditor.getEditorHTML();
    //    html = myEditor.cleanHTML(html);
    //    if (html.search(/<strong/gi) > -1) {
    //        alert("Don't shout at me!");
    //        Event.stopEvent(ev);
    //    }
    //    this.msgBody.innerHTML = html;
    //});

    return myEditor;
}
