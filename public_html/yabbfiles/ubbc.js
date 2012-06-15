//##############################################################################
//# ubbc.js                                                                    #
//##############################################################################
//# YaBB: Yet another Bulletin Board                                           #
//# Open-Source Community Software for Webmasters                              #
//# Version:        YaBB 2.5 Anniversary Edition                               #
//# Packaged:       July 04, 2010                                              #
//# Distributed by: http://www.yabbforum.com                                   #
//# ===========================================================================#
//# Copyright (c) 2000-2010 YaBB (www.yabbforum.com) - All Rights Reserved.    #
//# Software by:  The YaBB Development Team                                    #
//#               with assistance from the YaBB community.                     #
//# Sponsored by: Xnull Internet Media, Inc. - http://www.ximinc.com           #
//#               Your source for web hosting, web design, and domains.        #
//##############################################################################

//YaBB 2.5 AE $Revision: 1.7 $

function submitproc() {
	if (window.submitted) return false;
	window.submitted = true;
	return true;
}

function storeCaret(text) { 
	if (text.createTextRange) text.caretPos = document.selection.createRange().duplicate();
}

function AddSelText(bbopen, bbclose) {
	if (document.postmodify.message.caretPos) {
		var old_length = document.postmodify.message.caretPos.text.length;
		document.postmodify.message.caretPos.text = bbopen + document.postmodify.message.caretPos.text + bbclose;
		if (old_length == 0) document.postmodify.message.caretPos.moveStart("character", -bbclose.length);
		else document.postmodify.message.caretPos.moveStart("character", -(bbclose.length + old_length));
		document.postmodify.message.caretPos.moveEnd("character", -bbclose.length);
		document.postmodify.message.caretPos.select();
	}
	else if (document.postmodify.message.setSelectionRange) {
		var selectionStart = document.postmodify.message.selectionStart;
		var selectionEnd = document.postmodify.message.selectionEnd;
		var currentTop = document.postmodify.message.scrollTop;		
		var replaceString = bbopen + document.postmodify.message.value.substring(selectionStart, selectionEnd) + bbclose;
		document.postmodify.message.value = document.postmodify.message.value.substring(0, selectionStart) + replaceString + document.postmodify.message.value.substring(selectionEnd);
		document.postmodify.message.setSelectionRange(selectionStart + bbopen.length, selectionEnd + bbopen.length);
		document.postmodify.message.scrollTop = currentTop;		
	}
	else document.postmodify.message.value += bbopen + bbclose;
	document.postmodify.message.focus()
}

function AddText(text) {
	AddSelText(text, '');
}

function AddSelTextUrl(bbopen, bbclose) {
	var thetext = '';
	var theurl = '';
	blopen = bbopen.substring(0, bbopen.length - 1)
	if (document.postmodify.message.caretPos) {
		tmpString=document.postmodify.message.caretPos.text.replace(/\s*(.+?)\s*$/i, "$1");
		var old_length = tmpString.length;
		spliturl = tmpString.split(" ");
		theurl = spliturl[0];
		if ( spliturl.length > 1 && (theurl.match(/\S\.\S/)) ) {
			for (var i=1; i < spliturl.length; i++) { thetext += spliturl[i]; if (i < (spliturl.length - 1)) { thetext += " " } }
			document.postmodify.message.caretPos.text = blopen + '=' + theurl + ']' + thetext + bbclose;
		}
		else document.postmodify.message.caretPos.text = bbopen + tmpString + bbclose;
		if (old_length == 0) document.postmodify.message.caretPos.moveStart("character", -bbclose.length);
		document.postmodify.message.caretPos.moveEnd("character", -bbclose.length);
		document.postmodify.message.caretPos.select();
	}
	else if (document.postmodify.message.setSelectionRange) {
		var markString = blopen + '=';
		var selectionStart = document.postmodify.message.selectionStart;
		var selectionEnd = document.postmodify.message.selectionEnd;
		var currentTop = document.postmodify.message.scrollTop;
		var tmpString = document.postmodify.message.value.substring(selectionStart, selectionEnd);
		spliturl=tmpString.replace(/\s*(.+?)\s*$/i, "$1");
		spliturl = spliturl.split(" ");
		theurl = spliturl[0];
		if ( spliturl.length > 1 && (theurl.match(/\S\.\S/)) ) {
			for (var i=1; i < spliturl.length; i++) { thetext += spliturl[i]; if (i < (spliturl.length - 1)) { thetext += " " } }
			markString = blopen + '=' + theurl + ']';
			replaceString = blopen + '=' + theurl + ']' + thetext + bbclose;
		}
		else replaceString = bbopen + tmpString + bbclose;
		document.postmodify.message.value = document.postmodify.message.value.substring(0, selectionStart) + replaceString + document.postmodify.message.value.substring(selectionEnd);
		document.postmodify.message.setSelectionRange(selectionStart + markString.length, selectionEnd + bbopen.length);
		document.postmodify.message.scrollTop = currentTop;		
	}
	else document.postmodify.message.value += bbopen + bbclose;
	document.postmodify.message.focus()
}

