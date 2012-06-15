###############################################################################
# Display.pl                                                                  #
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

$displayplver = 'YaBB 2.5 AE $Revision: 1.62 $';
if ($action eq 'detailedversion') { return 1; }

&LoadLanguage('Display');
&LoadLanguage('FA');
require "$templatesdir/$usedisplay/Display.template";
if ($iamgmod) { require "$vardir/gmodsettings.txt"; }

sub Display {
	# Check if board was 'shown to all' - and whether they can view the topic
	if (&AccessCheck($currentboard, '', $boardperms) ne "granted") { &fatal_error("no_access"); }

	# Get the "NEW"est Post for this user.
	my $newestpost;
	if (!$iamguest && $max_log_days_old && $INFO{'start'} eq "new") {
		# This decides which messages were already read in the thread to
		# determing where the redirect should go. It is done by
		# comparing times in the username.log and the boardnumber.txt files.
		&getlog;
		my $mnum = $INFO{'num'};
		my $dlp = int($yyuserlog{$mnum}) > int($yyuserlog{"$currentboard--mark"}) ? int($yyuserlog{$mnum}) : int($yyuserlog{"$currentboard--mark"});
		$dlp = $dlp > $date - ($max_log_days_old * 86400) ? $dlp : $date - ($max_log_days_old * 86400);

		unless (ref($thread_arrayref{$mnum})) {
			fopen(MNUM, "$datadir/$mnum.txt");
			@{$thread_arrayref{$mnum}} = <MNUM>;
			fclose(MNUM);
		}
		my $i = -1;
		foreach (@{$thread_arrayref{$mnum}}) {
			$i++;
			last if (split(/\|/, $_))[3] > $dlp;
		}

		$newestpost = $INFO{'start'} = $i;
	}

	if ($buddyListEnabled) { &loadMyBuddy; }
	my $viewnum = $INFO{'num'};

	# strip off any non numeric values to avoid exploitation
	$maxmessagedisplay ||= 10;
	my ($msubthread, $mnum, $mstate, $mdate, $msub, $mname, $memail, $mreplies, $musername, $micon, $mip, $mlm, $mlmb);
	my ($counter, $counterwords, $threadclass, $notify, $max, $start, $windowbg, $mattach, $pagedropindex, $template_viewers, $template_favorite, $template_pollmain, $navback, $mark_unread, $pollbutton, $icanbypass, $replybutton, $bypassReplyButton);

	&LoadCensorList;

	# Determine category
	$curcat = ${$uid.$currentboard}{'cat'};

	# Figure out the name of the category
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }

	if ($currentboard eq $annboard) {
		$vircurrentboard = $INFO{'virboard'};
		$vircurcat = ${$uid.$vircurrentboard}{'cat'};
		($vircat, undef) = split(/\|/, $catinfo{$vircurcat});
		($virboardname, undef) = split(/\|/, $board{$vircurrentboard},2);
		&ToChars($virboardname);
	}

	($cat, $catperms) = split(/\|/, $catinfo{"$curcat"});
	&ToChars($cat);

	($boardname, $boardperms, $boardview) = split(/\|/, $board{$currentboard});

	&ToChars($boardname);

	# Check to make sure this thread isn't locked.
	($mnum, $msubthread, $mname, $memail, $mdate, $mreplies, $musername, $micon, $mstate) = split(/\|/, $yyThreadLine);

	if ($mstate =~ /m/) {
		$msubthread =~ / dest=(\d+)\]/;
		my $newnum = $1;
		if (-e "$datadir/$newnum.txt") {
			$yySetLocation = "$scripturl?num=$newnum";
			&redirectexit;
		}
		eval { require "$datadir/movedthreads.cgi" };
		while (exists $moved_file{$newnum}) {
			$newnum = $moved_file{$newnum};
			next if exists $moved_file{$newnum};
			if (-e "$datadir/$newnum.txt") {
				$yySetLocation = "$scripturl?num=$newnum";
				&redirectexit;
			}
		}
	}

	($msubthread, undef) = &Split_Splice_Move($msubthread,0);
	&ToChars($msubthread);
	$msubthread = &Censor($msubthread);

	# Build a list of this board's moderators.
	if (keys %moderators > 0) {
		if (keys %moderators == 1) { $showmods = qq~($display_txt{'298'}: ~; }
		else { $showmods = qq~($display_txt{'63'}: ~; }

		while ($_ = each(%moderators)) {
			&FormatUserName($_);
			$showmods .= &QuickLinks($_,1) . ", ";
		}
		$showmods =~ s/, \Z/)/;
	}
	if (keys %moderatorgroups > 0) {
		if (keys %moderatorgroups == 1) { $showmodgroups = qq~($display_txt{'298a'}: ~; }
		else { $showmodgroups = qq~($display_txt{'63a'}: ~; }

		my ($tmpmodgrp,$thismodgrp);
		while ($_ = each(%moderatorgroups)) {
			$tmpmodgrp = $moderatorgroups{$_};
			($thismodgrp, undef) = split(/\|/, $NoPost{$tmpmodgrp}, 2);
			$showmodgroups .= qq~$thismodgrp, ~;
		}
		$showmodgroups =~ s/, \Z/)/;
	}

	## now we've established credentials,
	## can this user bypass locks?
	## work out who can bypass locked thread post only if bypass switched on
	if ($mstate =~ /l/i) {
		if ($bypass_lock_perm) { $icanbypass = &checkUserLockBypass; }
		$enable_quickreply = 0;
	}

	my $permdate = &permtimer($mnum);
	my $display_permalink = qq~<a href="http://$perm_domain/$symlink$permdate/$currentboard/$mnum">$display_txt{'10'}</a>~;

	# Look for a poll file for this thread.
	if (&AccessCheck($currentboard, 3) eq 'granted') {
		$pollbutton = qq~$menusep<a href="$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;title=AddPoll">$img{'addpoll'}</a>~;
	}
	if (-e "$datadir/$viewnum.poll") {
		$has_poll = 1;
		$pollbutton = '';
	} else {
		$has_poll = 0;
		if ($useraddpoll == 0) { $pollbutton = ''; }
	}

	# Get the class of this thread, based on lock status and number of replies.
	if ((!$iamguest || $enable_guestposting) && &AccessCheck($currentboard, 2) eq 'granted') {
		$replybutton = qq~$menusep<a href="~ . ($enable_quickreply && $enable_quickjump ? 'javascript:document.postmodify.message.focus();' : qq~$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;title=PostReply~);
		$bypassReplyButton = $replybutton . qq~" onclick="return confirm('$display_txt{'posttolocked'}');">$img{'reply'}</a> ~;
		$replybutton .= qq~">$img{'reply'}</a> ~;
	}

	$threadclass = 'thread';
	## hidden threads
	if ($mstate =~ /h/i) {
		$threadclass = 'hide';
		if (!$iamadmin && !$iamgmod && !$iammod) { &fatal_error('no_access'); }
	}
	## locked thread
	elsif ($mstate =~ /l/i) {
		$threadclass = 'locked';  ## same icon regardless
		$pollbutton = '';
		if   ($icanbypass) { $replybutton = $bypassReplyButton; }
		else { $replybutton = ''; } # squish
	}
	elsif ($mreplies >= $VeryHotTopic) { $threadclass = 'veryhotthread'; }
	elsif ($mreplies >= $HotTopic) { $threadclass = 'hotthread'; }
	elsif ($mstate eq '') { $threadclass = 'thread'; }

	if ($threadclass eq 'hide') { ##  hidden
		if ($mstate =~ /s/i && $mstate !~ /l/i) { $threadclass = 'hidesticky'; }
		elsif ($mstate =~ /l/i && $mstate !~ /s/i) {
			$threadclass = 'hidelock'; $pollbutton = '';
			if ($icanbypass) { $replybutton = $bypassReplyButton; }
			else { $replybutton = ''; } # squish
		}
		elsif ($mstate =~ /s/i && $mstate =~ /l/i) {
			$threadclass = 'hidestickylock'; $pollbutton  = '';
			if ($icanbypass) { $replybutton = $bypassReplyButton; }
			else { $replybutton = ''; } # squish
		}
	}
	elsif ($threadclass eq 'locked' && $mstate =~ /s/i) {
		$threadclass = 'stickylock';
		if ($icanbypass) { $replybutton = $bypassReplyButton; }
		else { $replybutton = ''; } # squish
	}
	elsif ($mstate =~ /s/i) { $threadclass = 'sticky'; }
	elsif (${$mnum}{'board'} eq $annboard) { $threadclass = $threadclass eq 'locked' ? 'announcementlock' : 'announcement'; }

	if (-e "$datadir/$mnum.mail" && !$iamguest) {
		require "$sourcedir/Notify.pl";
		&ManageThreadNotify("update", $mnum, $username, '', '', '1');
	}

	if ($showmodgroups ne "" && $showmods ne "") { $showmods .= qq~ - ~; }

	# Build the page links list.
	if (!$iamguest) {
		(undef, $userthreadpage, undef,undef) = split(/\|/, ${$uid.$username}{'pageindex'});
	}
	my ($pagetxtindex, $pagetextindex, $pagedropindex1, $pagedropindex2, $all, $allselected);
	$postdisplaynum = 3; # max number of pages to display
	$dropdisplaynum = 10;
	$startpage = 0;
	$max = $mreplies + 1;
	if (substr($INFO{'start'}, 0, 3) eq 'all' && $showpageall != 0) { $maxmessagedisplay = $max; $all = 1; $allselected = qq~ selected="selected"~; $start = !$ttsreverse ? 0 : $mreplies; }
	else { $start = $INFO{'start'} !~ /\d/ ? (!$ttsreverse ? 0 : $mreplies) : $INFO{'start'}; }
	$start = $start > $mreplies ? $mreplies : $start;
	$start = !$ttsreverse ? (int($start / $maxmessagedisplay) * $maxmessagedisplay) : (int(($mreplies - $start) / $maxmessagedisplay) * $maxmessagedisplay);
	$tmpa = 1;
	$pagenumb = int(($max - 1) / $maxmessagedisplay) + 1;

	if ($start >= (($postdisplaynum - 1) * $maxmessagedisplay)) {
		$startpage = $start - (($postdisplaynum - 1) * $maxmessagedisplay);
		$tmpa = int($startpage / $maxmessagedisplay) + 1;
	}
	if ($max >= $start + ($postdisplaynum * $maxmessagedisplay)) { $endpage = $start + ($postdisplaynum * $maxmessagedisplay); }
	else { $endpage = $max; }
	$lastpn = int($mreplies / $maxmessagedisplay) + 1;
	$lastptn = ($lastpn - 1) * $maxmessagedisplay;
	$pageindex1 = qq~<span class="small" style="float: left; height: 21px; margin: 0px; margin-top: 2px;"><img src="$imagesdir/index_togl.gif" border="0" alt="$display_txt{'19'}" title="$display_txt{'19'}" style="vertical-align: middle;" /> $display_txt{'139'}: $pagenumb</span>~;
	$pageindex2 = $pageindex1;
	if ($pagenumb > 1 || $all) {
		if ($userthreadpage == 1 || $iamguest) {
			$pagetxtindexst = qq~<span class="small" style="float: left; height: 21px; margin: 0px; margin-top: 2px;">~;
			if (!$iamguest) { $pagetxtindexst .= qq~<a href="$scripturl?num=$viewnum;start=~ . (!$ttsreverse ? $start : $mreplies - $start) . qq~;action=threadpagedrop"><img src="$imagesdir/index_togl.gif" border="0" alt="$display_txt{'19'}" style="vertical-align: middle;" /></a> $display_txt{'139'}: ~; }
			else { $pagetxtindexst .= qq~<img src="$imagesdir/index_togl.gif" border="0" alt="" style="vertical-align: middle;" /> $display_txt{'139'}: ~; }
			if ($startpage > 0) { $pagetxtindex = qq~<a href="$scripturl?num=$viewnum/~ . (!$ttsreverse ? 0 : $mreplies) . qq~" style="font-weight: normal;">1</a>&nbsp;<a href="javascript:void(0);" onclick="ListPages($mnum);">...</a>&nbsp;~; }
			if ($startpage == $maxmessagedisplay) { $pagetxtindex = qq~<a href="$scripturl?num=$viewnum/~ . (!$ttsreverse ? 0 : $mreplies) . qq~" style="font-weight: normal;">1</a>&nbsp;~; }
			for ($counter = $startpage; $counter < $endpage; $counter += $maxmessagedisplay) {
				$pagetxtindex .= $start == $counter ? qq~<b>$tmpa</b>&nbsp;~ : qq~<a href="$scripturl?num=$viewnum/~ . (!$ttsreverse ? $counter : ($mreplies - $counter)) . qq~" style="font-weight: normal;">$tmpa</a>&nbsp;~;
				$tmpa++;
			}
			if ($endpage < $max - ($maxmessagedisplay)) { $pageindexadd = qq~<a href="javascript:void(0);" onclick="ListPages($mnum);">...</a>&nbsp;~; }
			if ($endpage != $max) { $pageindexadd .= qq~<a href="$scripturl?num=$viewnum/~ . (!$ttsreverse ? $lastptn : $mreplies - $lastptn) . qq~" style="font-weight: normal;">$lastpn</a>~; }
			$pagetxtindex .= qq~$pageindexadd~;
			$pageindex1 = qq~$pagetxtindexst$pagetxtindex</span>~;
			$pageindex2 = $pageindex1;

		} else {
			$pagedropindex1 = qq~<span style="float: left; width: 350px; margin: 0px; margin-top: 2px; border: 0px;">~;
			$pagedropindex1 .= qq~<span style="float: left; height: 21px; margin: 0; margin-right: 4px;"><a href="$scripturl?num=$viewnum;start=~ . (!$ttsreverse ? $start : $mreplies - $start) . qq~;action=threadpagetext"><img src="$imagesdir/index_togl.gif" border="0" alt="$display_txt{'19'}" title="$display_txt{'19'}" /></a></span>~;
			$pagedropindex2 = $pagedropindex1;
			$tstart = $start;
			#if (substr($INFO{'start'}, 0, 3) eq "all") { ($tstart, $start) = split(/\-/, $INFO{'start'}); }
			$d_indexpages = $pagenumb / $dropdisplaynum;
			$i_indexpages = int($pagenumb / $dropdisplaynum);
			if ($d_indexpages > $i_indexpages) { $indexpages = int($pagenumb / $dropdisplaynum) + 1; }
			else { $indexpages = int($pagenumb / $dropdisplaynum) }
			$selectedindex = int(($start / $maxmessagedisplay) / $dropdisplaynum);

			if ($pagenumb > $dropdisplaynum) {
				$pagedropindex1 .= qq~<span style="float: left; height: 21px; margin: 0;"><select size="1" name="decselector1" id="decselector1" style="font-size: 9px; border: 2px inset;" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
				$pagedropindex2 .= qq~<span style="float: left; height: 21px; margin: 0;"><select size="1" name="decselector2" id="decselector2" style="font-size: 9px; border: 2px inset;" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
			}

			for ($i = 0; $i < $indexpages; $i++) {
				$indexpage = !$ttsreverse ? ($i * $dropdisplaynum * $maxmessagedisplay) : ($mreplies - ($i * $dropdisplaynum * $maxmessagedisplay));
				$indexstart = ($i * $dropdisplaynum) + 1;
				$indexend = $indexstart + ($dropdisplaynum - 1);
				if ($indexend > $pagenumb)    { $indexend   = $pagenumb; }
				if ($indexstart == $indexend) { $indxoption = qq~$indexstart~; }
				else { $indxoption = qq~$indexstart-$indexend~; }
				$selected = "";
				if ($i == $selectedindex) {
					$selected    = qq~ selected="selected"~;
					$pagejsindex = qq~$indexstart|$indexend|$maxmessagedisplay|$indexpage~;
				}
				if ($pagenumb > $dropdisplaynum) {
					$pagedropindex1 .= qq~<option value="$indexstart|$indexend|$maxmessagedisplay|$indexpage"$selected>$indxoption</option>\n~;
					$pagedropindex2 .= qq~<option value="$indexstart|$indexend|$maxmessagedisplay|$indexpage"$selected>$indxoption</option>\n~;
				}
			}

			if ($pagenumb > $dropdisplaynum) {
				$pagedropindex1 .= qq~</select>\n</span>~;
				$pagedropindex2 .= qq~</select>\n</span>~;
			}
			$pagedropindex1 .= qq~<span id="ViewIndex1" class="droppageindex" style="height: 14px; visibility: hidden">&nbsp;</span>~;
			$pagedropindex2 .= qq~<span id="ViewIndex2" class="droppageindex" style="height: 14px; visibility: hidden">&nbsp;</span>~;
			$tmpmaxmessagedisplay = $maxmessagedisplay;
			$prevpage = !$ttsreverse ? $start - $tmpmaxmessagedisplay : $mreplies - $start + $tmpmaxmessagedisplay;
			$nextpage = !$ttsreverse ? $start + $maxmessagedisplay : $mreplies - $start - $maxmessagedisplay;
			$pagedropindexpvbl = qq~<img src="$imagesdir/index_left0.gif" height="14" width="13" border="0" alt="" style="margin: 0px; display: inline; vertical-align: middle;" />~;
			$pagedropindexnxbl = qq~<img src="$imagesdir/index_right0.gif" height="14" width="13" border="0" alt="" style="margin: 0px; display: inline; vertical-align: middle;" />~;
			if ((!$ttsreverse and $start < $maxmessagedisplay) or ($ttsreverse and $prevpage > $mreplies)) { $pagedropindexpv .= qq~<img src="$imagesdir/index_left0.gif" height="14" width="13" border="0" alt="" style="display: inline; vertical-align: middle;" />~; }
			else { $pagedropindexpv .= qq~<img src="$imagesdir/index_left.gif" border="0" height="14" width="13" alt="$pidtxt{'02'}" title="$pidtxt{'02'}" style="display: inline; vertical-align: middle; cursor: pointer;" onclick="location.href=\\'$scripturl?num=$viewnum/$prevpage\\'" ondblclick="location.href=\\'$scripturl?num=$viewnum/~ . (!$ttsreverse ? 0 : $mreplies) . qq~\\'" />~; }
			if ((!$ttsreverse and $nextpage > $lastptn) or ($ttsreverse and $nextpage < $mreplies - $lastptn)) { $pagedropindexnx .= qq~<img src="$imagesdir/index_right0.gif" border="0" height="14" width="13" alt="" style="display: inline; vertical-align: middle;" />~; }
			else { $pagedropindexnx .= qq~<img src="$imagesdir/index_right.gif" height="14" width="13" border="0" alt="$pidtxt{'03'}" title="$pidtxt{'03'}" style="display: inline; vertical-align: middle; cursor: pointer;" onclick="location.href=\\'$scripturl?num=$viewnum/$nextpage\\'" ondblclick="location.href=\\'$scripturl?num=$viewnum/~ . (!$ttsreverse ? $lastptn : $mreplies - $lastptn) . qq~\\'" />~; }
			$pageindex1 = qq~$pagedropindex1</span>~;
			$pageindex2 = qq~$pagedropindex2</span>~;

			$pageindexjs = qq~
	function SelDec(decparam, visel) {
		splitparam = decparam.split("|");
		var vistart = parseInt(splitparam[0]);
		var viend = parseInt(splitparam[1]);
		var maxpag = parseInt(splitparam[2]);
		var pagstart = parseInt(splitparam[3]);
		//var allpagstart = parseInt(splitparam[3]);
		if(visel == 'xx' && decparam == '$pagejsindex') visel = '$tstart';
		var pagedropindex = '<table border="0" cellpadding="0" cellspacing="0"><tr>';
		for(i=vistart; i<=viend; i++) {
			if(visel == pagstart) pagedropindex += '<td class="titlebg" height="14" style="height: 14px; padding-left: 1px; padding-right: 1px; font-size: 9px; font-weight: bold;">' + i + '</td>';
			else pagedropindex += '<td height="14" class="droppages"><a href="$scripturl?num=$viewnum/' + pagstart + '">' + i + '</a></td>';
			pagstart ~ . (!$ttsreverse ? '+' : '-') . qq~= maxpag;
		}
		~;
		if ($showpageall) {
			$pageindexjs .= qq~
			if (vistart != viend) {
				if(visel == 'all') pagedropindex += '<td class="titlebg" height="14" style="height: 14px; padding-left: 1px; padding-right: 1px; font-size: 9px; font-weight: normal;"><b>$pidtxt{'01'}</b></td>';
				else pagedropindex += '<td height="14" class="droppages"><a href="$scripturl?num=$viewnum/all">$pidtxt{'01'}</a></td>';
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
	SelDec('$pagejsindex', '~ . (!$ttsreverse ? $tstart : ($mreplies - $tstart)) . qq~');
~;
		}
	}

	if (!$iamguest) {
		$yyjavascript .= qq~
		var addnotlink = '$img{'add_notify'}';
		var remnotlink = '$img{'del_notify'}';
		~;
		if (${$uid.$username}{'thread_notifications'} =~ /\b$viewnum\b/) {
			$notify = qq~$menusep<a href="javascript:Notify('$scripturl?action=notify3;num=$viewnum/~ . (!$ttsreverse ? $start : $mreplies - $start) . qq~','$imagesdir')" name="notifylink">$img{'del_notify'}</a>~;
		} else {
			$notify = qq~$menusep<a href="javascript:Notify('$scripturl?action=notify2;num=$viewnum/~ . (!$ttsreverse ? $start : $mreplies - $start) . qq~','$imagesdir')" name="notifylink">$img{'add_notify'}</a>~;
		}
	}

	$yymain .= qq~
	<script language="JavaScript1.2" src="$yyhtml_root/ajax.js" type="text/javascript"></script>
	<script language="JavaScript1.2" src="$yyhtml_root/ubbc.js" type="text/javascript"></script>
	~;

	# update the .ctb file START
	&MessageTotals("load", $viewnum);
	if ($username ne "Guest") {
		my (%viewer,@tmprepliers,$isrep);
		foreach (@logentries) { # @logentries already loaded in YaBB.pl => &WriteLog;
			$viewer{(split(/\|/, $_, 2))[0]} = 1;
		}

		my $j = 0;
		foreach (@repliers) {
			my ($reptime, $repuser, $isreplying) = split(/\|/, $_);
			next if $date - $reptime > 600 || !exists $viewer{$repuser};
			if ($repuser eq $username) { $tmprepliers[$j] = qq~$date|$repuser|0~; $isrep = 1; }
			else { $tmprepliers[$j] = qq~$reptime|$repuser|$isreplying~; }
			$j++;
		}
		push(@tmprepliers, qq~$date|$username|0~) if !$isrep;
		@repliers = @tmprepliers;

		${$viewnum}{'views'}++; # Add 1 to the number of views of this thread.
		&MessageTotals("update", $viewnum);
	} else {
		&MessageTotals("incview", $viewnum); # Add 1 to the number of views of this thread.
	}
	# update the .ctb file END

	# Mark current board as read if no other new threads are in
	&getlog;
	# &NextPrev => Insert Navigation Bit and get info about number of threads newer than last visit
	if (&NextPrev($viewnum, $yyuserlog{$currentboard}) < 2) { $yyuserlog{$currentboard} = $date; }
	# Mark current thread as read. Save thread and board Mark.
	delete $yyuserlog{"$mnum--unread"};
	&dumplog($mnum);

	$template_home = qq~<a href="$scripturl" class="nav">$mbname</a>~;
	$topviewers = 0;
	if (${$uid.$currentboard}{'ann'} == 1) {
		if ($vircurrentboard) {
			$template_cat = qq~<a href="$scripturl?catselect=$vircurcat">$vircat</a>~;
			$template_board = qq~<a href="$scripturl?board=$vircurrentboard">$virboardname</a>~;
			$navback = qq~<a href="$scripturl?board=$vircurrentboard">&lsaquo; $maintxt{'board'}</a>~;
			$template_mods = qq~$showmods$showmodgroups~;
		} elsif ($iamadmin || $iamgmod) {
			$template_cat = qq~<a href="$scripturl?catselect=$curcat">$cat</a>~;
			$template_board = qq~<a href="$scripturl?board=$currentboard">$boardname</a>~;
			$navback = qq~<a href="$scripturl?board=$currentboard">&lsaquo; $maintxt{'board'}</a>~;
			$template_mods = qq~$showmods$showmodgroups~;
		} else {
			$template_cat = $maintxt{'418'};
			$template_board = $display_txt{'999'};
			$template_mods = '';
		}
	} else {
		$template_cat = qq~<a href="$scripturl?catselect=$curcat">$cat</a>~;
		$template_board = qq~<a href="$scripturl?board=$currentboard">$boardname</a>~;
		$navback = qq~<a href="$scripturl?board=$currentboard">&lsaquo; $maintxt{'board'}</a>~;
		$template_mods  = qq~$showmods$showmodgroups~;
	}
	if ($showtopicviewers && ($iamadmin || $iamgmod || $iammod) && $sessionvalid == 1) {
		my ($mrepuser, $misreplying, $replying);
		foreach (@repliers) {
			(undef, $mrepuser, $misreplying) = split(/\|/, $_);
			&LoadUser($mrepuser);
			$replying = $misreplying ? qq~ <span class="small">($display_txt{'645'})</span>~ : '';
			$template_viewers .= qq~$link{$mrepuser}$replying, ~;
			$topviewers++;
		}
		$template_viewers =~ s/\, \Z/\./;
	}

	$yyjavascript .= qq~
		var addfavlang = '$display_txt{'526'}';
		var remfavlang = '$display_txt{'527'}';
		var remnotelang = '$display_txt{'530'}';
		var addnotelang = '$display_txt{'529'}';
		var markfinishedlang = '$display_txt{'528'}';~;

	if (!$iamguest && $currentboard ne $annboard) {
		require "$sourcedir/Favorites.pl";
		$template_favorite = &IsFav($viewnum, (!$ttsreverse ? $start : $mreplies - $start));
	}
	$template_threadimage = qq~<a name="top"><img src="$imagesdir/$threadclass.gif" style="vertical-align: middle;" alt="" /></a>~;
	$template_sendtopic = $sendtopicmail ? qq~$menusep<a href="javascript:sendtopicmail($sendtopicmail);">$img{'sendtopic'}</a>~ : '';
	$template_print = qq~$menusep<a href="$scripturl?action=print;num=$viewnum" target="_blank">$img{'print'}</a>~;
	if ($has_poll) { require "$sourcedir/Poll.pl"; &display_poll($viewnum); $template_pollmain = qq~$pollmain<br />~; }

	# Load background color list.
	@cssvalues = ('windowbg', 'windowbg2');
	$cssnum = @cssvalues;

	if (!$UseMenuType) { $sm = 1; }

	unless (ref($thread_arrayref{$viewnum})) {
		fopen(MSGTXT, "$datadir/$viewnum.txt") || &fatal_error("cannot_open","$datadir/$viewnum.txt", 1);
		@{$thread_arrayref{$viewnum}} = <MSGTXT>;
		fclose(MSGTXT);
	}
	$counter = 0;
	my @messages;
	# Skip the posts in this thread until we reach $start.
	if (!$ttsreverse) {
		foreach (@{$thread_arrayref{$viewnum}}) {
			if ($counter >= $start and $counter < ($start + $maxmessagedisplay)) { push(@messages, $_); }
			$counter++;
		}
		$counter = $start;

	} else {
		foreach (@{$thread_arrayref{$viewnum}}) {
			if ($counter > ($mreplies - $start - $maxmessagedisplay) and $counter <= ($mreplies - $start)) { push(@messages, $_); }
			$counter++;
		}
		$counter = $mreplies - $start;
		@messages = reverse(@messages);
	}

	# For each post in this thread:
	my (%attach_gif,%attach_count,$movedflag);
	foreach (@messages) {
		my ($userlocation, $aimad, $yimad, $msnad, $gtalkad, $skypead, $myspacead, $facebookad, $icqad, $buddyad, $addbuddy, $isbuddy, $addbuddylink, $userOnline, $signature_hr, $lastmodified, $memberinfo, $template_postinfo, $template_ext_prof, $template_profile, $template_quote, $template_email, $template_www, $template_pm);

		$css = $cssvalues[($counter % $cssnum)];
		($msub, $mname, $memail, $mdate, $musername, $micon, $mattach, $mip, $postmessage, $ns, $mlm, $mlmb, $mfn) = split(/[\|]/, $_);

		# If the user isn't a guest, load their info.
		if ($musername ne 'Guest' && !$yyUDLoaded{$musername} && -e ("$memberdir/$musername.vars")) {
			my $tmpns = $ns;
			$ns = "";
			&LoadUserDisplay($musername);
			$ns = $tmpns;
		}
		$messagedate = $mdate;
		if (${$uid.$musername}{'regtime'}) {
			$registrationdate = ${$uid.$musername}{'regtime'};
		} else {
			$registrationdate = $date;
		}

		# Do we have an attachment file?
		chomp $mfn;
		$attachment = '';
		$showattach = '';
		$showattachhr = '';
		if ($mfn ne '') {
			# store all downloadcounts in variable
			if (!%attach_count) {
				my ($atfile,$atcount);
				fopen(ATM, "$vardir/attachments.txt");
				while (<ATM>) {
					(undef, undef, undef, undef, undef, undef, undef, $atfile, $atcount) =split(/\|/, $_);
					$attach_count{$atfile} = $atcount;
				}
				fclose(ATM);
				$attach_count{'no_attachments'} = 1 if !%attach_count;
			}

			foreach (split(/,/, $mfn)) {
				$_ =~ /\.(.+?)$/;
				my $ext = lc($1);
				unless (exists $attach_gif{$ext}) {
					$attach_gif{$ext} = ($ext && -e "$forumstylesdir/$useimages/$ext.gif") ? "$ext.gif" : "paperclip.gif";
				}
				my $filesize = -s "$uploaddir/$_";
				if ($filesize) {
					if ($_ =~ /\.(bmp|jpe|jpg|jpeg|gif|png)$/i && $amdisplaypics == 1) {
						$showattach .= qq~<div class="small" style="float:left; margin:8px;"><a href="$scripturl?action=downloadfile;file=$_" target="_blank"><img src="$imagesdir/$attach_gif{$ext}" border="0" align="bottom" alt="" /> $_</a> (~ . int($filesize / 1024) . qq~ KB | <acronym title='$attach_count{$_} $fatxt{'41a'}' class="small">$attach_count{$_}</acronym> )<br />~ . ($img_greybox ? ($img_greybox == 2 ? qq~<a href="$scripturl?action=downloadfile;file=$_" rel="gb_imageset[nice_pics]" title="$_">~ : qq~<a href="$scripturl?action=downloadfile;file=$_" rel="gb_image[nice_pics]" title="$_">~) : qq~<a href="$scripturl?action=downloadfile;file=$_" target="_blank">~) . qq~<img src="$uploadurl/$_" name="attach_img_resize" alt="$_" title="$_" border="0" style="display:none" /></a></div>\n~;
					} else {
						$attachment .= qq~<div class="small"><a href="$scripturl?action=downloadfile;file=$_"><img src="$imagesdir/$attach_gif{$ext}" border="0" align="bottom" alt="" /> $_</a> (~ . int($filesize / 1024) . qq~ KB | <acronym title='$attach_count{$_} $fatxt{'41a'}' class="small">$attach_count{$_}</acronym> )</div>~;
					}
				} else {
					$attachment .= qq~<div class="small"><img src="$imagesdir/$attach_gif{$ext}" border="0" align="bottom" alt="" />  $_ ($fatxt{'1'}~ . (exists $attach_count{$_} ? qq~ | <acronym title='$attach_count{$_} $fatxt{'41a'}' class="small">$attach_count{$_}</acronym> ~ : '') . qq~)</div>~;
				}
			}
			$showattachhr = qq~<hr width="100%" size="1" class="hr" style="margin: 0; margin-top: 5px; margin-bottom: 5px; padding: 0;" />~;
			if ($showattach && $attachment) {
				$attachment =~ s/<div class="small">/<div class="small" style="margin:8px;">/g;
			}
		}

		# Should we show "last modified by?"
		if ($showmodify && $mlm ne '' && $mlmb ne '' && (!$tllastmodflag || ($mdate + ($tllastmodtime * 60)) < $mlm)) {
			&LoadUser($mlmb);
			$mlmb = ${$uid.$mlmb}{'realname'} || $display_txt{'470'};
			$lastmodified = qq~&#171; <i>$display_txt{'211'}: ~ . &timeformat($mlm) . qq~ $display_txt{'525'} $mlmb</i> &#187;~;
		}

		$messdate = &timeformat($mdate);
		if ($iamadmin || $iamgmod && $gmod_access2{'ipban2'} eq "on") { $mip = $mip }
		else { $mip = $display_txt{'511'}; }

		## moderator alert button!
		if ($PMenableAlertButton && $PM_level && !$iamadmin && !$iamgmod && !$iammod && (!$iamguest || ($iamguest && $PMAlertButtonGuests))) {
			$PMAlertButton = qq~$menusep<a href="$scripturl?action=modalert;num=$viewnum;title=PostReply;quote=$counter" onclick="return confirm('$display_txt{'alertmod_confirm'}');">$img{'alertmod'}</a>~;
		}
		## is member a buddy of mine?
		if ($buddyListEnabled && !$iamguest && $musername ne $username) {
			$isbuddy = qq~<br /><img src="$imagesdir/buddylist.gif" border="0" align="middle" alt="$display_txt{'isbuddy'}" title="$display_txt{'isbuddy'}" /> <br />$display_txt{'isbuddy'}~;
			$addbuddylink = qq~$menusep<a href="$scripturl?num=$viewnum;action=addbuddy;name=$useraccount{$musername};vpost=$counter">$img{'addbuddy'}</a>~;
		}

		# user is current / admin / gmod
		if ((${$uid.$musername}{'regdate'} && $messagedate > $registrationdate) || ${$uid.$musername}{'position'} eq 'Administrator' || ${$uid.$musername}{'position'} eq 'Global Moderator') {
			if (!$iamguest && $musername ne $username) {
				## check whether user is a buddy
				if ($mybuddie{$musername}) { $buddyad = $isbuddy; }
				else { $addbuddy = $addbuddylink; }
				# Allow instant message sending if current user is a member.
				&CheckUserPM_Level($musername);
				if ($PM_level == 1 || ($PM_level == 2 && $UserPM_Level{$musername} > 1 && ($iamadmin || $iamgmod || $iammod)) || ($PM_level == 3 && $UserPM_Level{$musername} == 3 && ($iamadmin || $iamgmod))) {
					$template_pm = qq~$menusep<a href="$scripturl?action=imsend;to=$useraccount{$musername}">$img{'message_sm'}</a>~;
				}
			}

			$tmppostcount = &NumberFormat(${$uid.$musername}{'postcount'});
			$template_postinfo = qq~$display_txt{'21'}: $tmppostcount<br />~;
			$template_profile = ($profilebutton && !$iamguest) ? qq~$menusep<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">$img{'viewprofile_sm'}</a>~ : '';
			$template_www = ${$uid.$musername}{'weburl'} ? qq~$menusep${$uid.$musername}{'weburl'}~ : '';

			$userOnline = &userOnLineStatus($musername) . "<br />";
			$displayname = ${$uid.$musername}{'realname'};
			if (${$uid.$musername}{'location'}) {
				$userlocation = ${$uid.$musername}{'location'} . "<br />";
			}
			$signature_hr = qq~<hr width="100%" size="1" class="hr" style="margin: 0; margin-top: 5px; margin-bottom: 5px; padding: 0;" />~ if ${$uid.$musername}{'signature'};
			$memberinfo = "$memberinfo{$musername}$addmembergroup{$musername}";

			$aimad = ${$uid.$musername}{'aim'} ? qq~$menusep${$uid.$musername}{'aim'}~ : '';
			$icqad = ${$uid.$musername}{'icq'} ? qq~$menusep${$uid.$musername}{'icq'}~ : '';
			$yimad = ${$uid.$musername}{'yim'} ? qq~$menusep${$uid.$musername}{'yim'}~ : '';
			$msnad = ${$uid.$musername}{'msn'} ? qq~$menusep${$uid.$musername}{'msn'}~ : '';
			$gtalkad = ${$uid.$musername}{'gtalk'} ? qq~$menusep${$uid.$musername}{'gtalk'}~ : '';
			$skypead = ${$uid.$musername}{'skype'} ? qq~$menusep${$uid.$musername}{'skype'}~ : '';
			$myspacead = ${$uid.$musername}{'myspace'} ? qq~$menusep${$uid.$musername}{'myspace'}~ : '';
			$facebookad = ${$uid.$musername}{'facebook'} ? qq~$menusep${$uid.$musername}{'facebook'}~ : '';

			$usernamelink = &QuickLinks($musername);
			if ($extendedprofiles) {
				require "$sourcedir/ExtendedProfiles.pl";
				$usernamelink = &ext_viewinposts_popup($musername,$usernamelink);
			}
		} elsif ($musername !~ m~Guest~ && $messagedate < $registrationdate) {
			$exmem = 1;
			$memberinfo = $display_txt{'470a'};
			$usernamelink = qq~<b>$mname</b>~;
			$displayname = $display_txt{'470a'};
		} else {
			require "$sourcedir/Decoder.pl";
			$musername = 'Guest';
			$memberinfo = $display_txt{'28'};
			$usernamelink = qq~<b>$mname</b>~;
			$displayname = $mname;
			$cryptmail = &scramble($memail, $musername);
		}
		$usernames_life_quote{$useraccount{$musername}} = $displayname; # for display names in Quotes in LivePreview

		# Insert 2
		if ((!${$uid.$musername}{'hidemail'} || $iamadmin || $allow_hide_email != 1 || $musername eq 'Guest') && !$exmem) {
			$template_email = $menusep . &enc_eMail($img{'email_sm'},$memail,'','');
			if ($iamadmin) { $template_email =~ s~title=\\"$img_txt{'69'}\\"~title=\\"$memail\\"~; }
		}
		if ($iamguest) { $template_email = ''; }

		$counterwords = $counter != 0 ? "$display_txt{'146'} #$counter - " : "";

		# Print the post and user info for the poster.
		my $outblock = $messageblock;
		my $posthandelblock = $posthandellist;
		my $contactblock = $contactlist;

		($msub, undef) = &Split_Splice_Move($msub,0);
		$msub ||= $display_txt{'24'};
		&ToChars($msub);
		$msub = &Censor($msub);

		$message = &Censor($postmessage);
		&wrap;
		($message,$movedflag) = &Split_Splice_Move($message,$viewnum);
		if ($enable_ubbc) {
			if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
			&DoUBBC;
		}
		&wrap2;
		&ToChars($message);

		if ($icanbypass) { $template_modify = qq~$menusep<a href="$scripturl?board=$currentboard;action=modify;message=$counter;thread=$viewnum" onclick="return confirm('$display_txt{'modifyinlocked'}');">$img{'modify'}</a> ~; }

		if ($mstate !~ /l/i) {
			if ($replybutton) {
				my $quote_mname = $displayname;
				$quote_mname =~ s/'/\\'/g;
				$usernamelink = qq~<a href="javascript:void(AddText('[color=$quoteuser_color]@[/color] [b]$quote_mname\[/b]\\r\\n\\r\\n'))"><img src="$imagesdir/qquname.gif" border="0" alt="$display_txt{'146n'}" title="$display_txt{'146n'}" /></a> $usernamelink~ if $enable_quickreply && $enable_quoteuser && (!$iamguest || $enable_guestposting);

				if (!$movedflag || $iamadmin || $iamgmod || $iammod) {
					if ($enable_quickreply) {
						$quote_mname = $useraccount{$musername};
						$quote_mname =~ s/'/\\'/g;
						if ($enable_markquote) {
							$outblock =~ s/(<div)( class="$messageclass" style="float: left; width: 99%; overflow: auto;">)/$1 onmouseup="get_selection($counter);"$2/i;
							$template_quote = qq~$menusep<a href="javascript:void(quoteSelection('$quote_mname',$viewnum,$counter,$mdate,''))">$img{'mquote'}</a>~;
						} else {
							$template_quote = '';
						}
						if ($enable_quickjump) {
							if (length($postmessage) <= $quick_quotelength) {
								my $quickmessage = $postmessage;
								if (!$nestedquotes) {
									$quickmessage =~ s~(<(br|p).*?>){0,1}\[quote([^\]]*)\](.*?)\[/quote([^\]]*)\](<(br|p).*?>){0,1}~<br />~ig;
								}
								$quickmessage =~ s/<(br|p).*?>/\\r\\n/ig;
								$quickmessage =~ s/'/\\'/g;
								$template_quote .= qq~$menusep<a href="javascript:void(quoteSelection('$quote_mname',$viewnum,$counter,$mdate,'$quickmessage'))">$img{'quote'}</a>~;
							} else {
								$template_quote .= qq~$menusep<a href="javascript:void(quick_quote_confirm('$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;quote=$counter;title=PostReply'))">$img{'quote'}</a>~;
							}
						} else {
							$template_quote .= qq~$menusep<a href="$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;quote=$counter;title=PostReply">$img{'quote'}</a>~;
						}
					} else {
						$template_quote = qq~$menusep<a href="$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;quote=$counter;title=PostReply">$img{'quote'}</a>~;
					}
				}
			}
			if ($sessionvalid == 1 && ($iamadmin || $iamgmod || $iammod || ($username eq $musername && !$exmem && (!$tlnomodflag || $date < $mdate + ($tlnomodtime * 3600 * 24))))) {
				$template_modify = qq~$menusep<a href="$scripturl?board=$currentboard;action=modify;message=$counter;thread=$viewnum">$img{'modify'}</a>~;
			} else {
				$template_modify = '';
			}
			if ($counter > 0 && ($iamadmin || $iamgmod || $iammod) && $sessionvalid == 1) {
				$template_split = qq~$menusep<a href="$scripturl?action=split_splice;board=$currentboard;thread=$viewnum;oldposts=~ . join(',%20', ($counter .. $mreplies)) . qq~;leave=0;newcat=$curcat;newboard=$currentboard;newthread=new;ss_submit=1" onclick="return confirm('$display_txt{'split_confirm'}');">$img{'admin_split'}</a>~;
			}
			if ($sessionvalid == 1 && ($iamadmin || $iamgmod || $iammod || ($username eq $musername && !$exmem && (!$tlnodelflag || $date < $mdate + ($tlnodeltime * 3600 * 24))))) {
				$template_delete = qq~$menusep<span style="cursor: pointer; cursor: hand;" onclick="if(confirm('$display_txt{'rempost'}')) {uncheckAllBut($counter);}">$img{'delete'}</span>~;
				if ((($iammod && $mdmod == 1) || ($iamadmin && $mdadmin == 1) || ($iamgmod && $mdglobal == 1)) && $sessionvalid == 1) {
					$template_admin = qq~<input type="checkbox" class="$css" style="border: 0px;" name="del$counter" value="$counter" />~;
				} else {
					# need to set visibility to hidden - used for regular users to delete their posts too,
					$template_admin = qq~ <input type="checkbox" class="$css" style="border: 0px; visibility: hidden; display: none;" name="del$counter" value="$counter" />~;
				}
			} else {
				$template_delete = '';
				$template_admin = qq~ <input type="checkbox" class="$css" style="border: 0px; visibility: hidden; display: none;" name="del$counter" value="$counter" />~;
			}
		}

		$msgimg = qq~<a href="$scripturl?num=$viewnum/$counter#$counter"><img src="$imagesdir/$micon.gif" alt="" border="0" style="vertical-align: middle;" /></a>~;
		$ipimg = qq~<img src="$imagesdir/ip.gif" alt="" border="0" style="vertical-align: middle;" />~;
		if ($extendedprofiles) {
			require "$sourcedir/ExtendedProfiles.pl";
			$template_ext_prof = &ext_viewinposts($musername);
		}

		# Jump to the "NEW" Post.
		$usernamelink = qq~<a name="new"></a>$usernamelink~ if $newestpost && $newestpost == $counter;

		$posthandelblock =~ s/({|<)yabb quote(}|>)/$template_quote/g;
		$posthandelblock =~ s/({|<)yabb modify(}|>)/$template_modify/g;
		$posthandelblock =~ s/({|<)yabb split(}|>)/$template_split/g;
		$posthandelblock =~ s/({|<)yabb delete(}|>)/$template_delete/g;
		$posthandelblock =~ s/({|<)yabb admin(}|>)/$template_admin/g;
		$posthandelblock =~ s/({|<)yabb modalert(}|>)/$PMAlertButton/g;
		$posthandelblock =~ s/\Q$menusep//i;

		$contactblock =~ s/({|<)yabb email(}|>)/$template_email/g;
		$contactblock =~ s/({|<)yabb profile(}|>)/$template_profile/g;
		$contactblock =~ s/({|<)yabb pm(}|>)/$template_pm/g;
		$contactblock =~ s/({|<)yabb www(}|>)/$template_www/g;
		$contactblock =~ s/({|<)yabb aim(}|>)/$aimad/g;
		$contactblock =~ s/({|<)yabb yim(}|>)/$yimad/g;
		$contactblock =~ s/({|<)yabb icq(}|>)/$icqad/g;
		$contactblock =~ s/({|<)yabb msn(}|>)/$msnad/g;
		$contactblock =~ s/({|<)yabb gtalk(}|>)/$gtalkad/g;
		$contactblock =~ s/({|<)yabb skype(}|>)/$skypead/g;
		$contactblock =~ s/({|<)yabb myspace(}|>)/$myspacead/g;
		$contactblock =~ s/({|<)yabb facebook(}|>)/$facebookad/g;
		$contactblock =~ s/({|<)yabb addbuddy(}|>)/$addbuddy/g;
		$contactblock =~ s/\Q$menusep//i;

		$outblock =~ s/({|<)yabb images(}|>)/$imagesdir/g;
		$outblock =~ s/({|<)yabb messageoptions(}|>)/$msgcontrol/g;
		$outblock =~ s/({|<)yabb memberinfo(}|>)/$memberinfo/g;
		$outblock =~ s/({|<)yabb userlink(}|>)/$usernamelink/g;
		$outblock =~ s/({|<)yabb location(}|>)/$userlocation/g;
		$outblock =~ s/({|<)yabb stars(}|>)/$memberstar{$musername}/g;
		$outblock =~ s/({|<)yabb subject(}|>)/$msub/g;
		$outblock =~ s/({|<)yabb msgimg(}|>)/$msgimg/g;
		$outblock =~ s/({|<)yabb msgdate(}|>)/$messdate/g;
		$outblock =~ s/({|<)yabb replycount(}|>)/$counterwords/g;
		$outblock =~ s/({|<)yabb count(}|>)/$counter/g;
		$outblock =~ s/({|<)yabb att(}|>)/$attachment/g;
		$outblock =~ s/({|<)yabb css(}|>)/$css/g;
		$outblock =~ s/({|<)yabb gender(}|>)/${$uid.$musername}{'gender'}/g;
		$outblock =~ s/({|<)yabb ext_prof(}|>)/$template_ext_prof/g;
		$outblock =~ s/({|<)yabb postinfo(}|>)/$template_postinfo/g;
		$outblock =~ s/({|<)yabb usertext(}|>)/${$uid.$musername}{'usertext'}/g;
		$outblock =~ s/({|<)yabb userpic(}|>)/${$uid.$musername}{'userpic'}/g;
		$outblock =~ s/({|<)yabb message(}|>)/$message/g;
		$outblock =~ s/({|<)yabb showatt(}|>)/$showattach/g;
		$outblock =~ s/({|<)yabb showatthr(}|>)/$showattachhr/g;
		$outblock =~ s/({|<)yabb modified(}|>)/$lastmodified/g;
		$outblock =~ s/({|<)yabb signature(}|>)/${$uid.$musername}{'signature'}/g;
		$outblock =~ s/({|<)yabb signaturehr(}|>)/$signature_hr/g;
		$outblock =~ s/({|<)yabb ipimg(}|>)/$ipimg/g;
		$outblock =~ s/({|<)yabb ip(}|>)/$mip/g;
		$outblock =~ s/({|<)yabb posthandellist(}|>)/$posthandelblock/g;
		$outblock =~ s/({|<)yabb contactlist(}|>)/$contactblock/g;
		if ($accept_permalink == 1){
			$outblock =~ s/({|<)yabb permalink(}|>)/$display_permalink/g;
		} else {
			$outblock =~ s/({|<)yabb permalink(}|>)//g;
		}
		$outblock =~ s/({|<)yabb useronline(}|>)/$userOnline/g;
		$outblock  =~ s/({|<)yabb isbuddy(}|>)/$buddyad/g;

		$tmpoutblock .= $outblock;

		$counter += !$ttsreverse ? 1 : -1;
	}
	undef %UserPM_Level;
	# Insert 4

	# Insert 5
	my ($template_remove, $template_splice, $template_lock, $template_hide, $template_sticky, $template_multidelete);
	if (($iammod || $iamadmin || $iamgmod) && $sessionvalid == 1) {
		$template_remove = qq~$menusep<a href="javascript:document.removethread.submit();" onclick="return confirm('$display_txt{'162'}')"> $img{'admin_rem'}</a>~;

		$template_splice = qq~$menusep<a href="javascript:void(window.open('$scripturl?action=split_splice;board=$currentboard;thread=$viewnum;oldposts=all;leave=0;newcat=$curcat;newboard=$currentboard;position=end','_blank','width=800,height=650,scrollbars=yes,resizable=yes,menubar=no,toolbar=no,top=150,left=150'))">$img{'admin_move_split_splice'}</a>~;

		$template_lock = qq~$menusep<a href="$scripturl?action=lock;thread=$viewnum">$img{'admin_lock'}</a>~;
		$template_hide = qq~$menusep<a href="$scripturl?action=hide;thread=$viewnum">$img{'hide'}</a>~;
		$template_sticky = qq~$menusep<a href="$scripturl?action=sticky;thread=$viewnum">$img{'admin_sticky'}</a>~;
		if (${$mnum}{'board'} eq $annboard) { $template_sticky = ''; }
	}
	if ((($iammod && $mdmod == 1) || ($iamadmin && $mdadmin == 1) || ($iamgmod && $mdglobal == 1)) && $sessionvalid == 1) {
		if ($mstate !~ /l/i) {
			$template_multidelete = qq~$menusep<a href="javascript:document.multidel.submit();" onclick="return confirm('$display_txt{'739'}')">$img{'admin_del'}</a>~;
		}
	}

	if ($template_viewers) {
		$topic_viewers = qq~
	<tr>
		<td class="windowbg" valign="middle" align="left">
			$display_txt{'644'} ($topviewers): $template_viewers
		</td>
	</tr>
~;
	}

	# Mark as read button has no use in global announcements or for guests
	if ($currentboard ne $annboard && !$iamguest) {
		$mark_unread = qq~$menusep<a href="$scripturl?action=markunread;thread=$viewnum;board=$currentboard">$img{'markunread'}</a>~;
	}

	# Template it

	$tabsep = qq~<img src="$imagesdir/tabsep211.png" border="0" alt="" style="vertical-align: middle;" />~;
	$yynavback = qq~$tabsep <a href="$scripturl">&#171; $img_txt{'103'}</a> $tabsep $navback $tabsep~;
	$yynavigation = qq~&rsaquo; $template_cat &rsaquo; $template_board &rsaquo; $msubthread~;
	# Create link to modify displayed post order if allowed
	my $curthreadurl = (!$iamguest and $ttsureverse) ? qq~<a title="$display_txt{'reverse'}" href="$scripturl?num=$viewnum;start=~ . (!$ttsreverse ? $mreplies : 0) . qq~;action=~ . ($userthreadpage == 1 ? 'threadpagetext' : 'threadpagedrop') . qq~;reversetopic=$ttsreverse"><img src="$imagesdir/arrow_~ . ($ttsreverse ? 'up' : 'down') . qq~.gif" border="0" alt="" style="vertical-align: middle;" /> $msubthread</a>~ : $msubthread;

	$threadhandellist =~ s/({|<)yabb markunread(}|>)/$mark_unread/g;
	$threadhandellist =~ s/({|<)yabb reply(}|>)/$replybutton/g;
	$threadhandellist =~ s/({|<)yabb poll(}|>)/$pollbutton/g;
	$threadhandellist =~ s/({|<)yabb notify(}|>)/$notify/g;
	$threadhandellist =~ s/({|<)yabb favorite(}|>)/$template_favorite/g;
	$threadhandellist =~ s/({|<)yabb sendtopic(}|>)/$template_sendtopic/g;
	$threadhandellist =~ s/({|<)yabb print(}|>)/$template_print/g;
	$threadhandellist =~ s/\Q$menusep//i;

	$adminhandellist =~ s/({|<)yabb remove(}|>)/$template_remove/g;
	$adminhandellist =~ s/({|<)yabb splice(}|>)/$template_splice/g;
	$adminhandellist =~ s/({|<)yabb lock(}|>)/$template_lock/g;
	$adminhandellist =~ s/({|<)yabb hide(}|>)/$template_hide/g;
	$adminhandellist =~ s/({|<)yabb sticky(}|>)/$template_sticky/g;
	$adminhandellist =~ s/({|<)yabb multidelete(}|>)/$template_multidelete/g;
	$adminhandellist =~ s/\Q$menusep//i;

	$display_template =~ s/({|<)yabb home(}|>)/$template_home/g;
	$display_template =~ s/({|<)yabb category(}|>)/$template_cat/g;
	$display_template =~ s/({|<)yabb board(}|>)/$template_board/g;
	$display_template =~ s/({|<)yabb moderators(}|>)/$template_mods/g;
	$display_template =~ s/({|<)yabb topicviewers(}|>)/$topic_viewers/g;
	$display_template =~ s/({|<)yabb prev(}|>)/$prevlink/g;
	$display_template =~ s/({|<)yabb next(}|>)/$nextlink/g;
	$display_template =~ s/({|<)yabb pageindex top(}|>)/$pageindex1/g;
	$display_template =~ s/({|<)yabb pageindex bottom(}|>)/$pageindex2/g;

	$display_template =~ s/({|<)yabb threadhandellist(}|>)/$threadhandellist/g;
	$display_template =~ s/({|<)yabb threadimage(}|>)/$template_threadimage/g;
	$display_template =~ s/({|<)yabb threadurl(}|>)/$curthreadurl/g;
	$tmpviews = ${$viewnum}{'views'} - 1;
	$tmpviews = &NumberFormat($tmpviews);
	$display_template =~ s/({|<)yabb views(}|>)/ $tmpviews /eg;
	if (($iamadmin || $iamgmod || $iammod) && $sessionvalid == 1) {
		# Board=$currentboard is necessary for multidel - DO NOT REMOVE!!
		# This form is necessary to allow thread deletion in locked topics.
		$formstart .= qq~<form name="removethread" action="$scripturl?action=removethread" method="post" style="display: inline">
		<input type="hidden" name="thread" value="$viewnum" />
		</form>~;

	}
	$formstart .= qq~<form name="multidel" action="$scripturl?board=$currentboard;action=multidel;thread=$viewnum/~ . (!$ttsreverse ? $start : $mreplies - $start) . qq~" method="post" style="display: inline">~;
	$formend = qq~</form>~;

	$display_template =~ s/({|<)yabb multistart(}|>)/$formstart/g;
	$display_template =~ s/({|<)yabb multiend(}|>)/$formend/g;

	$display_template =~ s/({|<)yabb pollmain(}|>)/$template_pollmain/g;
	$display_template =~ s/({|<)yabb postsblock(}|>)/$tmpoutblock/g;
	$display_template =~ s/({|<)yabb adminhandellist(}|>)/$adminhandellist/g;
	$display_template =~ s/({|<)yabb forumselect(}|>)/$selecthtml/g;

	$yymain .= qq~
	$display_template
	<script language="JavaScript1.2" type="text/javascript">
	<!-- //
	function uncheckAllBut(counter) {
		for (var i = 0; i < document.forms["multidel"].length; ++i) {
			if (document.forms["multidel"].elements[i].type == "checkbox") document.forms["multidel"].elements[i].checked = false;
		}
		document.forms["multidel"].elements["del"+counter].checked = true;
		document.multidel.submit();
	}~;


	if ($sendtopicmail) {
		my ($esubject,$emessage);
		if ($sendtopicmail > 1) {
			&LoadLanguage('SendTopic');
			&LoadLanguage('Email');
			require "$sourcedir/Mailer.pl";
			$esubject = &uri_escape("$sendtopic_txt{'118'}: $msubthread ($sendtopic_txt{'318'} ${$uid.$username}{'realname'})");
			$emessage = &uri_escape( &template_email($sendtopicemail, {'toname' => '?????', 'subject' => $msubthread, 'displayname' => ${$uid.$username}{'realname'}, 'num' => $viewnum}) );
		}
		$yymain .= qq~

	function sendtopicmail(action) {
		var x = "mailto:?subject=$esubject&body=$emessage";
		if (action == 3) {
			Check = confirm('$display_txt{'sendtopicemail'}');
			if (Check != true) x = '';
		}
		if (action == 1 || x == '') x = "$scripturl?action=sendtopic;topic=$viewnum";
		window.location.href = x;
	}~;
	}

$yymain .= qq~

	$pageindexjs
	function ListPages(tid) { window.open('$scripturl?action=pages;num='+tid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
	// -->
	</script>
	~;

	if ($img_greybox) {
		$yyinlinestyle .= qq~<link href="$yyhtml_root/greybox/gb_styles.css" rel="stylesheet" type="text/css" />\n~;
		$yyjavascript .= qq~
var GB_ROOT_DIR = "$yyhtml_root/greybox/";
// -->
</script>
<script type="text/javascript" src="$yyhtml_root/AJS.js"></script>
<script type="text/javascript" src="$yyhtml_root/AJS_fx.js"></script>
<script type="text/javascript" src="$yyhtml_root/greybox/gb_scripts.js"></script>
<script type="text/javascript">
<!--~;
	}

	$yytitle = $msubthread;
	if ($replybutton and $enable_quickreply) {
		$yymain =~ s~(<!-- Threads Admin Button Bar start -->.*?</td>)~$1<td align="right">{yabb forumjump}</td>~s;
		require "$sourcedir/Post.pl";
		$action = 'post';
		$INFO{'title'} = 'PostReply';
		$Quick_Post = 1;
		$message = '';
		&Post;
	}
	&template;
}

sub NextPrev {
	fopen(MSGTXT, "$boardsdir/$currentboard.txt") || &fatal_error("cannot_open","$boardsdir/$currentboard.txt", 1);
	my @threadlist = <MSGTXT>;
	fclose(MSGTXT);

	$thevirboard = qq~num=~;
	if ($vircurrentboard) {
		fopen(MSGTXT, "$boardsdir/$vircurrentboard.txt") || &fatal_error("cannot_open","$boardsdir/$vircurrentboard.txt", 1);
		my @virthreadlist = <MSGTXT>;
		fclose(MSGTXT);
		push(@threadlist, @virthreadlist);
		undef @virthreadlist;
		$thevirboard = qq~virboard=$vircurrentboard;num=~;
	}

	my ($countsticky,$countnosticky) = (0,0);
	my (@stickythreadlist,@nostickythreadlist);
	for ($i = 0; $i < @threadlist; $i++) {
		my $threadstatus = (split /\|/, $threadlist[$i])[8];
		if ($threadstatus =~ /h/i && !$iamadmin && !$iamgmod && !$iammod) { next; }
		if ($threadstatus =~ /s/i || $threadstatus =~ /a/i) {
			$stickythreadlist[$countsticky] = $threadlist[$i];
			$countsticky++;
		} else {
			$nostickythreadlist[$countnosticky] = $threadlist[$i];
			$countnosticky++;
		}
	}

	@threadlist = ();
	if ($countsticky)   { push(@threadlist, @stickythreadlist); }
	if ($countnosticky) { push(@threadlist, @nostickythreadlist); }

	my $name = $_[0];
	my $lastvisit = int($_[1]);
	my $is = 0;
	my ($mnum,$mdate,$datecount);
	for ($i = 0; $i < @threadlist; $i++) {
		($mnum, undef, undef, undef, $mdate, undef) = split(/\|/, $threadlist[$i], 6);
		if ($mnum == $name) {
			if ($i > 0) {
				($prev, undef) = split(/\|/, $threadlist[$i - 1], 2);
				$prevlink = qq~<a href="$scripturl?$thevirboard$prev">$display_txt{'768'}</a>~;
			} else {
				$prevlink = $display_txt{'766'};
			}
			if ($i < $#threadlist) {
				($next, undef) = split(/\|/, $threadlist[$i + 1], 2);
				$nextlink = qq~<a href="$scripturl?$thevirboard$next">$display_txt{'767'}</a>~;
			} else {
				$nextlink = $display_txt{'766'};
			}
			$is = 1;
		}
		$datecount++ if $mdate > $lastvisit;
		last if $is && $datecount > 1;
	}

	if (!$is) { undef $INFO{'num'}; &redirectinternal; } # if topic not found
	$datecount;
}

sub SetMsn {
	$msnstyle = qq~<link rel="stylesheet" href="$forumstylesurl/$usestyle.css" type="text/css" />~;
	$msnstyle =~ s~$usestyle\/~~g;
	my $msnname = $INFO{'msnname'};
	if (!${$uid.$msnname}{'password'}) { &LoadUser($msnname); }
	$msnuser = ${$uid.$msnname}{'msn'};

	print qq~Content-type: text/html\n\n~;
	print qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>$msntxt{'5'}</title>
$msnstyle
</head>
<body class="windowbg2" style="margin: 0px; padding: 0px;">
<table border="0" width="100%" cellspacing="1" cellpadding="4" class="bordercolor">
	<tr>
		<td class="titlebg" align="left" height="22">
		<img src="$defaultimagesdir/msn.gif" width="16" height="14" alt="" title="" border="0" /> $msntxt{'5'}
		</td>
	</tr>
	<tr>
		<td class="windowbg" align="left" height="58">
		<img src="$defaultimagesdir/msn.gif" width="16" height="16" style="vertical-align: middle;" alt="${$uid.$msnname}{'realname'}" title="${$uid.$msnname}{'realname'}" border="0" /> $msnuser<br /><br />
		</td>
	</tr>
</table>

<script language="JavaScript1.2" type="text/javascript">
<!--
function sendmsn(msnto) {
	var msnControl = new ActiveXObject('Messenger.UIAutomation.1');
	if(!msnControl.MyContacts.Count) {
		alert("$msntxt{'3'}");
		return false;
	}
	msnControl.AutoSignin();
	msnControl.InstantMessage(msnto);
	window.close();
}

function addtomsn(msnto) {
	var msnControl = new ActiveXObject('Messenger.UIAutomation.1');
	msnControl.AutoSignin();
	msnControl.AddContact(0, msnto);
	window.close();
}

function notOnline() {
	alert("$msntxt{'3'}");
	return true;
}

if(navigator.appName == "Microsoft Internet Explorer" && navigator.appVersion.slice(0,4) >= 4 && navigator.userAgent.indexOf("Opera") < 0) {
	var msnControl = new ActiveXObject('Messenger.UIAutomation.1');
	document.write("<input type='button' value='$msntxt{'1'}' style='font-size: 10px' onclick=sendmsn('$msnuser') />");
	document.write("<input type='button' value='$msntxt{'2'}' style='font-size: 10px' onclick=addtomsn('$msnuser') />");
} else {
	document.write("$msntxt{'4'}<br /><br />");
}

window.onerror = notOnline;
//-->
</script>

</body>
</html>
~;

}

sub SetGtalk {
	$gtalkstyle = qq~<link rel="stylesheet" href="$forumstylesurl/$usestyle.css" type="text/css" />~;
	$gtalkstyle =~ s~$usestyle\/~~g;
	my $gtalkname = $INFO{'gtalkname'};
	if (!${$uid.$gtalkname}{'password'}) { &LoadUser($gtalkname); }
	$gtalkuser = ${$uid.$gtalkname}{'gtalk'};

	print qq~Content-type: text/html\n\n~;
	print qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Google Talk</title>
$gtalkstyle
</head>
<body class="windowbg2" style="margin: 0px; padding: 0px;">
<table border="0" width="100%" cellspacing="1" cellpadding="4" class="bordercolor">
  <tr>
    <td class="titlebg" align="left" height="22">
      <img src="$defaultimagesdir/gtalk2.gif" width="16" height="14" alt="" title="" border="0" />
       Google Talk
    </td>
  </tr>
  <tr>
    <td class="windowbg" align="left" height="58">
      <img src="$defaultimagesdir/gtalk2.gif" width="16" height="14" style="vertical-align: middle;" alt="${$uid.$gtalkname}{'realname'}" title="${$uid.$gtalkname}{'realname'}" border='0' /> $gtalkuser<br /><br />
    </td>
  </tr>
</table>
</body>
</html>
~;
}

sub ThreadPageindex {
	#my ($msindx, $trindx, $mbindx);
	my ($msindx, $trindx, $mbindx,$pmindx) = split(/\|/, ${$uid.$username}{'pageindex'});
	if ($INFO{'action'} eq "threadpagedrop") {
		${$uid.$username}{'pageindex'} = qq~$msindx|0|$mbindx|$pmindx~;
	}
	if ($INFO{'action'} eq "threadpagetext") {
		${$uid.$username}{'pageindex'} = qq~$msindx|1|$mbindx|$pmindx~;
	}
	if (exists($INFO{'reversetopic'})) {
		${$uid.$username}{'reversetopic'} = $INFO{'reversetopic'} ? 0 : 1;
	}
	&UserAccount($username, "update");
	$yySetLocation = qq~$scripturl?num=$INFO{'num'}/$INFO{'start'}~;
	&redirectexit;
}

sub undumplog { # Used to mark a thread as unread
	# Load the log file
	&getlog;

	&dumplog("$INFO{'thread'}--unread") if $yyuserlog{$INFO{'thread'}};

	&redirectinternal;
}

1;