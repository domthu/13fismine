/*cookies EU law accept*/
(function (window) {

    if (!!window.cookieTI) {
        return window.cookieTI;
    }

    var document = window.document;
    // IE8 does not support textContent, so we should fallback to innerText.
    //var supportsTextContent = 'textContent' in document.body;
    var supportsTextContent = true;
    //var cookieText = "<p>Questo sito o gli strumenti terzi da questo utilizzati si avvalgono di cookie necessari al funzionamento ed utili alle finalità illustrate nella cookie policy.</p><p>Se vuoi saperne di più consulta la <a href='@@ref-policy@@' class='cookieTI-cookie-policy-link' target='_blank'>cookie policy</a>.</p><p>Chiudendo questo banner  o proseguendo la navigazione, acconsenti all’uso dei cookie.</p>.";
    var cookieText = "<p>Questo sito o gli strumenti terzi da questo utilizzati si avvalgono di cookie necessari al funzionamento ed utili alle finalità illustrate nella cookie policy.</p><p>Se vuoi saperne di più consulta la <a href='@@ref-policy@@' class='cookieTI-cookie-policy-link' target='_blank'>cookie policy</a>.</p><p>Chiudendo questo banner cliccando su accetto, acconsenti all’uso dei cookie.</p>.";
    var dismissText = 'ACCETTO';
    var linkText = 'leggi cookies policy';
    
    var cookieTI = (function () {

        var cookieName = 'FiscosportCookie';
        var domainName = 'fiscopsport.it';
        //var domainName = 'localhost';
        var cookieTIId = 'cookieChoiceInfo';
        var dismissLinkId = 'cookieChoiceDismiss';

        function _createHeaderElement(cookieText, dismissText, linkText, linkHref) {
            var butterBarStyles = 'position:fixed;width:100%;background-color:#eee;' +
                'margin:0; left:0; top:0;padding:4px;z-index:1000;text-align:center;';

            var cookieTIElement = document.createElement('div');
            cookieTIElement.id = cookieTIId;
            cookieTIElement.style.cssText = butterBarStyles;
            cookieTIElement.appendChild(_createTIText(cookieText));

            if (!!linkText && !!linkHref) {
                cookieTIElement.appendChild(_createInformationLink(linkText, linkHref));
            }
            cookieTIElement.appendChild(_createDismissLink(dismissText));
            return cookieTIElement;
        }

        function _createDialogElement(cookieText, dismissText, linkText, linkHref) {
            var glassStyle = 'position:fixed;width:100%;height:230px;z-index:999;' +
                'top:0;left:0;opacity:0.8;filter:alpha(opacity=80);' +
                'background-color:#333;';
            var dialogStyle = 'z-index:1000;position:fixed;left:50%;top:10px';
            var contentStyle = 'position:relative;left:-50%;' +
                'background-color:#fff;padding:20px;box-shadow:4px 4px 25px #888;';

            var cookieTIElement = document.createElement('div');
            cookieTIElement.id = cookieTIId;

            var glassPanel = document.createElement('div');
            glassPanel.style.cssText = glassStyle;

            var content = document.createElement('div');
            content.style.cssText = contentStyle;

            var dialog = document.createElement('div');
            dialog.style.cssText = dialogStyle;

            var dismissLink = _createDismissLink(dismissText);
            //dismissLink.style.display = 'block';
            //dismissLink.style.textAlign = 'right';
            //dismissLink.style.marginTop = '8px';
            dismissLink.style.float = 'right';


            content.appendChild(_createTIText(cookieText));
            if (!!linkText && !!linkHref) {
                content.appendChild(_createInformationLink(linkText, linkHref));
            }
            content.appendChild(dismissLink);
            dialog.appendChild(content);
            cookieTIElement.appendChild(glassPanel);
            cookieTIElement.appendChild(dialog);
            return cookieTIElement;
        }

        function _setElementText(element, text) {
            if (supportsTextContent) {
                element.textContent = text;
            } else {
                element.innerText = text;
            }
        }

        function _createTIText(cookieText) {
            //var TIText = document.createElement('span');
            var TIText = document.createElement('div');
            //_setElementText(TIText, cookieText);
            TIText.innerHTML = cookieText;
            return TIText;
        }

        function _createDismissLink(dismissText) {
            var dismissLink = document.createElement('a');
            _setElementText(dismissLink, dismissText);
            dismissLink.id = dismissLinkId;
            //dismissLink.className = "btn btn-primary";
            dismissLink.className = "btn btn-success";
            dismissLink.href = '#';
            //dismissLink.style.marginLeft = '24px';
            dismissLink.style = 'marginLeft: 24px; right: 24px; float: right;';
            return dismissLink;
        }

        function _createInformationLink(linkText, linkHref) {
            var infoLink = document.createElement('a');
            _setElementText(infoLink, linkText);
            infoLink.className = "btn btn-info";
            infoLink.href = linkHref;
            infoLink.target = '_blank';
            infoLink.style.marginLeft = '8px';
            return infoLink;
        }

        function _dismissLinkClick() {
            _saveUserPreference();
            _removeCookieTI();
            return false;
        }

        function _showCookieTI(cookieText, dismissText, linkText, linkHref, isDialog) {
            if (_shouldDisplayTI()) {
                _removeCookieTI();
                var TIElement = (isDialog) ?
                    _createDialogElement(cookieText, dismissText, linkText, linkHref) :
                    _createHeaderElement(cookieText, dismissText, linkText, linkHref);
                var fragment = document.createDocumentFragment();
                fragment.appendChild(TIElement);
                document.body.appendChild(fragment.cloneNode(true));
                document.getElementById(dismissLinkId).onclick = _dismissLinkClick;
            } else {
                /*lancio */
            }
        }

        function showCookieTIBar(cookieText, dismissText, linkText, linkHref) {
            _showCookieTI(cookieText, dismissText, linkText, linkHref, false);
        }

        //function showCookieTIDialog(cookieText, dismissText, linkText, linkHref) {
        function showCookieTIDialog(linkHref) {
            cookieText = cookieText.replace('@@ref-policy@@', linkHref);
            _showCookieTI(cookieText, dismissText, linkText, linkHref, true);
        }

        function _removeCookieTI() {
            var cookieChoiceElement = document.getElementById(cookieTIId);
            if (cookieChoiceElement != null) {
                cookieChoiceElement.parentNode.removeChild(cookieChoiceElement);
            }
        }

        function _saveUserPreference() {
            // Set the cookie expiry to one year after today.
            var expiryDate = new Date();
            expiryDate.setFullYear(expiryDate.getFullYear() + 1);
            document.cookie = cookieName + '=y; expires=' + expiryDate.toGMTString() + '; path=/; domain=' + domainName + '; secure: true';
            //document.cookie = cookieName + '=y; expires=' + expiryDate.toGMTString() + '; path=/; domain=' + domainName + '; secure: true';
            //document.cookie = cookieName + '=y; expires=' + expiryDate.toGMTString();
        }

        function _shouldDisplayTI() {
            // Display the header only if the cookie has not been set.
            return !document.cookie.match(new RegExp(cookieName + '=([^;]+)'));
        }

        var exports = {};
        exports.showCookieTIBar = showCookieTIBar;
        exports.showCookieTIDialog = showCookieTIDialog;
        return exports;
    })();

    window.cookieTI = cookieTI;
    return cookieTI;
})(this);