function emai1() {
	AddSelTextUrl("[email]","[/email]");
}


function hyperlink() {
	AddSelTextUrl("[url]","[/url]");
}

function hr() {
	AddText("[hr]");
}

function timestamp(thetime) {
	thetime += cntsec;
	AddText("[timestamp="+thetime+"]");
}

function size() {
	AddSelText("[size=12]","[/size]");
}

function edit() {
	AddSelText("[edit]","[/edit]");
}

function me() {
	AddText("/me");
}

function fntsize(size) {
	AddSelText("[size="+size+"]","[/size]");
	document.getElementById("fontsize").options[0].text = size;
	document.getElementById("fontsize").options[0].selected = true;
}

function font() {
	AddSelText("[font=Verdana]","[/font]");
}

function fontfce(font) {
	AddSelText("[font="+font+"]","[/font]");
	document.getElementById("fontface").options[0].text = font;
	document.getElementById("fontface").options[0].selected = true;
}

function highlight() {
	AddSelText("[highlight]","[/highlight]");
}

function me() {
        AddText("/me ");
}

function teletype() {
	AddSelText("[tt]","[/tt]");
}

function right() {
	AddSelText("[right]","[/right]");
}

function left() {
	AddSelText("[left]","[/left]");
}

function superscript() {
	AddSelText("[sup]","[/sup]");
}

function subscript() {
	AddSelText("[sub]","[/sub]");
}

function image() {
	AddSelText("[img]","[/img]");
}

function ftp() {
	AddSelText("[ftp]","[/ftp]");
}

function move() {
	AddSelText("[move]","[/move]");
}

function flash() {
	AddSelText("[media]","[/media]");
}

function pre() {
	AddSelText("[pre]","[/pre]");
}

function tcol() {
	AddSelText("[td]","[/td]");
}

function trow() {
	AddSelText("[tr]","[/tr]");
}

function table() {
	AddSelText("[table][tr][td]", "[/td][/tr][/table]");
}

function strike() {
	AddSelText("[s]","[/s]");
}

function underline() {
	AddSelText("[u]","[/u]");
}

function bold() {
	AddSelText("[b]","[/b]");
}

function italicize() {
	AddSelText("[i]","[/i]");
}

function quote() {
	AddSelText("[quote]","[/quote]");
}

function center() {
	AddSelText("[center]","[/center]");
}

function showcode() {
	AddSelText("[code]","[/code]");
}

function list() {
	AddSelText("[list][*]", "\n[/list]");
}

function showcolor(color) {
	AddSelText("[color="+color+"]","[/color]");
}

function smiley() {
	AddText(" :)");
}

function wink() {
	AddText(" ;)");
}

function cheesy() {
	AddText(" :D");
}

function grin() {
	AddText(" ;D");
}

function angry() {
	AddText(" >:(");
}

function sad() {
	AddText(" :(");
}

function shocked() {
	AddText(" :o");
}

function cool() {
	AddText(" 8-)");
}

function huh() {
	AddText(" :-?");
}

function rolleyes() {
	AddText(" ::)");
}

function tongue() {
	AddText(" :P");
}

function lipsrsealed() {
	AddText(" :-X");
}

function embarassed() {
	AddText(" :-[");
}

function undecided() {
	AddText(" :-/");
}

function kiss() {
	AddText(" :-*");
}

function cry() {
	AddText(" :'(");
}
