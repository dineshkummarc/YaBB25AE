###############################################################################
# MessageIndex.pl                                                             #
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

$messageindexplver = 'YaBB 2.5 AE $Revision: 1.52 $';
if ($action eq 'detailedversion') { return 1; }

&LoadLanguage('MessageIndex');
require "$templatesdir/$usemessage/MessageIndex.template";

sub MessageIndex {
	# Check if board was 'shown to all' - and whether they can view the board
	if (&AccessCheck($currentboard, '', $boardperms) ne "granted") { &fatal_error("no_access"); }
	if ($annboard eq $currentboard && !$iamadmin && !$iamgmod) { &fatal_error("no_access"); }

	my ($counter, $mcount, $buffer, $pages, $showmods, $mnum, $msub, $mname, $memail, $mdate, $mreplies, $musername, $micon, $mstate, $dlp, $threadlength);
	my ($numanns, $threadcount, $countsticky, $countnosticky, $stkynum, @tmpanns, @anns, @threadlist, @stickythreadlist, @nostickythreadlist, @threads);
	&BoardTotals("load", $currentboard);

	# Build a list of the board's moderators.
	if (keys %moderators > 0) {
		if (keys %moderators == 1) { $showmods = qq~($messageindex_txt{'298'}: ~; }
		else { $showmods = qq~($messageindex_txt{'63'}: ~; }

		while ($_ = each(%moderators)) {
			&FormatUserName($_);
			$showmods .= &QuickLinks($_,1) . ", ";
		}
		$showmods =~ s/, \Z/)/;
	}
	if (keys %moderatorgroups > 0) {
		if (keys %moderatorgroups == 1) { $showmodgroups = qq~($messageindex_txt{'298a'}: ~; }
		else { $showmodgroups = qq~($messageindex_txt{'63a'}: ~; }

		my ($tmpmodgrp,$thismodgrp);
		while ($_ = each(%moderatorgroups)) {
			$tmpmodgrp = $moderatorgroups{$_};
			($thismodgrp, undef) = split(/\|/, $NoPost{$tmpmodgrp}, 2);
			$showmodgroups .= qq~$thismodgrp, ~;
		}
		$showmodgroups =~ s/, \Z/)/;
	}
	if ($showmodgroups ne "" && $showmods ne "") { $showmods .= qq~ - ~; }

	# Load announcements, if they exist.
	if ($annboard && $annboard ne $currentboard && ${$uid.$currentboard}{'rbin'} != 1) {
		chomp $annboard;
		fopen(ANN, "$boardsdir/$annboard.txt");
		@tmpanns = <ANN>;
		fclose(ANN);
		foreach my $realanns (@tmpanns) {
			my $threadstatus = (split /\|/, $realanns)[8];
			if ($threadstatus =~ /h/i && !$iamadmin && !$iamgmod && !$iammod) { next; }
			push (@threads, $realanns);
			$numanns++;
		}
		undef @tmpanns;
	}

	# Determine what category we are in.
	$catid = ${$uid.$currentboard}{'cat'};
	($cat, undef) = split(/\|/, $catinfo{$catid});
	&ToChars($cat);

	fopen(BRDTXT, "$boardsdir/$currentboard.txt") || &fatal_error("cannot_open","$boardsdir/$currentboard.txt", 1);
	@threadlist = <BRDTXT>;
	fclose(BRDTXT);
	foreach my $threadlist (@threadlist) {
		my $threadstatus = (split /\|/, $threadlist)[8];
		if ($threadstatus =~ /h/i && !$iamadmin && !$iamgmod && !$iammod) { next; }
		if ($threadstatus =~ /s/i) {
			push (@threads, $threadlist);
			$countsticky++;
		} else {
			$nostickythreadlist[$threadcount] = $threadlist;
			$threadcount++;
		}
	}
	undef @threadlist;

	$threadcount = $threadcount + $countsticky + $numanns;
	my $maxindex = $INFO{'view'} eq 'all' ? $threadcount : $maxdisplay;

	# There are three kinds of lies: lies, damned lies, and statistics.
	# - Mark Twain

	# Construct the page links for this board.
	if (!$iamguest) { ($usermessagepage, undef, undef, undef) = split(/\|/, ${$uid.$username}{'pageindex'}); }
	my ($pagetxtindex, $pagetextindex, $pagedropindex1, $pagedropindex2, $all, $allselected);
	$indexdisplaynum = 3;              # max number of pages to display
	$dropdisplaynum  = 10;
	$startpage = 0;
	$max = $threadcount;
	if (substr($INFO{'start'}, 0, 3) eq 'all' && $showpageall != 0) { $maxindex = $max; $all = 1; $allselected = qq~ selected="selected"~; $start = 0; }
	else { $start = $INFO{'start'} || 0; }
	if ($start > $threadcount - 1) { $start = $threadcount - 1; }
	elsif ($start < 0) { $start = 0; }
	$start    = int($start / $maxindex) * $maxindex;
	$tmpa     = 1;
	$pagenumb = int(($threadcount - 1) / $maxindex) + 1;

	if ($start >= (($indexdisplaynum - 1) * $maxindex)) {
		$startpage = $start - (($indexdisplaynum - 1) * $maxindex);
		$tmpa = int($startpage / $maxindex) + 1;
	}
	if ($threadcount >= $start + ($indexdisplaynum * $maxindex)) { $endpage = $start + ($indexdisplaynum * $maxindex); }
	else { $endpage = $threadcount }
	$lastpn = int(($threadcount - 1) / $maxindex) + 1;
	$lastptn = ($lastpn - 1) * $maxindex;
	$pageindex1 = qq~<span class="small" style="float: left; height: 21px; margin: 0px; margin-top: 2px;"><img src="$imagesdir/index_togl.gif" border="0" alt="$messageindex_txt{'19'}" title="$messageindex_txt{'19'}" style="vertical-align: middle;" /> $messageindex_txt{'139'}: $pagenumb</span>~;
	$pageindex2 = $pageindex1;
	if ($pagenumb > 1 || $all) {

		if ($usermessagepage == 1 || $iamguest) {
			$pagetxtindexst = qq~<span class="small" style="float: left; height: 21px; margin: 0px; margin-top: 2px;">~;
			if (!$iamguest) { $pagetxtindexst .= qq~<a href="$scripturl?board=$INFO{'board'};start=$start;action=messagepagedrop"><img src="$imagesdir/index_togl.gif" border="0" alt="$messageindex_txt{'19'}" title="$messageindex_txt{'19'}" style="vertical-align: middle;" /></a> $messageindex_txt{'139'}: ~; }
			else { $pagetxtindexst .= qq~<img src="$imagesdir/index_togl.gif" border="0" alt="$messageindex_txt{'139'}" title="$messageindex_txt{'139'}" style="vertical-align: middle;" /> $messageindex_txt{'139'}: ~; }
			if ($startpage > 0) { $pagetxtindex = qq~<a href="$scripturl?board=$currentboard/0" style="font-weight: normal;">1</a>&nbsp;<a href='javascript: void(0);' onclick='ListPages2("$currentboard","$threadcount");'>...</a>&nbsp;~; }
			if ($startpage == $maxindex) { $pagetxtindex = qq~<a href="$scripturl?board=$currentboard/0" style="font-weight: normal;">1</a>&nbsp;~; }
			for ($counter = $startpage; $counter < $endpage; $counter += $maxindex) {
				$pagetxtindex .= $start == $counter ? qq~<b>$tmpa</b>&nbsp;~ : qq~<a href="$scripturl?board=$currentboard/$counter" style="font-weight: normal;">$tmpa</a>&nbsp;~;
				$tmpa++;
			}
			if ($endpage < $threadcount - $maxindex) { $pageindexadd = qq~<a href='javascript: void(0);' onclick='ListPages2("$currentboard","$threadcount");'>...</a>&nbsp;~; }
			if ($endpage != $threadcount) { $pageindexadd .= qq~<a href="$scripturl?board=$currentboard/$lastptn" style="font-weight: normal;">$lastpn</a>~; }

			$pagetxtindex .= $pageindexadd;
			$pageindex1 = qq~$pagetxtindexst $pagetxtindex</span>~;
			$pageindex2 = $pageindex1;
		} else {
			$pagedropindex1 = qq~<span style="float: left; width: 350px; margin: 0px; margin-top: 2px; border: 0px;">~;
			$pagedropindex1 .= qq~<span style="float: left; height: 21px; margin: 0; margin-right: 4px;"><a href="$scripturl?board=$INFO{'board'};start=$start;action=messagepagetext"><img src="$imagesdir/index_togl.gif" border="0" alt="$messageindex_txt{'19'}" title="$messageindex_txt{'19'}" /></a></span>~;
			$pagedropindex2 = $pagedropindex1;
			$tstart = $start;
			#if (substr($INFO{'start'}, 0, 3) eq "all") { ($tstart, $start) = split(/\-/, $INFO{'start'}); }
			$d_indexpages = $pagenumb / $dropdisplaynum;
			$i_indexpages = int($pagenumb / $dropdisplaynum);
			if ($d_indexpages > $i_indexpages) { $indexpages = int($pagenumb / $dropdisplaynum) + 1; }
			else { $indexpages = int($pagenumb / $dropdisplaynum) }
			$selectedindex = int(($start / $maxindex) / $dropdisplaynum);

			if ($pagenumb > $dropdisplaynum) {
				$pagedropindex1 .= qq~<span style="float: left; height: 21px; margin: 0;"><select size="1" name="decselector1" id="decselector1" style="font-size: 9px; border: 2px inset;" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
				$pagedropindex2 .= qq~<span style="float: left; height: 21px; margin: 0;"><select size="1" name="decselector2" id="decselector2" style="font-size: 9px; border: 2px inset;" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
			}
			for ($i = 0; $i < $indexpages; $i++) {
				$indexpage = ($i * $dropdisplaynum) * $maxindex;

				$indexstart = ($i * $dropdisplaynum) + 1;
				$indexend = $indexstart + ($dropdisplaynum - 1);
				if ($indexend > $pagenumb)    { $indexend   = $pagenumb; }
				if ($indexstart == $indexend) { $indxoption = qq~$indexstart~; }
				else { $indxoption = qq~$indexstart-$indexend~; }
				$selected = "";
				if ($i == $selectedindex) {
					$selected = qq~ selected="selected"~;
					$pagejsindex = qq~$indexstart|$indexend|$maxindex|$indexpage~;
				}
				if ($pagenumb > $dropdisplaynum) {
					$pagedropindex1 .= qq~<option value="$indexstart|$indexend|$maxindex|$indexpage"$selected>$indxoption</option>\n~;
					$pagedropindex2 .= qq~<option value="$indexstart|$indexend|$maxindex|$indexpage"$selected>$indxoption</option>\n~;
				}
			}
			if ($pagenumb > $dropdisplaynum) {
				$pagedropindex1 .= qq~</select>\n</span>~;
				$pagedropindex2 .= qq~</select>\n</span>~;
			}
			$pagedropindex1 .= qq~<span id="ViewIndex1" class="droppageindex" style="height: 14px; visibility: hidden">&nbsp;</span>~;
			$pagedropindex2 .= qq~<span id="ViewIndex2" class="droppageindex" style="height: 14px; visibility: hidden">&nbsp;</span>~;
			$tmpmaxindex = $maxindex;
			#if (substr($INFO{'start'}, 0, 3) eq "all") { $maxindex = $maxindex * $dropdisplaynum; }
			$prevpage = $start - $tmpmaxindex;
			$nextpage = $start + $maxindex;
			$pagedropindexpvbl = qq~<img src="$imagesdir/index_left0.gif" height="14" width="13" border="0" alt="" style="margin: 0px; display: inline; vertical-align: middle;" />~;
			$pagedropindexnxbl = qq~<img src="$imagesdir/index_right0.gif" height="14" width="13" border="0" alt="" style="margin: 0px; display: inline; vertical-align: middle;" />~;
			if ($start < $maxindex) { $pagedropindexpv .= qq~<img src="$imagesdir/index_left0.gif" height="14" width="13" border="0" alt="" style="display: inline; vertical-align: middle;" />~; }
			else { $pagedropindexpv .= qq~<img src="$imagesdir/index_left.gif" border="0" height="14" width="13" alt="$pidtxt{'02'}" title="$pidtxt{'02'}" style="display: inline; vertical-align: middle; cursor: pointer;" onclick="location.href=\\'$scripturl?board=$currentboard/$prevpage\\'" ondblclick="location.href=\\'$scripturl?board=$currentboard/0\\'" />~; }
			if ($nextpage > $lastptn) { $pagedropindexnx .= qq~<img src="$imagesdir/index_right0.gif" border="0" height="14" width="13" alt="" style="display: inline; vertical-align: middle;" />~; }
			else { $pagedropindexnx .= qq~<img src="$imagesdir/index_right.gif" height="14" width="13" border="0" alt="$pidtxt{'03'}" title="$pidtxt{'03'}" style="display: inline; vertical-align: middle; cursor: pointer;" onclick="location.href=\\'$scripturl?board=$currentboard/$nextpage\\'" ondblclick="location.href=\\'$scripturl?board=$currentboard/$lastptn\\'" />~; }
			$pageindex1 = qq~$pagedropindex1</span>~;
			$pageindex2 = qq~$pagedropindex2</span>~;

			$pageindexjs = qq~
<script language="JavaScript1.2" type="text/javascript">
<!-- 
	function SelDec(decparam, visel) {
		splitparam = decparam.split("|");
		var vistart = parseInt(splitparam[0]);
		var viend = parseInt(splitparam[1]);
		var maxpag = parseInt(splitparam[2]);
		var pagstart = parseInt(splitparam[3]);
		//var allpagstart = parseInt(splitparam[3]);
		if (visel == 'xx' && decparam == '$pagejsindex') visel = '$tstart';
		var pagedropindex = '<table border="0" cellpadding="0" cellspacing="0"><tr>';
		for(i=vistart; i<=viend; i++) {
			if (visel == pagstart) pagedropindex += '<td class="titlebg" height="14" style="height: 14px; padding-left: 1px; padding-right: 1px; font-size: 9px; font-weight: bold;">' + i + '</td>';
			else pagedropindex += '<td height="14" class="droppages"><a href="$scripturl?board=$currentboard/' + pagstart + '">' + i + '</a></td>';
			pagstart += maxpag;
		}
		~;
		if ($showpageall) {
			$pageindexjs .= qq~
			if (vistart != viend) {
				if(visel == 'all') pagedropindex += '<td class="titlebg" height="14" style="height: 14px; padding-left: 1px; padding-right: 1px; font-size: 9px; font-weight: normal;"><b>$pidtxt{'01'}</b></td>';
				else pagedropindex += '<td height="14" class="droppages"><a href="$scripturl?board=$currentboard/all">$pidtxt{'01'}</a></td>';
			}
			~;
		}
		$pageindexjs .= qq~
		if(visel != 'xx') pagedropindex += '<td height="14" class="small" style="height: 14px; padding-left: 4px;">$pagedropindexpv$pagedropindexnx</td>';
		else pagedropindex += '<td height="14" class="small" style="height: 14px; padding-left: 4px;">$pagedropindexpvbl$pagedropindexnxbl</td>';
		pagedropindex += '</tr></table>';
		document.getElementById("ViewIndex1").innerHTML=pagedropindex;
		document.getElementById("ViewIndex1").style.visibility = "visible";
		document.getElementById("ViewIndex2").innerHTML=pagedropindex;
		document.getElementById("ViewIndex2").style.visibility = "visible";
		~;
			if ($pagenumb > $dropdisplaynum) {
				$pageindexjs .= qq~
		document.getElementById("decselector1").value = decparam;
		document.getElementById("decselector2").value = decparam;
		~;
			}
			$pageindexjs .= qq~
	}
	document.onload = SelDec('$pagejsindex', '$tstart');
//-->
</script>
~;
		}
	}

	if ($start <= $#threads) { $stkynum = scalar @threads; }
	push (@threads, @nostickythreadlist);
	undef @nostickythreadlist;
	@threads = splice(@threads, $start, $maxindex);
	chomp @threads;

	my %attachments;
	if (-s "$vardir/attachments.txt" > 5) {
		fopen(ATM, "$vardir/attachments.txt");
		while (<ATM>) {
			$attachments{(split(/\|/, $_, 2))[0]}++;
		}
		fclose(ATM);
	}

	&LoadCensorList;

	# Print the header and board info.
	&ToChars($boardname);
	if ((($iammod && $modview == 1 && !$iamadmin && !$iamgmod) || ($iamadmin && $adminview == 1) || ($iamgmod && $gmodview == 1)) && $sessionvalid == 1) {
		$yymain .= qq~<script language="JavaScript1.2" src="$yyhtml_root/ubbc.js" type="text/javascript"></script>~;
	}

	my $homelink = qq~<a href="$scripturl">$mbname</a>~;
	my $catlink = qq~<a href="$scripturl?catselect=$catid">$cat</a>~;
	my $boardlink = qq~<a href="$scripturl?board=$currentboard" class="a"><b>$boardname</b></a>~;
	my $modslink = qq~$showmods~;

	# check howmany col's must be spanned
	if ((($iamadmin && $adminview >= 1) || ($iamgmod && $gmodview >= 1) || ($iammod && $modview >= 1 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
		$colspan = 8;
	} else {
		$colspan = 7;
	}

	if (!$iamguest) {
		$markalllink = qq~$menusep<a href="javascript:MarkAllAsRead('$scripturl?board=$INFO{'board'};action=markasread','$imagesdir')">$img{'markboardread'}</a>~;
		$notify_board = qq~$menusep<a href="$scripturl?action=boardnotify;board=$INFO{'board'}">$img{'notify'}</a>~;
	}

	if (&AccessCheck($currentboard, 1) eq "granted") {
		# when Quick-Post and Quick-Jump: focus message first, then the subject to have a better display
		$postlink = qq~$menusep<a href="~ . ($enable_quickpost && $enable_quickjump ? 'javascript:document.postmodify.message.focus();document.postmodify.subject.focus();' : qq~$scripturl?board=$INFO{'board'};action=post;title=StartNewTopic~) . qq~">$img{'newthread'}</a>~;
	}
	if (&AccessCheck($currentboard, 3) eq "granted") {
		$polllink = qq~$menusep<a href="$scripturl?board=$INFO{'board'};action=post;title=CreatePoll">$img{'createpoll'}</a>~;
	}

	if ((($iamadmin && $adminview == 3) || ($iamgmod && $gmodview == 3) || ($iammod && $modview == 3 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
		if ($currentboard eq $annboard) {
			$adminlink = qq~<img src="$imagesdir/announcementlock.gif" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}" border="0" /><img src="$imagesdir/hide.gif" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}" border="0" /><img src="$imagesdir/admin_move.gif" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}" border="0" /><img src="$imagesdir/admin_rem.gif" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}" border="0" />~;
		} else {
			$adminlink = qq~<img src="$imagesdir/locked.gif" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}" border="0" /><img src="$imagesdir/sticky.gif" alt="$messageindex_txt{'781'}" title="$messageindex_txt{'781'}" border="0" /><img src="$imagesdir/hide.gif" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}" border="0" /><img src="$imagesdir/admin_move.gif" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}" border="0" /><img src="$imagesdir/admin_rem.gif" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}" border="0" />~;
		}
		$adminheader =~ s/({|<)yabb admin(}|>)/$adminlink/g;
	} elsif ((($iamadmin && $adminview != 0) || ($iamgmod && $gmodview != 0) || ($iammod && $modview != 0 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
		$adminlink = qq~$messageindex_txt{'2'}~;
		$adminheader =~ s/({|<)yabb admin(}|>)/$adminlink/g;
	}

	# check to display moderator column
	my $tmpstickyheader;
	if ($stkynum) {
		$stickyheader =~ s/({|<)yabb colspan(}|>)/$colspan/g;
		$tmpstickyheader = $stickyheader;
	}

	# load Favorites in a hash
	if (${$uid.$username}{'favorites'}) { foreach (split(/,/, ${$uid.$username}{'favorites'})) { $favicon{$_} = 1; } }

	# Begin printing the message index for current board.
	$counter = $start;
	&dumplog($currentboard); # Mark current board as seen
	my $dmax = $date - ($max_log_days_old * 86400);
	foreach (@threads) {
		($mnum, $msub, $mname, $memail, $mdate, $mreplies, $musername, $micon, $mstate) = split(/\|/, $_);

		&MessageTotals('load', $mnum);

		my $goodboard = $mstate =~ /a/i ? $annboard : $currentboard;
		if (${$mnum}{'board'} ne $goodboard) {
			${$mnum}{'board'} = $goodboard if $goodboard;
			&MessageTotals('recover', $mnum);
		}

		$permlinkboard = ${$mnum}{'board'} eq $annboard ? $annboard : $currentboard;
		my $permdate = &permtimer($_);
		my $message_permalink = qq~<a href="http://$perm_domain/$symlink$permdate/$permlinkboard/$mnum">$messageindex_txt{'10'}</a>~;

		$threadclass = 'thread';
		if ($mstate =~ /h/i) { $threadclass = 'hide'; }
		elsif ($mstate =~ /l/i) { $threadclass = 'locked'; }
		elsif ($mreplies >= $VeryHotTopic) { $threadclass = 'veryhotthread'; }
		elsif ($mreplies >= $HotTopic) { $threadclass = 'hotthread'; }
		elsif ($mstate == '') { $threadclass = 'thread'; }
		if ($threadclass eq 'hide' && $mstate =~ /s/i && $mstate !~ /l/i) { $threadclass = 'hidesticky'; }
		elsif ($threadclass eq 'hide' && $mstate =~ /l/i && $mstate !~ /s/i) { $threadclass = 'hidelock'; }
		elsif ($threadclass eq 'hide' && $mstate =~ /s/i && $mstate =~ /l/i) { $threadclass = 'hidestickylock'; }
		elsif ($threadclass eq 'locked' && $mstate =~ /s/i && $mstate !~ /h/i) { $threadclass = 'stickylock'; }
		elsif ($mstate =~ /s/i && $mstate !~ /h/i) { $threadclass = 'sticky'; }
		elsif (${$mnum}{'board'} eq $annboard && $mstate !~ /h/i) { $threadclass = $threadclass eq 'locked' ? 'announcementlock' : 'announcement'; }

		my ($movedSubject, $movedFlag) = &Split_Splice_Move($msub,$mnum);
		$threadclass = 'locked_moved' if $movedFlag;

		if (!$iamguest && $max_log_days_old) {
			# Decide if thread should have the "NEW" indicator next to it.
			# Do this by reading the user's log for last read time on thread,
			# and compare to the last post time on the thread.
			$dlp = int($yyuserlog{$mnum}) > int($yyuserlog{"$currentboard--mark"}) ? int($yyuserlog{$mnum}) : int($yyuserlog{"$currentboard--mark"});
			if (!$movedFlag && ($yyuserlog{"$mnum--unread"} || (!$dlp && $mdate > $dmax) || ($dlp > $dmax && $dlp < $mdate))) {
				if (${$mnum}{'board'} eq $annboard) {
					$new = qq~<a href="$scripturl?virboard=$currentboard;num=$mnum/new#new"><img src="$imagesdir/new.gif" alt="$messageindex_txt{'302'}" title="$messageindex_txt{'302'}" border="0"/></a>~;
				} else {
					$new = qq~<a href="$scripturl?num=$mnum/new#new"><img src="$imagesdir/new.gif" alt="$messageindex_txt{'302'}" title="$messageindex_txt{'302'}" border="0"/></a>~;
				}
			} else {
				$new = '';
			}
		}

		$micon = qq~<img src="$imagesdir/$micon.gif" alt="" border="0" align="middle" />~;
		$mpoll = "";
		if (-e "$datadir/$mnum.poll") {
			$mpoll = qq~<b>$messageindex_txt{'15'}: </b>~;
			fopen(POLL, "$datadir/$mnum.poll");
			my @poll = <POLL>;
			fclose(POLL);
			my ($poll_question, $poll_locked, $poll_uname, $poll_name, $poll_email, $poll_date, $guest_vote, $hide_results, $multi_vote, $poll_mod, $poll_modname, $poll_comment, $vote_limit, $pie_radius, $pie_legends, $poll_end) = split(/\|/, $poll[0]);
			chomp $poll_end;
			if ($poll_end && !$poll_locked && $poll_end < $date) {
				$poll_locked = 1;
				$poll_end = '';
				$poll[0] = "$poll_question|$poll_locked|$poll_uname|$poll_name|$poll_email|$poll_date|$guest_vote|$hide_results|$multi_vote|$poll_mod|$poll_modname|$poll_comment|$vote_limit|$pie_radius|$pie_legends|$poll_end\n";
				fopen(POLL, ">$datadir/$mnum.poll");
				print POLL @poll;
				fclose(POLL);
			}
			$micon = qq~$img{'pollicon'}~;
			if ($poll_locked) { $micon = $img{'polliconclosed'}; }
			elsif (!$iamguest && $max_log_days_old && $mdate > $date - ($max_log_days_old * 86400)) {
				if ($dlp < $createpoll_date) {
					$micon = qq~$img{'polliconnew'}~;
				} else {
					fopen(POLLED, "$datadir/$mnum.polled");
					$polled = <POLLED>;
					fclose(POLLED);
					(undef, undef, undef, $vote_date, undef) = split(/\|/, $polled);
					if ($dlp < $vote_date) { $micon = qq~$img{'polliconnew'}~; }
				}
			}
		}

		# Load the current nickname of the account name of the thread starter.
		if ($musername ne 'Guest') {
			&LoadUser($musername);
			# See if they are an ex-member.
			if ((${$uid.$musername}{'regdate'} && $mdate > ${$uid.$musername}{'regtime'}) || ${$uid.$musername}{'position'} eq "Administrator" || ${$uid.$musername}{'position'} eq "Global Moderator") {
				$mname = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">${$uid.$musername}{'realname'}</a>~;
			} else {
				$mname .= qq~ ($messageindex_txt{'470a'})~;
			}
		} else {
			$mname .= " ($maintxt{'28'})";
		}

		# Build the page links list.
		my ($pages, $pagesall);
		if ($showpageall) { $pagesall = qq~<a href="$scripturl?num=$mnum/all">$pidtxt{'01'}</a>~; }
		if (int(($mreplies + 1) / $maxmessagedisplay) > 6) {
			$pages = qq~ <a href="$scripturl?num=$mnum/~ . (!$ttsreverse ? "0#0" : "$mreplies#$mreplies") . qq~">1</a>~;
			$pages .= qq~ <a href="$scripturl?num=$mnum/~ . (!$ttsreverse ? "$maxmessagedisplay#$maxmessagedisplay" : ($mreplies - $maxmessagedisplay) . '#' . ($mreplies - $maxmessagedisplay)) . qq~">2</a>~;
			$endpage = int($mreplies / $maxmessagedisplay) + 1;
			$i = ($endpage - 1) * $maxmessagedisplay;
			$j = $i - $maxmessagedisplay;
			$k = $endpage - 1;
			$tmpa = $endpage - 2;
			$tmpb = $j - $maxmessagedisplay;
			$pages .= qq~ <a href="javascript:void(0);" onclick="ListPages($mnum);">...</a>~;
			$pages .= qq~ <a href="$scripturl?num=$mnum/~ . (!$ttsreverse ? "$tmpb#$tmpb" : ($mreplies - $tmpb) . '#' . ($mreplies - $tmpb)) . qq~">$tmpa</a>~;
			$pages .= qq~ <a href="$scripturl?num=$mnum/~ . (!$ttsreverse ? "$j#$j" : ($mreplies - $j) . '#' . ($mreplies - $j)) . qq~">$k</a>~;
			$pages .= qq~ <a href="$scripturl?num=$mnum/~ . (!$ttsreverse ? "$i#$i" : ($mreplies - $i) . '#' . ($mreplies - $i)) . qq~">$endpage</a>~;
			$pages = qq~<br /><span class="small">&#171; $messageindex_txt{'139'} $pages $pagesall &#187;</span>~;
		} elsif ($mreplies + 1 > $maxmessagedisplay) {
			$tmpa = 1;
			for ($tmpb = 0; $tmpb < $mreplies + 1; $tmpb += $maxmessagedisplay) {
				$pages .= qq~<a href="$scripturl?num=$mnum/~ . (!$ttsreverse ? "$tmpb#$tmpb" : ($mreplies - $tmpb) . '#' . ($mreplies - $tmpb)) . qq~">$tmpa</a>\n~;
				++$tmpa;
			}
			$pages =~ s/\n\Z//;
			$pages = qq~<br /><span class="small">&#171; $messageindex_txt{'139'} $pages $pagesall &#187;</span>~;
		}

		# build number of views
		my $views = ${$mnum}{'views'} ? ${$mnum}{'views'} - 1 : 0;
		$lastposter = ${$mnum}{'lastposter'};
		if ($lastposter =~ m~\AGuest-(.*)~) {
			$lastposter = $1 . " ($maintxt{'28'})";
		} else {
			&LoadUser($lastposter);
			if ((${$uid.$lastposter}{'regdate'} && ${$mnum}{'lastpostdate'} > ${$uid.$lastposter}{'regtime'}) || ${$uid.$lastposter}{'position'} eq "Administrator" || ${$uid.$lastposter}{'position'} eq "Global Moderator") {
				$lastposter = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$lastposter}">${$uid.$lastposter}{'realname'}</a>~;
			} else {
				# Need to load thread to see lastposters DISPLAYname if is Ex-Member
				fopen(EXMEMBERTHREAD, "$datadir/$mnum.txt") || &fatal_error('cannot_open', "$datadir/$mnum.txt", 1);
				my @x = <EXMEMBERTHREAD>;
				fclose(EXMEMBERTHREAD);
				$lastposter = (split(/\|/, $x[$#x], 3))[1] . " - $messageindex_txt{'470a'}";
			}
		}
		$lastpostername = $lastposter || $messageindex_txt{'470'};

		if (($stkynum && ($counter >= $stkynum)) && ($stkyshowed < 1)) {
			$nonstickyheader =~ s/({|<)yabb colspan(}|>)/$colspan/g;
			$tmptempbar .= $nonstickyheader;
			$stkyshowed = 1;
		}

		# Check if the thread contains attachments and create a paper-clip icon if it does
		my $alt = $attachments{$mnum} == 1 ? $messageindex_txt{'5'} : $messageindex_txt{'4'};
		$temp_attachment = $attachments{$mnum} ?
			(($guest_media_disallowed && $iamguest) ?
				qq~<img src="$imagesdir/paperclip.gif" alt="$messageindex_txt{'3'} $attachments{$mnum} $alt" title="$messageindex_txt{'3'} $attachments{$mnum} $alt" />~ : 
				qq~<a href="javascript:void(window.open('$scripturl?action=viewdownloads;thread=$mnum','_blank','width=800,height=650,scrollbars=yes,resizable=yes,menubar=no,toolbar=no,top=150,left=150'))">~ . qq~<img src="$imagesdir/paperclip.gif" alt="$messageindex_txt{'3'} $attachments{$mnum} $alt" title="$messageindex_txt{'3'} $attachments{$mnum} $alt" style="border-style:none;" /></a>~) :
			"";

		$mcount++;
		# Print the thread info.
		$mydate = &timeformat($mdate);
		if ((($iamadmin && $adminview == 3) || ($iamgmod && $gmodview == 3) || ($iammod && $modview == 3 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
			if ($currentboard eq $annboard) {
				$adminbar = qq~
		<input type="checkbox" name="lockadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		<input type="checkbox" name="hideadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		<input type="checkbox" name="moveadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		<input type="checkbox" name="deleteadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		~;
			} elsif ($counter < $numanns) {
				$adminbar = qq~&nbsp;~;
			} else {
				$adminbar = qq~
		<input type="checkbox" name="lockadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		<input type="checkbox" name="stickadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		<input type="checkbox" name="hideadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		<input type="checkbox" name="moveadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		<input type="checkbox" name="deleteadmin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />
		~;
			}
			$admincol = $admincolumn;
			$admincol =~ s/({|<)yabb admin(}|>)/$adminbar/g;
		} elsif ((($iamadmin && $adminview == 2) || ($iamgmod && $gmodview == 2) || ($iammod && $modview == 2 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
			if ($currentboard ne $annboard && $counter < $numanns) {
				$adminbar = qq~&nbsp;~;
			} else {
				$adminbar = qq~<input type="checkbox" name="admin$mcount" class="windowbg" style="border: 0px;" value="$mnum" />~;
			}
			$admincol = $admincolumn;
			$admincol =~ s/({|<)yabb admin(}|>)/$adminbar/g;
		} elsif ((($iamadmin && $adminview == 1) || ($iamgmod && $gmodview == 1) || ($iammod && $modview == 1 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
			if ($currentboard eq $annboard) {
				$adminbar = qq~
		<a href="$scripturl?action=lock;thread=$mnum;tomessageindex=1"><img src="$imagesdir/announcementlock.gif" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}" border="0" /></a>&nbsp;
		<a href="$scripturl?action=hide;thread=$mnum;tomessageindex=1"><img src="$imagesdir/hide.gif" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}" border="0" /></a>&nbsp;
		<a href="javascript:void(window.open('$scripturl?action=split_splice;board=$currentboard;thread=$mnum;oldposts=all;leave=0;newcat=${$uid.$currentboard}{'cat'};newboard=$currentboard;position=end','_blank','width=800,height=650,scrollbars=yes,resizable=yes,menubar=no,toolbar=no,top=150,left=150'))"><img src="$imagesdir/admin_move.gif" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}" border="0" /></a>&nbsp;
		<a href="$scripturl?action=removethread;thread=$mnum" onclick="return confirm('$messageindex_txt{'162'}')"><img src="$imagesdir/admin_rem.gif" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}" border="0" /></a>
		~;
			} elsif ($counter < $numanns) {
				$adminbar = qq~&nbsp;~;
			} else {
				$adminbar = qq~
		<a href="$scripturl?action=lock;thread=$mnum;tomessageindex=1"><img src="$imagesdir/locked.gif" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}" border="0" /></a>&nbsp;
		<a href="$scripturl?action=sticky;thread=$mnum"><img src="$imagesdir/sticky.gif" alt="$messageindex_txt{'781'}" title="$messageindex_txt{'781'}" border="0" /></a>&nbsp;
		<a href="$scripturl?action=hide;thread=$mnum;tomessageindex=1"><img src="$imagesdir/hide.gif" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}" border="0" /></a>&nbsp;
		<a href="javascript:void(window.open('$scripturl?action=split_splice;board=$currentboard;thread=$mnum;oldposts=all;leave=0;newcat=${$uid.$currentboard}{'cat'};newboard=$currentboard;position=end','_blank','width=800,height=650,scrollbars=yes,resizable=yes,menubar=no,toolbar=no,top=150,left=150'))"><img src="$imagesdir/admin_move.gif" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}" border="0" /></a>&nbsp;
		<a href="$scripturl?action=removethread;thread=$mnum" onclick="return confirm('$messageindex_txt{'162'}')"><img src="$imagesdir/admin_rem.gif" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}" border="0" /></a>
		~;
			}
			$admincol = $admincolumn;
			$admincol =~ s/({|<)yabb admin(}|>)/$adminbar/g;
		}

		$msub = &Censor($msub);
		&ToChars($msub);
		if(!$movedFlag) {
			if (${$mnum}{'board'} eq $annboard) {
				$msublink = qq~<a href="$scripturl?virboard=$currentboard;num=$mnum">$msub</a>~;
			} else {
				$msublink = qq~<a href="$scripturl?num=$mnum">$msub</a>~;
			}
		} elsif ($movedFlag < 100) {
			&Split_Splice_Move($msub,0);
			$msublink = qq~$msub<br /><span class="small">$movedSubject</span>~;
		} else {
			$msub =~ /^(Re: )?\[m.*?\]: '(.*)'/; # newer then code in &Split_Splice_Move
			$msublink = qq~$maintxt{'758'}: '<a href="$scripturl?num=$movedFlag">$2</a>'<br /><span class="small">$movedSubject</span>~;
		}

		my $tempbar = $movedFlag ? $threadbarMoved : $threadbar;
		$tempbar =~ s/({|<)yabb admin column(}|>)/$admincol/g;
		$tempbar =~ s/({|<)yabb threadpic(}|>)/<img src="$imagesdir\/$threadclass.gif" alt="" \/>/g;
		$tempbar =~ s/({|<)yabb icon(}|>)/$micon/g;
		$tempbar =~ s/({|<)yabb new(}|>)/$new/g;
		$tempbar =~ s/({|<)yabb poll(}|>)/$mpoll/g;
		$tempbar =~ s/({|<)yabb favorite(}|>)/ ($favicon{$mnum} ? qq~<img src="$imagesdir\/addfav.gif" alt="$img_txt{'70'}" title="$img_txt{'70'}" \/>~ : '') /eg;
		$tempbar =~ s/({|<)yabb subjectlink(}|>)/$msublink/g;
		$tempbar =~ s/({|<)yabb attachmenticon(}|>)/$temp_attachment/g;
		$tempbar =~ s/({|<)yabb pages(}|>)/$pages/g;
		$tempbar =~ s/({|<)yabb starter(}|>)/$mname/g;
		$tempbar =~ s/({|<)yabb replies(}|>)/ &NumberFormat($mreplies) /eg;
		$tempbar =~ s/({|<)yabb views(}|>)/ &NumberFormat($views) /eg;
		$tempbar =~ s/({|<)yabb lastpostlink(}|>)/<a href="$scripturl?num=$mnum\/$mreplies#$mreplies">$img{'lastpost'} $mydate<\/a>/g;
		$tempbar =~ s/({|<)yabb lastposter(}|>)/$lastpostername/g;
		if($accept_permalink == 1) {
			$tempbar =~ s/({|<)yabb permalink(}|>)/$message_permalink/g;
		} else {
			$tempbar =~ s/({|<)yabb permalink(}|>)//g;
		}
		$tmptempbar .= $tempbar;
		$counter++;
	}

	# Put a "no messages" message if no threads exisit - just a  bit more friendly...
	if (!$tmptempbar) {
		$tmptempbar = qq~
		<tr>
			<td class="windowbg2" valign="middle" align="center" colspan="$colspan"><br />$messageindex_txt{'841'}<br /><br /></td>
		</tr>
		~;
	}

	my $multiview = 0;
	my $tmptempfooter;
	if    ((($iamadmin && $adminview == 3) || ($iamgmod && $gmodview == 3) || ($iammod && $modview == 3 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) { $multiview = 3; }
	elsif ((($iamadmin && $adminview == 2) || ($iamgmod && $gmodview == 2) || ($iammod && $modview == 2 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) { $multiview = 2; }

	if ($multiview >= 2) {
		my $boardlist = &moveto;
		if ($multiview eq '3') {
			$tempfooter    = $subfooterbar;
			$adminselector = qq~
				<label for="toboard">$messageindex_txt{'133'}</label>: <input type="checkbox" name="newinfo" value="1" title="$messageindex_txt{199}" class="titlebg" style="border: 0px;" ondblclick="alert('$messageindex_txt{200}')" /> <select name="toboard" id="toboard">$boardlist</select><input type="submit" value="$messageindex_txt{'462'}" class="button" />
			~;
			if ($currentboard eq $annboard) {
				$admincheckboxes = qq~
				<input type="checkbox" name="lockall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(1); else uncheckAll(1);" />
				<input type="checkbox" name="hideall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(2); else uncheckAll(2);" />
				<input type="checkbox" name="moveall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(3); else uncheckAll(3);" />
				<input type="checkbox" name="deleteall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(4); else uncheckAll(4);" />
				<input type="hidden" name="fromboard" value="$currentboard" />
			~;
			} else {
				$admincheckboxes = qq~
				<input type="checkbox" name="lockall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(1); else uncheckAll(1);" />
				<input type="checkbox" name="stickall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(2); else uncheckAll(2);" />
				<input type="checkbox" name="hideall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(3); else uncheckAll(3);" />
				<input type="checkbox" name="moveall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(4); else uncheckAll(4);" />
				<input type="checkbox" name="deleteall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(5); else uncheckAll(5);" />
				<input type="hidden" name="fromboard" value="$currentboard" />
			~;
			}
			$tempfooter =~ s/({|<)yabb admin selector(}|>)/$adminselector/g;
			$tempfooter =~ s/({|<)yabb admin checkboxes(}|>)/$admincheckboxes/g;
		} elsif ($multiview eq '2') {
			$tempfooter = $subfooterbar;
			if ($currentboard eq $annboard) {
				$adminselector = qq~
				<input type="radio" name="multiaction" id="multiactionlock" value="lock" class="titlebg" style="border: 0px;" /> <label for="multiactionlock">$messageindex_txt{'104'}</label>
				<input type="radio" name="multiaction" id="multiactionhide" value="hide" class="titlebg" style="border: 0px;" /> <label for="multiactionhide">$messageindex_txt{'844'}</label>
				<input type="radio" name="multiaction" id="multiactiondelete" value="delete" class="titlebg" style="border: 0px;" /> <label for="multiactiondelete">$messageindex_txt{'31'}</label>
				<input type="radio" name="multiaction" id="multiactionmove" value="move" class="titlebg" style="border: 0px;" /> <label for="multiactionmove">$messageindex_txt{'133'}</label>: <input type="checkbox" name="newinfo" value="1" title="$messageindex_txt{199}" class="titlebg" style="border: 0px;" ondblclick="alert('$messageindex_txt{200}')" /> <select name="toboard" onchange="document.multiadmin.multiaction[3].checked=true;">$boardlist</select>
				<input type="hidden" name="fromboard" value="$currentboard" />
				<input type="submit" value="$messageindex_txt{'462'}" class="button" />
			~;
			} else {
				$adminselector = qq~
				<input type="radio" name="multiaction" id="multiactionlock" value="lock" class="titlebg" style="border: 0px;" /> <label for="multiactionlock">$messageindex_txt{'104'}</label>
				<input type="radio" name="multiaction" id="multiactionstick" value="stick" class="titlebg" style="border: 0px;" /> <label for="multiactionstick">$messageindex_txt{'781'}</label>
				<input type="radio" name="multiaction" id="multiactionhide" value="hide" class="titlebg" style="border: 0px;" /> <label for="multiactionhide">$messageindex_txt{'844'}</label>
				<input type="radio" name="multiaction" id="multiactiondelete" value="delete" class="titlebg" style="border: 0px;" /> <label for="multiactiondelete">$messageindex_txt{'31'}</label>
				<input type="radio" name="multiaction" id="multiactionmove" value="move" class="titlebg" style="border: 0px;" /> <label for="multiactionmove">$messageindex_txt{'133'}</label>: <input type="checkbox" name="newinfo" value="1" title="$messageindex_txt{199}" class="titlebg" style="border: 0px;" ondblclick="alert('$messageindex_txt{200}')" /> <select name="toboard" onchange="document.multiadmin.multiaction[4].checked=true;">$boardlist</select>
				<input type="hidden" name="fromboard" value="$currentboard" />
				<input type="submit" value="$messageindex_txt{'462'}" class="button" />
			~;
			}
			$admincheckboxes = qq~
				<input type="checkbox" name="checkall" id="checkall" value="" class="titlebg" style="border: 0px;" onclick="if (this.checked) checkAll(0); else uncheckAll(0);" />
			~;
			$tempfooter =~ s/({|<)yabb admin selector(}|>)/$adminselector/g;
			$tempfooter =~ s/({|<)yabb admin checkboxes(}|>)/$admincheckboxes/g;
		}
	}
	$tmptempfooter .= $tempfooter;

	$yabbicons = qq~
	<img src="$imagesdir/thread.gif" alt="$messageindex_txt{'457'}" title="$messageindex_txt{'457'}" /> $messageindex_txt{'457'}<br />
	<img src="$imagesdir/sticky.gif" alt="$messageindex_txt{'779'}" title="$messageindex_txt{'779'}" /> $messageindex_txt{'779'}<br />
	<img src="$imagesdir/locked.gif" alt="$messageindex_txt{'456'}" title="$messageindex_txt{'456'}" /> $messageindex_txt{'456'}<br />
	<img src="$imagesdir/stickylock.gif" alt="$messageindex_txt{'456'}" title="$messageindex_txt{'780'}" /> $messageindex_txt{'780'}<br />
	<img src="$imagesdir/locked_moved.gif" alt="$messageindex_txt{'845'}" title="$messageindex_txt{'845'}" /> $messageindex_txt{'845'}<br />
~;
	if (($iamadmin || $iamgmod || $iammod) && $sessionvalid == 1) {
		$yabbadminicons = qq~<img src="$imagesdir/hide.gif" alt="$messageindex_txt{'458'}" title="$messageindex_txt{'458'}" /> $messageindex_txt{'458'}<br />~;
		$yabbadminicons .= qq~<img src="$imagesdir/hidesticky.gif" alt="$messageindex_txt{'459'}" title="$messageindex_txt{'459'}" /> $messageindex_txt{'459'}<br />~;
		$yabbadminicons .= qq~<img src="$imagesdir/hidelock.gif" alt="$messageindex_txt{'460'}" title="$messageindex_txt{'460'}" /> $messageindex_txt{'460'}<br />~;
		$yabbadminicons .= qq~<img src="$imagesdir/hidestickylock.gif" alt="$messageindex_txt{'461'}" title="$messageindex_txt{'461'}" /> $messageindex_txt{'461'}<br />~;
	}
	$yabbadminicons .= qq~
	<img src="$imagesdir/announcement.gif" alt="$messageindex_txt{'779a'}" title="$messageindex_txt{'779a'}" /> $messageindex_txt{'779a'}<br />
	<img src="$imagesdir/announcementlock.gif" alt="$messageindex_txt{'779b'}" title="$messageindex_txt{'779b'}" /> $messageindex_txt{'779b'}<br />
	<img src="$imagesdir/hotthread.gif" alt="$messageindex_txt{'454'} $HotTopic $messageindex_txt{'454a'}" title="$messageindex_txt{'454'} $HotTopic $messageindex_txt{'454a'}" /> $messageindex_txt{'454'} $HotTopic $messageindex_txt{'454a'}<br />
	<img src="$imagesdir/veryhotthread.gif" alt="$messageindex_txt{'455'} $VeryHotTopic $messageindex_txt{'454a'}" title="$messageindex_txt{'455'} $VeryHotTopic $messageindex_txt{'454a'}" /> $messageindex_txt{'455'} $VeryHotTopic $messageindex_txt{'454a'}<br />
~;

	&LoadAccess;

	#template it
	$messageindex_template =~ s/({|<)yabb board(}|>)/$boardlink/g;
	$template_mods = qq~$modslink$showmodgroups~;

	my ($rss_link, $rss_text);
	if (!$rss_disabled) {
		$rss_link = qq~<a href="$scripturl?action=RSSboard;board=$currentboard" target="_blank"><img src="$imagesdir/rss.png" border="0" alt="$maintxt{'rssfeed'}" title="$maintxt{'rssfeed'}" style="vertical-align: middle;" /></a>~;
		$rss_text = qq~<a href="$scripturl?action=RSSboard;board=$INFO{'board'}" target="_blank">$messageindex_txt{843}</a>~;
	}
	$yyrssfeed = $rss_text;
	$yyrss = $rss_link;
	$messageindex_template =~ s/({|<)yabb rssfeed(}|>)/$rss_text/g;
	$messageindex_template =~ s/({|<)yabb rss(}|>)/$rss_link/g;

	$messageindex_template =~ s/({|<)yabb home(}|>)/$homelink/g;
	$messageindex_template =~ s/({|<)yabb category(}|>)/$catlink/g;
	$messageindex_template =~ s/({|<)yabb board(}|>)/$boardlink/g;
	$messageindex_template =~ s/({|<)yabb moderators(}|>)/$template_mods/g;

	if ($ShowBDescrip) {
		if ($bdescrip ne "") {
			&ToChars($bdescrip);
			$boarddescription      =~ s/({|<)yabb boarddescription(}|>)/$bdescrip/g;
			$messageindex_template =~ s/({|<)yabb description(}|>)/$boarddescription/g;
		}
		else {
			$messageindex_template =~ s/({|<)yabb description(}|>)//g;
		}
		if (${$uid.$currentboard}{'ann'} == 1)  { ${$uid.$currentboard}{'pic'} = "ann.gif"; }
		elsif (${$uid.$currentboard}{'rbin'} == 1) { ${$uid.$currentboard}{'pic'} = "recycle.gif"; }
		else { if (!${$uid.$currentboard}{'pic'}) { ${$uid.$currentboard}{'pic'} = "boards.gif"; } }
		$bdpic = ${$uid.$currentboard}{'pic'};
		if ($bdpic =~ /\//i) { $bdpic = qq~ <img src="$bdpic" alt="$boardname" title="$boardname" border="0" align="middle" /> ~; }
		elsif ($bdpic) { $bdpic = qq~ <img src="$imagesdir/$bdpic" alt="$boardname" title="$boardname" border="0" align="middle" /> ~; }
		$messageindex_template =~ s/({|<)yabb bdpicture(}|>)/$bdpic/g;
		$tmpthreadcount = &NumberFormat(${$uid.$currentboard}{'threadcount'});
		$tmpmessagecount = &NumberFormat(${$uid.$currentboard}{'messagecount'});
		$messageindex_template =~ s/({|<)yabb threadcount(}|>)/$tmpthreadcount/g;
		$messageindex_template =~ s/({|<)yabb messagecount(}|>)/$tmpmessagecount/g;
	}
	$messageindex_template =~ s/({|<)yabb colspan(}|>)/$colspan/g;

	$topichandellist =~ s/({|<)yabb notify button(}|>)/$notify_board/g;
	$topichandellist =~ s/({|<)yabb markall button(}|>)/$markalllink/g;
	$topichandellist =~ s/({|<)yabb new post button(}|>)/$postlink/g;
	$topichandellist =~ s/({|<)yabb new poll button(}|>)/$polllink/g;
	$topichandellist =~ s/\Q$menusep//i;

	$messageindex_template =~ s/({|<)yabb topichandellist(}|>)/$topichandellist/g;
	$messageindex_template =~ s/({|<)yabb pageindex top(}|>)/$pageindex1/g;
	$messageindex_template =~ s/({|<)yabb pageindex bottom(}|>)/$pageindex2/g;

	if ((($iamadmin && $adminview == 3) || ($iamgmod && $gmodview == 3) || ($iammod && $modview == 3 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
		$messageindex_template =~ s/({|<)yabb admin column(}|>)/$adminheader/g;
	} elsif ((($iamadmin && $adminview != 0) || ($iamgmod && $gmodview != 0) || ($iammod && $modview != 0 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
		$messageindex_template =~ s/({|<)yabb admin column(}|>)/$adminheader/g;
	} else {
		$messageindex_template =~ s/({|<)yabb admin column(}|>)//g;
	}

	if ((($iamadmin && $adminview >= 2) || ($iamgmod && $gmodview >= 2) || ($iammod && $modview >= 2 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
		$formstart = qq~<form name="multiadmin" action="$scripturl?board=$currentboard;action=multiadmin" method="post" style="display: inline">~;
		$formend   = qq~<input type="hidden" name="allpost" value="$INFO{'start'}" /></form>~;
		$messageindex_template =~ s/({|<)yabb modupdate(}|>)/$formstart/g;
		$messageindex_template =~ s/({|<)yabb modupdateend(}|>)/$formend/g;
	} else {
		$messageindex_template =~ s/({|<)yabb modupdate(}|>)//g;
		$messageindex_template =~ s/({|<)yabb modupdateend(}|>)//g;
	}
	if ($tmpstickyheader) {
		$messageindex_template =~ s/({|<)yabb stickyblock(}|>)/$tmpstickyheader/g;
	} else {
		$messageindex_template =~ s/({|<)yabb stickyblock(}|>)//g;
	}
	$messageindex_template =~ s/({|<)yabb threadblock(}|>)/$tmptempbar/g;
	if ($tmptempfooter) {
		$messageindex_template =~ s/({|<)yabb adminfooter(}|>)/$tmptempfooter/g;
	} else {
		$messageindex_template =~ s/({|<)yabb adminfooter(}|>)//g;
	}
	$messageindex_template =~ s/({|<)yabb icons(}|>)/$yabbicons/g;
	$messageindex_template =~ s/({|<)yabb admin icons(}|>)/$yabbadminicons/g;
	$messageindex_template =~ s/({|<)yabb access(}|>)/ &LoadAccess /e;
	$yymain .= qq~
	$messageindex_template
	$pageindexjs
	~;

	if ((($iamadmin && $adminview >= 2) || ($iamgmod && $gmodview >= 2) || ($iammod && $modview >= 2 && !$iamadmin && !$iamgmod)) && $sessionvalid == 1) {
		my $modul = $currentboard eq $annboard ? 4 : 5;

		if ($sessionvalid == 1) {
			$yymain .= qq~
<script language="JavaScript1.2" type="text/javascript">
<!--
	function checkAll(j) {
		for (var i = 0; i < document.multiadmin.elements.length; i++) {
			if (document.multiadmin.elements[i].type == "checkbox" && !/all\$/.test(document.multiadmin.elements[i].name) && (j == 0 || (j != 0 && (i % $modul) == (j - 1))))
				document.multiadmin.elements[i].checked = true;
		}
	}
	function uncheckAll(j) {
		for (var i = 0; i < document.multiadmin.elements.length; i++) {
			if (document.multiadmin.elements[i].type == "checkbox" && !/all\$/.test(document.multiadmin.elements[i].name) && (j == 0 || (j != 0 && (i % $modul) == (j - 1))))
				document.multiadmin.elements[i].checked = false;
		}
	}
//-->
</script>\n~;
		}
	}

	$yyjavascript .= qq~\nvar markallreadlang = '$messageindex_txt{'500'}';\nvar markfinishedlang = '$messageindex_txt{'500a'}';~;
	$yymain .= qq~
<script language="JavaScript1.2" src="$yyhtml_root/ajax.js" type="text/javascript"></script>
<script language="JavaScript1.2" type="text/javascript">
<!--
	function ListPages(tid) { window.open('$scripturl?action=pages;num='+tid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
	function ListPages2(bid,cid) { window.open('$scripturl?action=pages;board='+bid+';count='+cid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
//-->
</script>
	~;

	# Make browsers aware of our RSS
	if(!$rss_disabled && $INFO{'board'}) { # Check to see if we're on a real board, not announcements
		$yyinlinestyle .= qq~<link rel="alternate" type="application/rss+xml" title="$messageindex_txt{'843'}" href="$scripturl?action=RSSboard;board=$INFO{'board'}" />\n~;
	}
	$tabsep = qq~<img src="$imagesdir/tabsep211.png" border="0" alt="" style="vertical-align: middle;" />~;
	$yynavback = qq~$tabsep <a href="$scripturl">&lsaquo; $img_txt{'103'}</a> $tabsep~;
	$yynavigation = qq~&rsaquo; $catlink &rsaquo; $boardname~;
	$yytitle = $boardname;
	if ($postlink and $enable_quickpost) {
		$yymain =~ s~(<!-- Icon and access info end -->)~$1\n<div style="text-align: right; padding-top: 10px; padding-bottom: 10px;">{yabb forumjump}</div>~;
		require "$sourcedir/Post.pl";
		$action = 'post';
		$INFO{'title'} = 'StartNewTopic';
		$Quick_Post = 1;
		&Post;
	}
	&template;
}

sub MarkRead { # Mark all threads in this board as read.
	# Load the log file
	&getlog;

	# Look for any threads marked unread in the current board and remove them
	fopen(BRDTXT, "$boardsdir/$currentboard.txt") || &fatal_error("cannot_open","$boardsdir/$currentboard.txt", 1);
	my @threadlist = map {/^(\d+)\|/} <BRDTXT>;
	fclose(BRDTXT);

	# Loop through @threadlist and delete the corresponding item from %yyuserlog
	foreach (@threadlist) { delete $yyuserlog{"$_--unread"}; }

	# Write it out
	&dumplog("$currentboard--mark");

	if($INFO{'oldmarkread'}) {
		&redirectinternal;
	}
	$elenable = 0;
	die ""; # This is here only to avoid server error log entries!
}

sub ListPages {
	my ($pcount, $maxvalue, $tlink);
	if ($INFO{'num'} ne '') { 
		$tlink = $INFO{'num'};
		$pcount = ${$INFO{'num'}}{'replies'} + 1;
		$maxvalue = $maxmessagedisplay;
		$jcode = 'num=';
	}
	if ($INFO{'board'} ne '') {
		$tlink = $INFO{'board'};
		$pcount = $INFO{'count'};
		$maxvalue = $maxdisplay;
		$jcode = 'board=';
	}

	$tmpa = 1;
	for ($tmpb = 0; $tmpb < $pcount; $tmpb += $maxvalue) {
		$pages .= qq~<a href='javascript: opp_page("$tlink","~ . ((!$ttsreverse or $INFO{'board'}) ? $tmpb : (${$INFO{'num'}}{'replies'} - $tmpb)) . qq~");'>$tmpa</a>\n~;
		++$tmpa;
	}
	$pages =~ s/\n\Z//;

	&print_output_header;

	$output = qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=$yycharset" />
<title>$messageindex_txt{'139'} $messageindex_txt{'18'}</title>
<link rel="stylesheet" href="$forumstylesurl/$usestyle.css" type="text/css" />
</head>
<body style="min-width: 350px;">
	<script language="JavaScript1.2" type="text/javascript">
	<!-- 
	function opp_page(tid,pid) {
		opener.location= "$scripturl?$jcode" + tid + "/" + pid;
		self.close();
	}
	//-->
	</script>
	<table border="0" cellpadding="4" cellspacing="1" width="100%" class="bordercolor">
	<tr>
		<td class="titlebg" align="center">$messageindex_txt{'139'} $messageindex_txt{'18'}</td>
	</tr>
	<tr>
		<td class="catbg" align="center">
		<br /><br /><br /><br />
		<p>&laquo; $messageindex_txt{'139'} $pages &raquo;</p>
		<br /><br /><br /><br />
		</td>
	</tr>
	<tr>
		<td class="windowbg" align="center"><a href="javascript: window.close();">$messageindex_txt{'903'}</a></td>
	</tr>
	</table>
</body>
</html>~;

	&print_HTML_output_and_finish;
}

sub MessagePageindex {
	# my ($msindx, $trindx, $mbindx);
	my ($msindx, $trindx, $mbindx, $pmindx) = split(/\|/, ${$uid.$username}{'pageindex'});
	if ($INFO{'action'} eq "messagepagedrop") {
		${$uid.$username}{'pageindex'} = qq~0|$trindx|$mbindx|$pmindx~;
	}
	if ($INFO{'action'} eq "messagepagetext") {
		${$uid.$username}{'pageindex'} = qq~1|$trindx|$mbindx|$pmindx~;
	}
	&UserAccount($username, "update");
	&redirectinternal;
}

sub moveto {
	my ($boardlist, $catid, $board, $category, $boardname, $boardperms, $boardview, $brdlist, @bdlist, $catname, $catperms, $access);
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	foreach $catid (@categoryorder) {
		$brdlist = $cat{$catid};
		if(!$brdlist) { next; }
		@bdlist = split(/,/, $brdlist);
		($catname, $catperms) = split(/\|/, $catinfo{"$catid"});

		$access = &CatAccess($catperms);
		if (!$access) { next; }
		&ToChars($catname);
		$boardlist .= qq~<optgroup label="$catname">~;
		foreach $board (@bdlist) {
			($boardname, $boardperms, $boardview) = split(/\|/, $board{"$board"});
			&ToChars($boardname);
			$access = &AccessCheck($board, '', $boardperms);
			if (!$iamadmin && $access ne "granted") { next; }
			if ($board ne $currentboard) {
				$boardlist .= qq~<option value="$board">$boardname</option>\n~;
			}
		}
		$boardlist .= qq~</optgroup>~;
	}
	$boardlist;
}

sub LoadAccess {
	my $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'808'}<br />";
	my $noaccesses = "";

	# Reply Check
	my $rcaccess = &AccessCheck($currentboard, 2) || 0;
	if ($rcaccess eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'809'}<br />"; }
	else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'809'}<br />"; }

	# start new Topic Check
	if (&AccessCheck($currentboard, 1) eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'810'}<br />"; }
	else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'810'}<br />"; }

	# Attachments Check
	if (&AccessCheck($currentboard, 4) eq 'granted' && $allowattach && ${$uid.$currentboard}{'attperms'} == 1 && (($allowguestattach == 0 && !$iamguest) || $allowguestattach == 1)) { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'813'}<br />"; }
	else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'813'}<br />"; }

	# Poll Check
	if (&AccessCheck($currentboard, 3) eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'811'}<br />"; }
	else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'811'}<br />"; }

	# Zero Post Check
	if ($username ne 'Guest') {
		if ($INFO{'zeropost'} != 1 && $rcaccess eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'812'}<br />"; }
		else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'812'}<br />"; }
	}

	qq~$yesaccesses<br />$noaccesses~;
}

1;