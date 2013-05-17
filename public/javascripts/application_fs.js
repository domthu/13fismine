/*funzione aggiunta per il preview di paperclip */

function handleFileSelect(evt) {
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
                var span = document.getElementById('prev');
                span.innerHTML = ['<img src="', e.target.result,
                    '" title="', escape(theFile.name), '"/>'].join('');
                document.getElementById('prev').insertBefore(span, null);
            };
        })(f);
// Read in the image file as a data URL.
        reader.readAsDataURL(f);
    }
}
