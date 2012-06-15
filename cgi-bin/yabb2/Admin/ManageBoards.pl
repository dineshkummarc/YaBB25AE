###############################################################################
# ManageBoards.pl                                                             #
###############################################################################
# YaBB: Yet another Bulletin Board                                            #
# Open-Source Community Software for Webmasters                               #
# Version:        YaBB 2.5 Anniversary Edition                                #
# Packaged:       July 04, 2010                                               #
# Distributed by: http://www.yabbforum.com                                    #
# =========================================================================== #
# Copyright (c) 2000-2010 YaBB (www.yabbforum.com) - All Rights Reserved.     #
# Software by:  The YaBB Development Team                                     #
#               with assistance from the YaBB community.                      #
# Sponsored by: Xnull Internet Media, Inc. - http://www.ximinc.com            #
#               Your source for web hosting, web design, and domains.         #
###############################################################################

$manageboardsplver = 'YaBB 2.5 AE $Revision: 1.21 $';
if ($action eq 'detailedversion') { return 1; }

sub ManageBoards {
	&is_admin_or_gmod;
	&LoadBoardControl;
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	if ($INFO{'action'} eq 'managecats') {
		$colspan = qq~colspan="2"~;
		$add = $admin_txt{'47'};
		$act = 'catscreen';
		$manage = qq~<a href="$adminurl?action=reordercats"><img src="$imagesdir/reorder.gif" alt="$admin_txt{'829'}" title="$admin_txt{'829'}" border="0" style="vertical-align: middle;" /></a> &nbsp;<b>$admin_txt{'49'}</b>~;
		$managedescr = $admin_txt{'678'};
		$act2 = 'addcat';
		$action_area = 'managecats';
	} else {
		$colspan = qq~colspan="4"~;
		$add = $admin_txt{'50'};
		$act = 'boardscreen';
		$manage = qq~<img src="$imagesdir/cat.gif" alt="" border="0" style="vertical-align: middle;" /> &nbsp;<b>$admin_txt{'51'}</b>~;
		$managedescr = $admin_txt{'677'};
		$act2 = 'addboard';
		$action_area = 'manageboards';
	}
	$yymain .= qq~
<script language="JavaScript1.2" type="text/javascript">
	<!--
		function checkSubmit(where){ 
			var something_checked = false;
			for (i=0; i<where.elements.length; i++){
				if(where.elements[i].type == "checkbox"){
					if(where.elements[i].checked == true){
						something_checked = true;
					}
				}
			}
			if(something_checked == true){
				if (where.baction[1].checked == false){
					return true;
				}
				if (confirm("$admin_txt{'617'}")) {
					return true;
				} else {
					return false; 
				}
			} else {
				alert("$admin_txt{'5'}");
				return false;
			}
		}
	//-->
</script>
<form name="whattodo" action="$adminurl?action=$act" onSubmit="return checkSubmit(this);" method="post">
 <div class="bordercolor" style="padding: 0px; width: 99%; margin-left: 0px; margin-right: auto;">
   <table width="100%" cellspacing="1" cellpadding="4">
     <tr valign="middle">
       <td align="left" class="titlebg" $colspan>
		 $manage
	   </td>
     </tr>
     <tr align="center" valign="middle">
       <td align="left" class="windowbg2" $colspan><br />
		  $managedescr<br /><br />
	   </td>
     </tr>
~;
	foreach $catid (@categoryorder) {
		@bdlist = split(/,/, $cat{$catid});
		($curcatname, $catperms) = split(/\|/, $catinfo{"$catid"});
		&ToChars($curcatname);

		if ($INFO{"action"} eq "managecats") {
			$tempcolspan = "";
			$tempclass   = "windowbg2";
			$temphrefclass = "";
		} else {
			$tempcolspan = qq~colspan="4"~;
			$tempclass   = "catbg";
			$temphrefclass = qq~class="catbg a"~;
		}

		$yymain .= qq~
     <tr valign="middle">
       <td align="left" height="25" class="$tempclass" valign="middle" $tempcolspan>
		<a href="$adminurl?action=reorderboards;item=$catid" $temphrefclass><img src="$imagesdir/reorder.gif" alt="$admin_txt{'832'}" title="$admin_txt{'832'}" border="0" style="vertical-align: middle;" /></a> &nbsp;<b>$curcatname</b>
	   </td>
~;
		if ($INFO{"action"} eq "managecats") {
			$yymain .= qq~
    	<td class="windowbg" height="25" width="10%" align="center"><input type="checkbox" name="yitem_$catid" value="1" /></td>~;
		}

		$yymain .= qq~
     </tr>~;
		unless ($INFO{"action"} eq "managecats") {
			foreach $curboard (@bdlist) {
				($boardname, $boardperms, $boardview) = split(/\|/, $board{$curboard});
				$boardname =~ s/\&quot\;/&#34;/g;
				&ToChars($boardname);
				$descr = ${$uid.$curboard}{'description'};
				$descr =~ s~\<br />~\n~g;
				my $bicon = "";
				if(${$uid.$curboard}{'pic'}) { $bicon = ${$uid.$curboard}{'pic'}; }
				if ($bicon =~ /\//i) { $bicon = qq~ <img src="$bicon" alt="" border="0" /> ~; }
				elsif ($bicon) { $bicon = qq~ <img src="$imagesdir/$bicon" alt="" border="0" /> ~; }
				if (${$uid.$curboard}{'ann'} == 1)  { $bicon = qq~ <img src="$imagesdir/ann.gif" alt="$admin_txt{'64g'}" title="$admin_txt{'64g'}" border="0" />~; }
				if (${$uid.$curboard}{'rbin'} == 1) { $bicon = qq~ <img src="$imagesdir/recycle.gif" alt="$admin_txt{'64i'}" title="$admin_txt{'64i'}" border="0" />~; }
				$convertstr = $descr;
				unless($convertstr =~ /<.+?>/) { # Don't cut it if there's HTML in it.
					$convertcut = 60;
					&CountChars;
				}
				my $descr = $convertstr;
				&ToChars($descr);
				if ($cliped) { $descr .= "..."; }
				$yymain .= qq~
  <tr>
    <td class="windowbg" width="25%" align="left">$boardname</td>
    <td class="windowbg" width="65%" align="left">$descr</td>
    <td class="windowbg" width="5%" align="center">$bicon</td>
    <td class="titlebg" width="5%" align="center"><input type="checkbox" name="yitem_$curboard" value="1" /></td>
  </tr>
~;
			}
		}
	}

	$yymain .= qq~
  	<tr>
      <td class="catbg" width="100%" align="center" valign="middle" $colspan> <label for="baction">$admin_txt{'52'}</label>
    	<input type="radio" name="baction" id="baction" value="edit" checked="checked" /> $admin_txt{'53'} 
    	<input type="radio" name="baction" value="delme" /> $admin_txt{'54'} 
    	<input type="submit" value="$admin_txt{'32'}" class="button" /></td>
  	 </tr>
</table>
</div>
</form>
<br />
<form name="diff" action="$adminurl?action=$act2" method="post">
 <div class="bordercolor" style="padding: 0px; width: 99%; margin-left: 0px; margin-right: auto;">
   <table width="100%" cellspacing="1" cellpadding="4">
  <tr>
    <td class="catbg" align="center" valign="middle"><label for="amount"><b>$add: </b></label>
	<input type="text" name="amount" id="amount" value="3" size="2" maxlength="2" /> 
	<input type="submit" value="$admintxt{'45'}" class="button" />
	</td>
  </tr>
   </table>
 </div>
</form>
~;
	$yytitle = "$admintxt{'a4_title'}";
	&AdminTemplate;
}

sub BoardScreen {
	&is_admin_or_gmod;
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	$i = 0;
	while ($_ = each(%FORM)) {
		if ($FORM{$_} && $_ =~ /^yitem_(.+)$/) {
			$editboards[$i] = $1;
			$i++;
		}
	}
	$i = 1;
	foreach $thiscat (@categoryorder) {
		@theboards = split(/,/, $cat{$thiscat});
		for (my $z = 0; $z < @theboards; $z++) {
			for (my $j = 0; $j < @editboards; $j++) {
				if ($editboards[$j] eq $theboards[$z]) {
					$editbrd[$i] = $theboards[$z];
					$i++;
					splice(@editboards,$j,1);
					last;
				}
			}
		}
	}
	if    ($FORM{'baction'} eq "edit")  { &AddBoards(@editbrd); }
	elsif ($FORM{'baction'} eq "delme") {
		shift(@editbrd);
		if (!$mloaded) { require "$boardsdir/forum.master"; }
		foreach my $bd (@editbrd) {
			# Remove Board form category it belongs to
			$category = ${$uid.$bd}{'cat'};
			@bdlist = split(/,/, $cat{$category});
			my $c = 0;
			foreach (@bdlist) {
				if ($_ eq $bd) { splice(@bdlist, $c, 1); last; }
				$c++;
			}
			$cat{$category} = join(',', &undupe(@bdlist));
			delete $board{$bd};
			$yymain .= qq~$admin_txt{'55'}$bd <br />~;
		}

		# Actual deleting
		&DeleteBoards(@editbrd);
		&Write_ForumMaster;

	} else {
		&admin_fatal_error("no_action","$FORM{'baction'}");
	}

	$action_area = "manageboards";
	&AdminTemplate;
}

sub DeleteBoards {
	&is_admin_or_gmod;

	fopen(FORUMCONTROL, "+<$boardsdir/forum.control") || &fatal_error("cannot_open","$boardsdir/forum.control", 1);
	seek FORUMCONTROL, 0, 0;
	my @oldcontrols = <FORUMCONTROL>;
	foreach $board (@_) {
		fopen(BOARDDATA, "$boardsdir/$board.txt");
		@messages = <BOARDDATA>;
		fclose(BOARDDATA);
		foreach $curmessage (@messages) {
			my ($id, undef) = split(/\|/, $curmessage, 2);
			unlink("$datadir/$id\.txt");
			unlink("$datadir/$id\.mail");
			unlink("$datadir/$id\.ctb");
			unlink("$datadir/$id\.data");
			unlink("$datadir/$id\.poll");
			unlink("$datadir/$id\.polled");
		}
		for (my $cnt = 0; $cnt < @oldcontrols; $cnt++) {
			my $oldboard;
			(undef, $oldboard, undef) = split(/\|/, $oldcontrols[$cnt], 3);
			$yydebug .= "$cnt   $oldboard \n";
			if ($oldboard eq $board) {
				$oldcontrols[$cnt] = "";
				$yydebug .= "\$board{\"$oldboard\"}";
				delete $board{"$board"};
				last;
			}
		}
		unlink("$boardsdir/$board.txt");
		unlink("$boardsdir/$board.ttl");
		unlink("$boardsdir/$board.poster");
		unlink("$boardsdir/$board.mail");

		fopen(ATM, "+<$vardir/attachments.txt", 1);
		seek ATM, 0, 0;
		my @buffer = <ATM>;
		my ($amcurrentboard,$amfn);
		for (my $a = 0; $a < @buffer; $a++) {
			(undef, undef, undef, undef, $amcurrentboard, undef, undef, $amfn, undef) = split(/\|/, $buffer[$a]);
			if ($amcurrentboard eq $board) {
				$buffer[$a] = '';
				unlink("$upload_dir/$amfn");
			}
		}
		truncate ATM, 0;
		seek ATM, 0, 0;
		print ATM @buffer;
		fclose(ATM);

		&BoardTotals("delete", $board);
	}

	my @boardcontrol = grep { $_; } @oldcontrols;

	truncate FORUMCONTROL, 0;
	seek FORUMCONTROL, 0, 0;
	print FORUMCONTROL sort(@boardcontrol);
	fclose(FORUMCONTROL);

	fopen(FORUMCONTROL, "$boardsdir/forum.control");
	@forum_control = <FORUMCONTROL>;
	fclose(FORUMCONTROL);
}

sub AddBoards {
	my @editboards = @_;
	&is_admin_or_gmod;
	$addtext = $admin_txt{'50'};
	if ($INFO{'action'} eq 'boardscreen') { $FORM{'amount'} = $#editboards; $addtext = $admin_txt{'50a'}; }
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	$yymain .= qq~
<script language="JavaScript1.2" type="text/javascript">
<!--
var copyValues = new Array();
var copyList = new Array();

// this function removes an entry from the IM multi-list
function removeUser(oElement) {
	var oList = oElement.options;
	var noneSelected = 1;

	for (var i = 0; i < oList.length; i++) {
		if(oList[i].selected) noneSelected = 0;
	}
	if(noneSelected) return false;

	var indexToRemove = oList.selectedIndex;
	if (confirm("$selector_txt{'remove'}"))
		{oElement.remove(indexToRemove);}
}
// this function forces all users listed in moderators to be selected for processing
function selectNames(total) {
	for(var x = 1; x <= total; x++) {
	var oList = document.getElementById('moderators'+x)
	for (var i = 0; i < oList.options.length; i++)
		{oList.options[i].selected = true;}
	}
}
// allows copying one or multiple items from moderators list
function copyNames(num) {
	copyList = new Array();
	copyValues = new Array();
	var oList = document.getElementById('moderators'+num).options;
	for (var i = 0; i < oList.length; i++) {
		if(oList[i].selected == true) {
			copyList[copyList.length] = oList[i].text;
			copyValues[copyValues.length] = oList[i].value;
		}
	}
}
// allows pasting from previously copied moderator list items
function pasteNames(num,total) {
	var found = false;
	var oList = null;
	var which = 0;
	if(copyList.length != 0) {
		for(var x = 0; x < total; x++) {
			which = num + x;
			oList = document.getElementById('moderators'+which).options;
			for (var e = 0; e < copyList.length; e++) {
				found = false;
				for (var i = 0; i < oList.length; i++) {
					if(oList[i].value == copyValues[e] || oList[i].text == copyList[e]) {
						found = true;
						break;
					}
				}
				if(found == false) {
					if(navigator.appName=="Microsoft Internet Explorer") {
						document.getElementById('moderators'+which).add(new Option(copyList[e],copyValues[e]));
					} else {
						document.getElementById('moderators'+which).add(new Option(copyList[e],copyValues[e]),null);
					}
				}
			}
		}
	}
}
//-->
</script>
<form name="boardsadd" action="$adminurl?action=addboard2" method="post" onsubmit="selectNames($FORM{'amount'});">
 <div class="bordercolor" style="padding: 0px; width: 99%; margin-left: 0px; margin-right: auto;">
<table border="0" align="center" cellspacing="1" cellpadding="4" width="100%">
  <tr>
    <td class="titlebg" colspan="5" align="left">
    <img src="$imagesdir/cat.gif" alt="" border="0" />
    <b>$addtext</b></td>
  </tr><tr>
      <td class="windowbg2" colspan="5" align="left"><br />$admin_txt{'57'}<br /><br /></td>
  </tr>
</table>
</div>
<br />
 <div class="bordercolor" style="padding: 0px; width: 99%; margin-left: 0px; margin-right: auto;">
<table border="0" align="center" cellspacing="1" cellpadding="4" width="100%">
~;

	# Check if and which board are set for announcements or recycle bin
	# Start Looping through and repeating the board adding wherever needed
	$istart    = 0;
	$annexist  = "";
	$rbinexist = "";

	for ($i = 1; $i != $FORM{'amount'} + 1; $i++) {
		# differentiate between edit or add boards
		if ($editboards[$i] eq "" && $INFO{"action"} eq "boardscreen") { next; }
		if ($INFO{"action"} eq "boardscreen") {
			$id = $editboards[$i];
		} else {
			$boardtext = "$admin_txt{'58'} $i:";
		}
		foreach $catid (@categoryorder) {
			@bdlist = split(/,/, $cat{$catid});
			($curcatname, $catperms) = split(/\|/, $catinfo{"$catid"});
			my $boardcat = ${$uid.$editboards[$i]}{'cat'};
			if ($INFO{"action"} eq "boardscreen") {
				if ($catid eq $boardcat) { $selected = qq~selected="selected" ~; }
				else { $selected = ""; }
			}
			&ToChars($curcatname);
			$catsel{$i} .= qq~<option value="$catid"$selected>$curcatname</option>~;
		}
		if ($istart == 0) { $istart = $i; }

		($boardname, $boardperms, $boardview) = split(/\|/, $board{"$id"});
		&ToChars($boardname);
		if ($INFO{"action"} eq "boardscreen") { $boardtext = $boardname; }
		$boardpic    = ${$uid.$editboards[$i]}{'pic'};
		$description = ${$uid.$editboards[$i]}{'description'};
		$description =~ s~<br />~\n~g;
		&ToChars($description);
		$moderators      = ${$uid.$editboards[$i]}{'mods'};
		$moderatorgroups = ${$uid.$editboards[$i]}{'modgroups'};
		$boardminage     = ${$uid.$editboards[$i]}{'minageperms'};
		$boardmaxage     = ${$uid.$editboards[$i]}{'maxageperms'};
		$boardgender     = ${$uid.$editboards[$i]}{'genderperms'};
		$genselect       = qq~<select name="gender$i" id="gender$i">~;
		$gentag[0]       = "";
		$gentag[1]       = "M";
		$gentag[2]       = "F";
		$gentag[3]       = "B";
		foreach $genlabel (@gentag) {
			$gentext = "99";
			$gentext .= $genlabel;
			if ($genlabel eq $boardgender) {
				$genselect .= qq~<option value="$genlabel" selected="selected">$admin_txt{$gentext}</option>~;
			} else {
				$genselect .= qq~<option value="$genlabel">$admin_txt{$gentext}</option>~;
			}
		}
		$genselect .= qq~</select>~;

		# Retrieve Optional Details
		$ann      = "";
		$rbin     = "";
		$zeroch   = "";
		$attch    = "";
		$showpriv = "";
		$brdpic   = "";
		if ($boardview == 1)              { $showpriv = qq~ checked="checked"~; }
		if (${$uid.$id}{'zero'} == 1)     { $zeroch   = qq~ checked="checked"~; }
		if (${$uid.$id}{'attperms'} == 1) { $attch    = qq~ checked="checked"~; }

		if (${$uid.$id}{'ann'} == 1) {
			$annch = qq~ checked="checked"~;
			$brdpic   = qq~ disabled="disabled"~;
		} elsif ($annboard ne "") {
			$annch    = qq~ disabled="disabled"~;
			$annexist = 1;
		}
		if (${$uid.$id}{'rbin'} == 1) {
			$rbinch = qq~ checked="checked"~;
			$brdpic   = qq~ disabled="disabled"~;
		} elsif ($binboard ne "") {
			$rbinch    = qq~ disabled="disabled"~;
			$rbinexist = 1;
		}

		#Get Board permissions here
		my $startperms = &DrawPerms(${$uid.$id}{'topicperms'}, 0);
		my $replyperms = &DrawPerms(${$uid.$id}{'replyperms'}, 1);
		my $viewperms  = &DrawPerms($boardperms, 0);
		my $pollperms  = &DrawPerms(${$uid.$id}{'pollperms'}, 0);

		$yymain .= qq~
  <tr>
	<td class="titlebg" width="100%" colspan="5" align="left"> <b>$boardtext</b></td>
  </tr><tr>
	<td class="catbg"  colspan="4"><b>$admin_txt{'59'}:</b> $admin_txt{'60'}</td>
  </tr><tr>~;
		if ($id ne '') {
			$yymain .= qq~
	<td class="windowbg" width="25%" align="left"><label for="id$i"><b>$admin_txt{'61'}</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="hidden" name="id$i" id="id$i" value="$id" />$id</td>~;
		} else {
			$yymain .= qq~
	<td class="windowbg" width="25%" align="left"><label for="id$i"><b>$admin_txt{'61'}</b><br />$admin_txt{'61b'}</label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="text" name="id$i" id="id$i" /></td>~;
		}
		$yymain .= qq~
  </tr><tr>
    <td class="windowbg"  width="25%" align="left"><label for="name$i"><b>$admin_txt{'68'}:</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="text" name="name$i" id="name$i" value="$boardname" size="50" maxlength="100" /></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="description$i"><b>$admin_txt{'62'}:</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><textarea name="description$i" id="description$i" rows="5" cols="30" style="width:98%; height:60px">$description</textarea></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left">
	<b>$admin_txt{'63'}:</b><br /><span class="small">
	<!-- <a href="javascript:void(0);" onclick="window.open('$scripturl?action=imlist;sort=username;toid=moderators$i','','status=no,height=345,width=464,menubar=no,toolbar=no,top=50,left=50,scrollbars=no')">$selector_txt{linklabel}</a><br/> -->
	<a href="javascript:void(0);" onclick="window.open('$scripturl?action=qsearch;toid=moderators$i','','status=no,height=325px,width=300,menubar=no,toolbar=no,top=50,left=50,scrollbars=no')">$selector_txt{linklabel}</a><br />
	<a href="javascript:copyNames($i)">$admin_txt{'63a'}</a><br/>
	<a href="javascript:pasteNames($i,1)">$admin_txt{'63b'}</a><br/>
	<a href="javascript:pasteNames(1,$FORM{'amount'})">$admin_txt{'63c'}</a></span>
    </td>
    <td class="windowbg2" width="75%" colspan="3" align="left">
    	<select name="moderators$i" id="moderators$i" multiple="multiple" size="3" style="width: 320px;" ondblclick="removeUser(this);">~;

		my @thisBoardModerators = split(/, ?/, $moderators);
		foreach my $thisMod (@thisBoardModerators ) {
			&LoadUser($thisMod);
			my $thisModname = ${$uid.$thisMod}{'realname'};
			if (!$thisModname) { $thisModname = $thisMod; }
			if ($do_scramble_id) { $thisMod = &cloak($thisMod); }
			$yymain .= qq~
			<option value="$thisMod">$thisModname</option>~;
		}

		$yymain .= qq~
		</select>
	        <br /><span class="small">$selector_txt{instructions}</span>
    <!--<input type="text" name="moderators$i" value="$moderators" size="50" maxlength="100" />-->
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="moderatorgroups$i"><b>$admin_txt{'13'}:</b></label></td>
	<td class="windowbg2"  width="75%" colspan="3">
~;

		# Allows admin to select entire membergroups to be a board moderator
		$k = 0;
		my $box = "";
		foreach (@nopostorder) {
			@groupinfo = split(/\|/, $NoPost{$_});
			$box .= qq~<option value="$_"~;
			foreach (split(/, /, $moderatorgroups)) {
				($lineinfo, undef) = split(/\|/, $NoPost{$_}, 2);
				if ($lineinfo eq $groupinfo[0]) {
					$box .= qq~ selected="selected" ~;
				}
			}
			$box .= qq~>$groupinfo[0]</option>~;
			$k++;
		}
		if ($k > 5) { $k = 5; }
		if ($k > 0) {
			$yymain .= qq~<select multiple="multiple" name="moderatorgroups$i" id="moderatorgroups$i" size="$k">$box</select> <label for="moderatorgroups$i"><span class="small">$admin_txt{'14'}</span></label>~;
		} else {
			$yymain .= qq~$admin_txt{'15'}~;
		}

		$yymain .= qq~
	</td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="cat$i"><b>$admin_txt{'44'}:</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><select name="cat$i" id="cat$i">$catsel{$i}</select></td>
  </tr><tr>
    <td class="catbg"  colspan="4"><b>$admin_txt{'64'}</b> $admin_txt{'64a'} </td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="pic$i"><b>$admin_txt{'64b'}:</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="text" name="pic$i" id="pic$i" value="$boardpic" size="50" maxlength="255"$brdpic /></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="zero$i"><b>$admin_txt{'64c'}</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="checkbox" name="zero$i" id="zero$i" value="1"$zeroch /> <label for="zero$i">$admin_txt{'64d'}</label></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="show$i"><b>$admin_txt{'64e'}</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="checkbox" name="show$i" id="show$i" value="1"$showpriv /> <label for="show$i">$admin_txt{'64f'}</label></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="att$i"><b>$admin_txt{'64k'}</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="checkbox" name="att$i" id="att$i" value="1"$attch /> <label for="att$i">$admin_txt{'64l'}</label></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="ann$i"><b>$admin_txt{'64g'}</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="checkbox" id="ann$i" name="ann$i" value="1" $annch onclick="javascript: if (this.checked) checkann(true, '$i'); else checkann(false, '$i');" /> <label for="ann$i">$admin_txt{'64h'}</label></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="rbin$i"><b>$admin_txt{'64i'}</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="checkbox" id="rbin$i" name="rbin$i" value="1" $rbinch onclick="javascript: if (this.checked) checkbin(true, '$i'); else checkbin(false, '$i');" /> <label for="rbin$i">$admin_txt{'64j'}</label></td>
  </tr><tr>
    <td class="catbg"  colspan="4"><b>$admin_txt{'100'}:</b> $admin_txt{'100a'}</td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="minage$i"><b>$admin_txt{'95'}:</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="text" size="3" name="minage$i" id="minage$i" value="$boardminage" /> <label for="minage$i">$admin_txt{'96'}</label></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="maxage$i"><b>$admin_txt{'95a'}:</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left"><input type="text" size="3" name="maxage$i" id="maxage$i" value="$boardmaxage" /> <label for="maxage$i">$admin_txt{'96a'}</label></td>
  </tr><tr>
    <td class="windowbg" width="25%" align="left"><label for="gender$i"><b>$admin_txt{'97'}:</b></label></td>
    <td class="windowbg2" width="75%" colspan="3" align="left">$genselect <label for="gender$i">$admin_txt{'98'}</label></td>
  </tr><tr>
    <td class="catbg"  colspan="4"><b>$admin_txt{'65'}:</b> $admin_txt{'65a'} <span class="small">$admin_txt{'14'}</span></td>
  </tr><tr>
    <td class="titlebg" width="25%" align="center"><label for="topicperms$i"><b>$admin_txt{'65b'}:</b></label></td>
    <td class="titlebg" width="25%" align="center"><label for="replyperms$i"><b>$admin_txt{'65c'}:</b></label></td>
    <td class="titlebg" width="25%" align="center"><label for="viewperms$i"><b>$admin_txt{'65d'}:</b></label></td>
    <td class="titlebg" width="25%" align="center"><label for="pollperms$i"><b>$admin_txt{'65e'}:</b></label></td>
  </tr><tr>
    <td class="windowbg2" width="25%" align="center"><select multiple="multiple" name="topicperms$i" id="topicperms$i" size="8">$startperms</select></td>
    <td class="windowbg2" width="25%" align="center"><select multiple="multiple" name="replyperms$i" id="replyperms$i" size="8">$replyperms</select></td>
    <td class="windowbg2" width="25%" align="center"><select multiple="multiple" name="viewperms$i" id="viewperms$i" size="8">$viewperms</select></td>
    <td class="windowbg2" width="25%" align="center"><select multiple="multiple" name="pollperms$i" id="pollperms$i" size="8">$pollperms</select></td>
  </tr>
</table>
</div>
<br /><br />
 <div class="bordercolor" style="padding: 0px; width: 99%; margin-left: 0px; margin-right: auto;">
<table border="0" align="center" cellspacing="1" cellpadding="4" width="100%">
~;
	}
	$yymain .= qq~
  <tr>
      <td class="catbg" width="100%" colspan="5" align="center"> <input type="hidden" name="amount" value=\"$FORM{"amount"}\" />
      <input type="hidden" name="screenornot" value="$INFO{'action'}" />
      <input type="submit" value="$admin_txt{'10'}" class="button" /></td>
  </tr>
</table>
</div>
</form>

<script language="JavaScript1.2" type="text/javascript">
<!--
var numboards = "$FORM{'amount'}";
var annexist = "$annexist";
var rbinexist = "$rbinexist";
var istart = "$istart";

function checkann(acheck, awho) {
	var adischeck = acheck;
	var adisuncheck = acheck;
	for (var i = istart; i <= numboards; i++) {
		if(i != awho) {
			if(document.getElementById('rbin'+i).checked == true) {
				adischeck = true;
				document.getElementById('ann'+i).disabled = true;
			}
			else {
				document.getElementById('ann'+i).disabled = acheck;
			}
		}
	}
	if(document.getElementById('ann'+awho).checked == true) {
		adischeck = true;
		document.forms["boardsadd"].elements['topicperms'+awho].selectedIndex = -1;
		document.forms["boardsadd"].elements['topicperms'+awho].options[0].selected = true;
		document.forms["boardsadd"].elements['replyperms'+awho].selectedIndex = -1;
		document.forms["boardsadd"].elements['replyperms'+awho].options[0].selected = true;
		document.forms["boardsadd"].elements['pollperms'+awho].selectedIndex = -1;
		document.forms["boardsadd"].elements['pollperms'+awho].options[0].selected = true;
	}
	document.getElementById('rbin'+awho).disabled = adischeck;
	document.getElementById('pic'+awho).disabled = adisuncheck;
	if(rbinexist == '1') document.getElementById('rbin'+awho).disabled = true;
}

function checkbin(bcheck, bwho) {
	var bdischeck = bcheck;
	var bdisuncheck = bcheck;
	for (var i = istart; i <= numboards; i++) {
		if(i != bwho) {
			if(document.getElementById('ann'+i).checked == true) {
				bdischeck = true;
				document.getElementById('rbin'+i).disabled = true;
			}
			else document.getElementById('rbin'+i).disabled = bcheck;
		}
	}
	if(document.getElementById('rbin'+bwho).checked == true) bdischeck = true;
	document.getElementById('ann'+bwho).disabled = bdischeck;
	document.getElementById('pic'+bwho).disabled = bdisuncheck;
	if(annexist == '1') document.getElementById('ann'+bwho).disabled = true;
}


//-->
</script>

	~;
	$yytitle     = "$admin_txt{'50'}";
	$action_area = "manageboards";
	&AdminTemplate;
}

sub DrawPerms {
	my ($permissions,$permstype) = @_;
	my ($foundit, %found, $groupsel, $groupsel2, $name);
	my $count = 0;
	if ($permissions eq "") { $permissions = "xk8yj56ndkal"; }
	my @perms = split(/, /, $permissions);
	foreach $perm (@perms) {
		$foundit = 0;
		if ($permstype == 1) {
			$name = $admin_txt{'65f'};
			if ($perm eq "Topic Starter") {
				$foundit = 1;
				$found{$name} = 1;
				$groupsel .= qq~<option value="Topic Starter" selected="selected">$name</option>\n~;
			}
			if ($count == $#perms && $found{$name} != 1) { $groupsel2 .= qq~<option value="Topic Starter">$name</option>\n~; }
		}

		($name, undef) = split(/\|/, $Group{"Administrator"}, 2);
		if ($perm eq "Administrator") {
			$foundit = 1;
			$found{$name} = 1;
			$groupsel .= qq~<option value="Administrator" selected="selected">$name</option>\n~;
		}
		if ($count == $#perms && $found{$name} != 1) { $groupsel2 .= qq~<option value="Administrator">$name</option>\n~; }

		($name, undef) = split(/\|/, $Group{"Global Moderator"}, 2);
		if ($perm eq "Global Moderator") {
			$foundit = 1;
			$found{$name} = 1;
			$groupsel .= qq~<option value="Global Moderator" selected="selected">$name</option>\n~;
		}
		if ($count == $#perms && $found{$name} != 1) { $groupsel2 .= qq~<option value="Global Moderator">$name</option>\n~; }

		if ($foundit != 1 || $count == $#perms) {
			foreach (@nopostorder) {
				($name, undef) = split(/\|/, $NoPost{$_}, 2);
				if ($perm eq $_) {
					$foundit = 1;
					$found{$_} = 1;
					$groupsel .= qq~<option value="$_" selected="selected">$name</option>\n~;
				}
				if ($found{$_} != 1 && $count == $#perms) { $groupsel2 .= qq~<option value="$_">$name</option>\n~; }
			}
			if ($foundit != 1 || $count == $#perms) {
				foreach (sort { $b <=> $a } keys %Post) {
					($name, undef) = split(/\|/, $Post{$_}, 2);
					if ($perm eq $name) {
						$foundit = 1;
						$found{$name} = 1;
						$groupsel .= qq~<option value="$name" selected="selected">$name</option>\n~;
					}
					if ($count == $#perms && ($found{$name} != 1 || $found{$name} eq "")) { $groupsel2 .= qq~<option value="$name">$name</option>\n~; }
				}
			}
		}
		$count++;
	}
	$groupsel . $groupsel2;
}

sub AddBoards2 {
	&is_admin_or_gmod;
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	$anncount  = 0;
	$rbincount = 0;
	my (@boardcontrol,@changes);
	for (my $i = 1; $i != $FORM{'amount'} + 1; $i++) {
		if ($FORM{"pic$i"} ne '' && $FORM{"pic$i"} !~ m~^[0-9a-zA-Z_\.\#\%\-\:\+\?\$\&\~\.\,\@/]+\.(gif|png|bmp|jpg)$~) { &admin_fatal_error("invalid_picture"); }
		##### Dealing with Required Info here #####
		if ($FORM{"id$i"} eq '') { next; }
		$id = $FORM{"id$i"};
		if ($FORM{"ann$i"})  { $anncount++; }
		if ($FORM{"rbin$i"}) { $rbincount++; }
		&admin_fatal_error('announcement_defined') if ($anncount > 1);
		&admin_fatal_error('recycle_bin_defined') if ($rbincount > 1);
		&admin_fatal_error('invalid_character',"$admin_txt{'61'} $admin_txt{'241'}") if ($id !~ /\A[0-9A-Za-z#%+-\.@^_]+\Z/);

		if ($FORM{'screenornot'} ne "boardscreen") {
			# adding a board
			# make sure no board already exists with that id
			&admin_fatal_error("board_defined","$id") if (exists $board{"$id"});

			my @bdlist = split(/\,/, $cat{$FORM{"cat$i"}});
			push(@bdlist, "$id");
			$cat{$FORM{"cat$i"}} = join(',', @bdlist);
			fopen(BOARDINFO, ">$boardsdir/$id.txt");
			print BOARDINFO '';
			fclose(BOARDINFO);
		}
		if ($FORM{'screenornot'} eq "boardscreen") {
			# editing a board
			my $category = ${$uid.$id}{'cat'};

			# move category of board
			if ($category ne $FORM{"cat$i"}) {
				${$uid.$id}{'cat'} = qq~$FORM{"cat$i"}~;
				my @bdlist = split(/,/, $cat{$category});

				# Remove Board from old Category
				my $k = 0;
				foreach $bd (@bdlist) {
					if ($id eq $bd) { splice(@bdlist, $k, 1); }
					$k++;
				}
				$cat{"$category"} = join(',', @bdlist);

				# Add Category to new Category
				my $ncat   = $FORM{"cat$i"};
				if ($cat{$ncat} ne "") { $cat{$ncat} .= ",$id"; }
				else { $cat{$ncat} = $id; }
			}

			if (-e "$boardsdir/$id.txt") { # fix a(nnboard) in the boardid.txt
				fopen(BOARDINFO, "$boardsdir/$id.txt") || &fatal_error('cannot_open', "$openboard/$id.txt", 1);
				my @boardtomodify = <BOARDINFO>;
				fclose(BOARDINFO);
				my $x;
				if ($FORM{"ann$i"} && (split /\|/, $boardtomodify[0])[8] !~ /a/i) {
					for ($x = 0; $x < @boardtomodify; $x++) {
						$boardtomodify[$x] =~ s/(.*\|)(0?)(.*)/ $1 . ($2 eq '0' ? "0a$3" : "a$3") /e;
					}
				} elsif (!$FORM{"ann$i"} && (split /\|/, $boardtomodify[0])[8] =~ /a/i) {
					for ($x = 0; $x < @boardtomodify; $x++) {
						$boardtomodify[$x] =~ s/(.*\|)(.*)/ $1 . &take_a_off($2) /e;
					}
					sub take_a_off { my $y = shift; $y =~ s/a//g; $y; }
				}
				if ($x) {
					fopen(BOARDINFO, ">$boardsdir/$id.txt") || &fatal_error('cannot_open', "$openboard/$id.txt", 1);
					print BOARDINFO @boardtomodify;
					fclose(BOARDINFO);
				}
			}
		}

		$bname = $FORM{"name$i"};
		&FromChars($bname);
		&ToHTML($bname);

		# If someone has the bright idea of starting a membergroup with a $
		# We need to escape it for them, to prevent us interpreting it as a var...
		$FORM{"viewperms$i"} =~ s~\$~\\\$~g;

		$board{"$id"} = "$bname|$FORM{\"viewperms$i\"}|$FORM{\"show$i\"}";
		$bdescription = $FORM{"description$i"};
		&FromChars($bdescription);
		$bdescription =~ s/\r//g;
		$bdescription =~ s~\n~<br \/>~g;
		if ($do_scramble_id) {
			my @mods;
			foreach (split(', ', $FORM{"moderators$i"})) {
				push(@mods, &decloak($_));
			}
			$FORM{"moderators$i"} = join(', ', @mods);
		}
		if ($FORM{"zero$i"} eq '') { $FORM{"zero$i"} = 0; }
		$FORM{"minage$i"} =~ tr/[0-9]//cd;    ## remove non numbers
		$FORM{"maxage$i"} =~ tr/[0-9]//cd;    ## remove non numbers
		if ($FORM{"minage$i"} < 0)   { $FORM{"minage$i"} = ""; }
		if ($FORM{"maxage$i"} < 0)   { $FORM{"maxage$i"} = ""; }
		if ($FORM{"minage$i"} > 180) { $FORM{"minage$i"} = ""; }
		if ($FORM{"maxage$i"} > 180) { $FORM{"maxage$i"} = ""; }
		if ($FORM{"maxage$i"} && $FORM{"maxage$i"} < $FORM{"minage$i"}) { $FORM{"maxage$i"} = $FORM{"minage$i"}; }

		push(@boardcontrol, "$FORM{\"cat$i\"}|$id|$FORM{\"pic$i\"}|$bdescription|$FORM{\"moderators$i\"}|$FORM{\"moderatorgroups$i\"}|$FORM{\"topicperms$i\"}|$FORM{\"replyperms$i\"}|$FORM{\"pollperms$i\"}|$FORM{\"zero$i\"}|$FORM{\"membergroups$i\"}|$FORM{\"ann$i\"}|$FORM{\"rbin$i\"}|$FORM{\"att$i\"}|$FORM{\"minage$i\"}|$FORM{\"maxage$i\"}|$FORM{\"gender$i\"}\n");
		push(@changes, $id);
		$yymain .= qq~<i>'$FORM{"name$i"}'</i> $admin_txt{'48'} <br />~;
	}

	# do the saving here, after all new boards passed the tests (admin_fatal_error)
	&BoardTotals("add", @changes);

	&Write_ForumMaster;
	fopen(FORUMCONTROL, "+<$boardsdir/forum.control");
	seek FORUMCONTROL, 0, 0;
	my @oldcontrols = <FORUMCONTROL>;
	my $oldboard;
	for (my $cnt = 0; $cnt < @oldcontrols; $cnt++) {
		(undef, $oldboard, undef) = split(/\|/, $oldcontrols[$cnt], 3);
		foreach my $changedboard (@changes) {
			if ($changedboard eq $oldboard) { $oldcontrols[$cnt] = ""; }
		}
	}
	push(@oldcontrols, @boardcontrol);
	@boardcontrol = grep { $_; } @oldcontrols;

	truncate FORUMCONTROL, 0;
	seek FORUMCONTROL, 0, 0;
	print FORUMCONTROL sort(@boardcontrol);
	fclose(FORUMCONTROL);

	$action_area = "manageboards";
	&AdminTemplate;
}

sub ReorderBoards {
	&is_admin_or_gmod;
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	if ($#categoryorder > 0) {
		foreach $category (@categoryorder) {
			chomp $category;
			($categoryname, undef) = split(/\|/, $catinfo{$category});
			&ToChars($categoryname);
			if ($category eq $INFO{"item"}) {
				$categorylistsel = qq~<option value="$category" selected="selected">$categoryname</option>~;
			} else {
				$categorylist .= qq~<option value="$category">$categoryname</option>~;
			}
		}
	}
	@bdlist = split(/,/, $cat{ $INFO{"item"} });
	$bdcnt = @bdlist;
	$bdnum = $bdcnt;
	if ($bdcnt < 4) { $bdcnt = 4; }
	($curcatname, $catperms) = split(/\|/, $catinfo{ $INFO{"item"} });
	&ToChars($curcatname);

	# Prepare the list of current boards to be put in the select box
	$boardslist = qq~<select name="selectboards" id="selectboards" size="$bdcnt" style="width: 190px;">~;
	foreach $board (@bdlist) {
		chomp $board;
		($boardname, undef) = split(/\|/, $board{$board}, 2);
		&ToChars($boardname);
		if ($board eq $INFO{'theboard'}) {
			$boardslist .= qq~<option value="$board" selected="selected">$boardname</option>~;
		} else {
			$boardslist .= qq~<option value="$board">$boardname</option>~;
		}
	}
	$boardslist .= qq~</select>~;

	$yymain .= qq~
<br /><br />
<form action="$adminurl?action=reorderboards2;item=$INFO{'item'}" method="post">
<table border="0" width="525" cellspacing="1" cellpadding="4" class="bordercolor" align="center">
  <tr>
    <td class="titlebg"><img src="$imagesdir/board.gif" alt="" style="vertical-align: middle;" /> <b>$admin_txt{'832'} ($curcatname)</b></td>
  </tr>
  <tr>
    <td class="windowbg" valign="middle" align="left">
~;
	if ($bdnum) {
		$yymain .= qq~
    <div style="float: left; width: 280px; text-align: left; margin-bottom: 4px;" class="small"><label for="selectboards">$admin_txt{'739'}</label></div>
    <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">$boardslist</div>
    <div style="float: left; width: 280px; text-align: left; margin-bottom: 4px;" class="small">$admin_txt{'739d'}</div>
    <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">
	<input type="submit" value="$admin_txt{'739a'}" name="moveup" style="font-size: 11px; width: 95px;" class="button" />
	<input type="submit" value="$admin_txt{'739b'}" name="movedown" style="font-size: 11px; width: 95px;" class="button" />
    </div>
~;
		if ($#categoryorder > 0) {
			$yymain .= qq~
    <div class="small" style="float: left; width: 280px; text-align: left; margin-bottom: 4px;"><label for="selectcategory">$admin_txt{'739c'}</label></div>
    <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">
	<select name="selectcategory" id="selectcategory" style="width: 190px;" onchange="submit();">
	$categorylistsel
	$categorylist
	</select>
    </div>
~;
		}
	} else {
		$yymain .= qq~
    <div class="small" style="text-align: center; margin-bottom: 4px;">$admin_txt{'739e'}</div>
~;
	}
	$yymain .= qq~
    </td>
  </tr>
</table>
</form>
~;
	$yytitle     = "$admin_txt{'832'}";
	$action_area = "manageboards";
	&AdminTemplate;
}

sub ReorderBoards2 {
	&is_admin_or_gmod;
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	@itemorder = split(/,/, $cat{ $INFO{"item"} });
	my $moveitem = $FORM{'selectboards'};
	my $category = $INFO{"item"};
	if ($moveitem) {
		if ($FORM{'moveup'} || $FORM{'movedown'}) {
			if ($FORM{'moveup'}) {
				for ($i = 0; $i < @itemorder; $i++) {
					if ($itemorder[$i] eq $moveitem && $i > 0) {
						$j             = $i - 1;
						$itemorder[$i] = $itemorder[$j];
						$itemorder[$j] = $moveitem;
						last;
					}
				}
			} elsif ($FORM{'movedown'}) {
				for ($i = 0; $i < @itemorder; $i++) {
					if ($itemorder[$i] eq $moveitem && $i < $#itemorder) {
						$j             = $i + 1;
						$itemorder[$i] = $itemorder[$j];
						$itemorder[$j] = $moveitem;
						last;
					}
				}
			}
			$cat{$category} = join(',', grep { $_; } @itemorder);
		} else {
			if ($category ne $FORM{"selectcategory"}) {
				${$uid.$moveitem}{'cat'} = qq~$FORM{'selectcategory'}~;
				my @bdlist = split(/,/, $cat{$category});
				my $k = 0;
				foreach $bd (@bdlist) {
					if ($moveitem eq $bd) { splice(@bdlist, $k, 1); }
					$k++;
				}
				$cat{"$category"} = join(',', @bdlist);
				my $ncat   = $FORM{"selectcategory"};
				if ($cat{$ncat} ne "") { $cat{$ncat} .= ",$moveitem"; }
				else { $cat{$ncat} = $moveitem; }
				$category = qq~$FORM{"selectcategory"}~;
			}
		}
		&Write_ForumMaster;


		fopen(FORUMCONTROL, "+<$boardsdir/forum.control");
		seek FORUMCONTROL, 0, 0;
		my @oldcontrols = <FORUMCONTROL>;
		my $oldboard;
		for (my $cnt = 0; $cnt < @oldcontrols; $cnt++) {
			my (undef, $oldboard,$pic,$bdescription,$moderators,$moderatorgroups,$topicperms,$replyperms,$pollperms,$zero,$membergroups,$ann,$rbin,$att,$minage,$maxage,$gender) = split(/\|/, $oldcontrols[$cnt]);
			if ($moveitem eq $oldboard) {
				$oldcontrols[$cnt] = qq~$category|$moveitem|$pic|$bdescription|$moderators|$moderatorgroups|$topicperms|$replyperms|$pollperms|$zero|$membergroups|$ann|$rbin|$att|$minage|$maxage|$gender~;
			}
		}
		my @boardcontrol = grep { $_; } @oldcontrols;

		truncate FORUMCONTROL, 0;
		seek FORUMCONTROL, 0, 0;
		print FORUMCONTROL sort(@boardcontrol);
		fclose(FORUMCONTROL);

	}
	$yySetLocation = qq~$adminurl?action=reorderboards;item=$category;theboard=$moveitem~;
	&redirectexit;
}

sub ConfRemBoard {
	$yymain .= qq~
<table border="0" width="100%" cellspacing="1" class="bordercolor">
<tr>
	<td class="titlebg"><b>$admin_txt{'31'} - '$FORM{'boardname'}'?</b></td>
</tr>
<tr>
	<td class="windowbg" >
$admin_txt{'617'}<br />
<b><a href="$adminurl?action=modifyboard;cat=$FORM{'cat'};id=$FORM{'id'};moda=$admin_txt{'31'}2">$admin_txt{'163'}</a> - <a href="$adminurl?action=manageboards">$admin_txt{'164'}</a></b>
</td>
</tr>
</table>
~;
	$yytitle     = "$admin_txt{'31'} - '$FORM{'boardname'}'?";
	$action_area = "manageboards";
	&AdminTemplate;
}
1;