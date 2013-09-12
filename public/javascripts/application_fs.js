/*funzione aggiunta per il preview di paperclip */
// valori accettati 1= Immagine Avatar Papareclip , 0 = Immagine Gravatar , 2  = Nuova immagine upload
function funct_avatar(tipo, grav_id, radio_button_id) {
    grav_id = '#' + grav_id;
    radio_button_id = '#' + radio_button_id;
    if (tipo == 'g') {
        $(grav_id + '-a').hide();
        $(grav_id + '-g').show();
    }
    else if (tipo == 'a') {
        $(grav_id + '-a').show();
        $(grav_id + '-g').hide();
        $(radio_button_id).prop('checked', true);
    }
    else{
      //verificare parametro
    }

}
//avatar 'i'
//grav_id 'fs-photo-edit'
//radio_button_id 'use_gravatar_true'
function handleFileSelect_fs(evt, grav_id, radio_button_id) {
    grav_id = grav_id || 'fs-photo-edit';
    radio_button_id = radio_button_id || 'use_gravatar_false';
    if (!evt) // i.e. the argument is undefined or null
      evt = window.event;
    var files = evt.target.files; // FileList object
    // Loop through the FileList and render image files as thumbnails.
    for (var i = 0, f; f = files[i]; i++) {

        // Only process image files.
        if (!f.type.match('image.*')) {
            continue;
        }

        var reader = new FileReader();

        // Closure to capture the file information.
        reader.onload = (function (theFile) {
            return function (e) {
                $('#' + grav_id + "-a").html(['<img class="thumb" src="', e.target.result,
                    '" title="', escape(theFile.name), '"/>'].join(''));
            };
        })(f);

        // Read in the image file as a data URL.
        reader.readAsDataURL(f);
    }

    if (grav_id && grav_id.length > 0) {
      funct_avatar('a', grav_id, radio_button_id);
    }
}

function js_flash(tipo, txt) {
    //fs-flash
    s = "";
    if ($.isArray(txt)) {
        $.each(txt, function (index, value) {
            s += '<p class="f-' + tipo + '"><span class="i-' + tipo +'"> </span>' + txt + '</p><div id="fs-flash-close-me"> clicca per chiudere</div>'
        });
    } else {
        s +=  '<p class="f-' + tipo + '"><span class="i-' + tipo  +'"> </span>' +  txt + '</p><div id="fs-flash-close-me"> clicca per chiudere</div>'
    }
    $('#fs-flash').html(s).focus();  //la focus fa la show e il center_me
}
 /*
jQuery.fn.center_me = function () {
    this.css("position","absolute");
    this.css("top", Math.max(0, (($(window).height() - $(this).outerHeight()) / 2) + $(window).scrollTop()) + "px");
    this.css("left", Math.max(0, (($(window).width() - $(this).outerWidth()) / 2) + $(window).scrollLeft()) + "px");
    return this;
}  */

function setVisible(id, visible) {
    var el = $(id);
    if (el) {
        if (visible) {
            el.show();
        } else {
            el.hide();
        }
    }
}
