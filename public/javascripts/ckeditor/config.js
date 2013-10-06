/*
 Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
 For licensing, see LICENSE.html or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function (config) {
    config.PreserveSessionOnFileBrowser = true;
    // Define changes to default configuration here. For example:
    config.language = 'it';
    // config.uiColor = '#AADC6E';

    //config.ContextMenu = ['Generic','Anchor','Flash','Select','Textarea','Checkbox','Radio','TextField','HiddenField','ImageButton','Button','BulletedList','NumberedList','Table','Form'] ;

    config.height = '400px';
    // config.width = '600px';
    config.skin = 'kama';

    //config.resize_enabled = false;
    //config.resize_maxHeight = 2000;
    //config.resize_maxWidth = 750;

    //config.startupFocus = true;
    config.filebrowserImageUploadUrl = '/ckeditor/create/image';
    config.filebrowserBrowseUrl = '/ckeditor/files' ;
    config.filebrowserUploadUrl = '/ckeditor/create/file';
    config.filebrowserImageBrowseUrl = '/ckeditor/images' ;

    // works only with en, ru, uk languages
    config.extraPlugins = "embed,attachment";
    config.toolbar = 'Full';

    config.toolbar_Full =
        [
            [ 'Source', 'Maximize', '-', 'Save', 'NewPage', 'DocProps', 'Preview', 'Print', '-', 'Templates' ],
            [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ],
            [ 'Find', 'Replace', '-', 'SelectAll', '-', 'SpellChecker', 'Scayt' ] ,
            '/',
            [ 'Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat' ] ,
            [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote', 'CreateDiv', '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock', '-', 'BidiLtr', 'BidiRtl' ],
            [ 'Link', 'Unlink', 'Anchor' ],
            [ 'Image', 'Flash', 'Table', 'HorizontalRule', 'Smiley', 'SpecialChar', 'PageBreak' ],
            '/',
            [ 'Styles', 'Format', 'Font', 'FontSize' ] ,
            [ 'TextColor', 'BGColor' ],
            [  'Preview', 'ShowBlocks' ]
        ];
    config.toolbar_Light =
        [
            [ 'Source',  'Maximize','Save', 'Preview', '-', 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ],
            [ 'SelectAll', '-', 'Scayt' ] ,
            [ 'Image', 'Flash', 'Table', 'HorizontalRule', 'SpecialChar', 'PageBreak' ] ,
            [ 'Link', 'Unlink', 'Anchor', '-'],
            '/',
            [ 'Format', 'Font', 'FontSize' ] ,
            [ 'Bold', 'Italic', 'Strike', 'TextColor', 'BGColor', 'RemoveFormat' ],
            [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote' ]

        ];
    config.toolbar_Basic =
        [
            [  'Source','Save', '-', 'Format', 'Font', 'FontSize', 'Bold', 'Italic', 'TextColor', 'BGColor', '-', 'RemoveFormat', '-', 'NumberedList', 'BulletedList', 'Table', '-', 'Link', 'Unlink']
        ];
};

