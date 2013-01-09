// This Javascript is written by Peter Velichkov (http://blog.creonfx.com)
// and is distributed under the following license : http://creativecommons.org/licenses/by-sa/3.0/
// Use and modify all you want just keep this comment. Thanks

var incdec = 0;
var headID = document.getElementsByTagName("head")[0];
var cssNode = document.createElement("style");
cssNode.type = 'text/css';
cssNode.id="resizingText";

function createCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name) {
	createCookie(name,"",-1);
}

function loadCss(x,y){
	try{
		var cssStr = '\
		#fs-articolo-full{font-size:' + (15+x) +'px;';
        if (y==2){
            var cssCol ='	-moz-column-count: 2; -moz-column-gap: 1em;-moz-column-rule: 1px solid black;' +
            ' -webkit-column-count: 3; -webkit-column-gap: 1em; -webkit-column-rule: 1px solid black;' +
            'column-count: 3; column-gap: 1em; column-rule: 1px solid black;';
        }
        else{
            var cssCol =''
        }
        cssStr= cssStr + cssCol +'}';
		if(cssNode.styleSheet){
			cssNode.styleSheet.cssText = cssStr; // for IE
		} else {
			var cssText = document.createTextNode(cssStr);
			cssNode.appendChild(cssText); // breaks ie
			//cssNode.innerHTML = cssStr; // breaks saffari
		}
		if(!document.getElementById("resizingText"))headID.appendChild(cssNode);
	}catch(err){ 
		// some debugging code
	}
}

function increaseFontSize() {
	if(incdec < 3){
		incdec++;
		loadCss(incdec);
		createCookie('textsize',incdec,1); 
	}
}

function decreaseFontSize() {
	if(incdec > 0){
		incdec--;
		loadCss(incdec);
		createCookie('textsize',incdec,1); 
	}		
}

var x = readCookie('textsize')
if (x && x!=0) {
	x = parseInt(x);
	incdec = x;
	loadCss(x);
}
// prova colonne

function columns2() {
		createCookie('columns',2,1); }

function columns1() {
		createCookie('columns',1,1);
}
var y = readCookie('columns')
if (y && y!=0) {
	y = parseInt(y);
	loadCss(y);
}

//eraseCookie('textsize');