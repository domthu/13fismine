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
  //  <p class='f-<%= key.to_s %>'><span class='<%= key.to_s %>-fs'> </span>  <%= msg %> </p>
    s = "";
    if ($.isArray(txt)) {
        $.each(txt, function (index, value) {
            s += '<p class="f-' + tipo + '"><span class="' + tipo +'>-fs"</span>' + txt + '</p><div id="fs-flash-close-me"> clicca per chiudere</div>'
        });
    } else {
        s +=  '<p class="f-' + tipo + '"><span class="' + tipo  +'-fs"></span>' +  txt + '</p><div id="fs-flash-close-me"> clicca per chiudere</div>'
        }
    $('#fs-flash').html(s).focus();  //la focus fa la show e il center_me
    }




    jQuery.fn.center_me = function () {
    this.css("position","absolute");
    this.css("top", Math.max(0, (($(window).height() - $(this).outerHeight()) / 2) + $(window).scrollTop()) + "px");
    this.css("left", Math.max(0, (($(window).width() - $(this).outerWidth()) / 2) + $(window).scrollLeft()) + "px");
    return this;
}

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

function speak(div0,div1,div2 ) {

         var htmlcontents = $("#" + div0).html();
    if (div1 !== undefined)
    {
        htmlcontents += $("#" + div1).html();

    }
    if (div2 !== undefined)
    {
        htmlcontents += $("#" + div2).html();

    }

  //get_id(divid,'it','fm');
  //testare Oddcast e Intranslator
  //www.ispeech.org/text.to.speech?link=http%3A%2F%2Fwww.ispeech.org%2Ftext.to.speech%3Fvoice%3Deuritalianfemale%26action%3Dconvert%26speed%3D0%26text%3Ddire%2520qualcosa
  //var urltts = "http://tts-api.com/tts.mp3?q="; //solo inglese
  //var urltts = "http://www.ispeech.org/text.to.speech?voice=euritalianfemale&action=convert&speed=0&text=";
  //var urltts = "http://www.ispeech.org/text.to.speech?link=http%3A%2F%2Fwww.ispeech.org%2Ftext.to.speech%3Fvoice%3Deuritalianfemale%26action%3Dconvert%26speed%3D0%26text%3D"
  //var urltts = "https://www.yakitome.com/api/rest/tts?api_key=your_api_key&voice=Audrey&speed=5&text=";
  var urltts = "http://api.voicerss.org?hl=it-it&r=0&key=c68635f1104b452e8dbe740c0c0330f3&src="
  $("#divaudio").html("<audio controls autoplay><source src='" + urltts + escape(htmlcontents) + "' type=audio/mpeg></audio>")
}
