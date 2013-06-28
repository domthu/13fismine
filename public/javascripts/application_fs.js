/*funzione aggiunta per il preview di paperclip */

// valori accettati 1= Immagine Avatar Papareclip , 0 = Immagine Gravatar , 2  = Nuova immagine upload
function funct_avatar(val) {
    if (val == 'g') {
        document.getElementById('fs-photo-edit-i').style.display = 'none';
        document.getElementById('fs-photo-edit-a').style.display = 'none';
        document.getElementById('fs-photo-edit-g').style.display = 'block';
    }
    else if (val == 'a') {
        document.getElementById('fs-photo-edit-i').style.display = 'none';
        document.getElementById('fs-photo-edit-a').style.display = 'block';
        document.getElementById('fs-photo-edit-g').style.display = 'none';
    }
    else if (val == 'i') {
        document.getElementById('fs-photo-edit-i').style.display = 'block';
        document.getElementById('fs-photo-edit-a').style.display = 'none';
        document.getElementById('fs-photo-edit-g').style.display = 'none';
        document.getElementById('use_gravatar_false').checked = true;
        document.getElementById('use_gravatar_true').checked = false;
        document.getElementById('use_gravatar_false').setAttribute('checked', 'checked');
    }

}
function handleFileSelect(evt, prev_id, avatar) {
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
                // Render thumbnail.
                // var span = document.createElement('span');
                var span = document.getElementById(prev_id);
                span.innerHTML = ['<img class="thumb" src="', e.target.result,
                    '" title="', escape(theFile.name), '"/>'].join('');
                //document.getElementById(prev_id).insertBefore(span, null);
            };
        })(f);

        // Read in the image file as a data URL.
        reader.readAsDataURL(f);
    }

    if (avatar && avatar.length > 0) {
     funct_avatar(avatar);
    }
}
function js_flash(tipo, txt) {
  //fs-flash
  s = "";
  if ($.isArray(txt)) {
      $.each(txt, function (index, value) {
          s += '<p> <span class="' + tipo + '"></span>' + value + '</p>'
      });
  } else {
      s += '<p> <span class="' + tipo + '"></span>' + txt + '</p>'
  }
  $("#fs-flash").html(s).focus();
}
