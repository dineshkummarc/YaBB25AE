###############################################################################
# Recent.pl                                                                   #
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

$recentplver = 'YaBB 2.5 AE $Revision: 1.19 $';
if ($action eq 'detailedversion') { return 1; }

# Sub RecentTopics shows all the most recently posted topics
# Meaning each thread will show up ONCE in the list.

# Sub RecentPosts will show the X last POSTS
# Even if they are all from the same thread

sub RecentTopics {
	&spam_protection;

	my $display = $INFO{'display'} || 10;
	if ($display < 0) { $display = 5; }
	elsif ($display > $maxrecentdisplay) { $display = $maxrecentdisplay; }
	my (@memset, @categories, %data, $numfound, $curcat, %catid, %catname, %cataccess, %catboards, $openmemgr, @membergroups, %openmemgr, $curboard, @threads, @boardinfo, $i, $c, @messages, $tnum, $tsub, $tname, $temail, $tdate, $treplies, $tusername, $ticon, $tstate, $mname, $memail, $mdate, $musername, $micon, $mattach, $mip, $mns, $mtime, $counter, $board, $notify);
	$numfound = 0;

	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	foreach $catid (@categoryorder) {
		$boardlist = $cat{$catid};

		(@bdlist) = split(/\,/, $boardlist);
		($catname, $catperms) = split(/\|/, $catinfo{$catid});
		$cataccess = &CatAccess($catperms);
		if (!$cataccess) { next; }

		foreach $curboard (@bdlist) {
			($boardname{$curboard}, $boardperms, $boardview) = split(/\|/, $board{$curboard});

			my $access = &AccessCheck($curboard, '', $boardperms);
			if (!$iamadmin && $access ne "granted") { next; }

			$catid{$curboard} = $catid;
			$catname{$curboard} = $catname;

			fopen(REC_BDTXT, "$boardsdir/$curboard.txt");
			for ($i = 0; $i < $display && ($buffer = <REC_BDTXT>); $i++) {
				($tnum, $tsub, $tname, $temail, $tdate, $treplies, $tusername, $ticon, $tstate) = split(/\|/, $buffer);
				chomp $tstate;
				if ($tstate !~ /h/ || $iamadmin || $iamgmod) {
					$mtime = $tdate;
					$data[$numfound] = "$mtime|$curboard|$tnum|$treplies|$tusername|$tname|$tstate";
					$numfound++;
				}
			}
			fclose(REC_BDTXT);
		}
	}

	@data = sort {$b <=> $a} @data;
	$numfound = 0;

	for ($i = 0; $i < @data; $i++) {
		($mtime, $curboard, $tnum, $treplies, $tusername, $tname, $tstate) = split(/\|/, $data[$i]);
		$tstart = $mtime;
		fopen(REC_THRETXT, "$datadir/$tnum.txt") || next;
		while (<REC_THRETXT>) { $message = $_; }

		# get only the last post for this thread.
		fclose(REC_THRETXT);
		chomp $message;

		if ($message) {
			($msub, $mname, $memail, $mdate, $musername, $micon, $mattach, $mip, $message, $mns) = split(/\|/, $message);
			$messages[$numfound] = "$curboard|$tnum|$treplies|$tusername|$tname|$msub|$mname|$memail|$mdate|$musername|$micon|$mattach|$mip|$message|$mns|$tstate|$tstart";
			$numfound++;
		}
		if ($numfound == $display) { last; }
	}

	if ($numfound > 0) {
		$counter = 1;
		&LoadCensorList;
	} else {
		$yymain .= qq~<hr class="hr" /><b>$maintxt{'170'}</b><hr />~;
	}

	for ($i = 0; $i < $numfound; $i++) {
		($board, $tnum, $c, $tusername, $tname, $msub, $mname, $memail, $mdate, $musername, $micon, $mattach, $mip, $message, $mns, $tstate, $trstart) = split(/\|/, $messages[$i]);
		$displayname = $mname;

		if ($tusername ne 'Guest' && -e ("$memberdir/$tusername.vars")) { &LoadUser($tusername); }
		if (${$uid.$tusername}{'regtime'}) {
			$registrationdate = ${$uid.$tusername}{'regtime'};
		} else {
			$registrationdate = $date;
		}

		if (${$uid.$tusername}{'regdate'} && $trstart > $registrationdate) {
			$tname = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$tusername}">${$uid.$tusername}{'realname'}</a>~;
		} elsif ($tusername !~ m~Guest~ && $trstart < $registrationdate) {
			$tname = qq~$tname - $maintxt{'470a'}~;
		} else {
			$tname = "$tname ($maintxt{'28'})";
		}

		if ($musername ne 'Guest' && -e ("$memberdir/$musername.vars")) { &LoadUser($musername); }
		if (${$uid.$musername}{'regtime'}) {
			$registrationdate = ${$uid.$musername}{'regtime'};
		} else {
			$registrationdate = $date;
		}

		if (${$uid.$musername}{'regdate'} && $mdate > $registrationdate) {
			$mname = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">${$uid.$musername}{'realname'}</a>~;
		} elsif ($musername !~ m~Guest~ && $mdate < $registrationdate) {
			$mname = qq~$mname - $maintxt{'470a'}~;
		} else {
			$mname = "$mname ($maintxt{'28'})";
		}

		&wrap;
		($message, undef) = &Split_Splice_Move($message,$tnum);
		if ($enable_ubbc) {
			$ns = $mns;
			if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
			&DoUBBC;
		}
		&wrap2;
		&ToChars($message);
		$message = &Censor($message);

		($msub, undef) = &Split_Splice_Move($msub,0);
		&ToChars($msub);
		$msub = &Censor($msub);

		if ($iamguest) {
			$notify = ''; 
		} else {
			if (${$uid.$username}{'thread_notifications'} =~ /\b$tnum\b/) {
				$notify = qq~$menusep<a href="$scripturl?action=notify3;num=$tnum/$c;oldnotify=1">$img{'del_notify'}</a>~;
			} else {
				$notify = qq~$menusep<a href="$scripturl?action=notify2;num=$tnum/$c;oldnotify=1">$img{'add_notify'}</a>~;
			}
		}

		$mdate = &timeformat($mdate);

		$yymain .= qq~
<table border="0" width="100%" cellspacing="1" class="bordercolor" style="table-layout: fixed;">
	<tr>
		<td align="center" width="5%" class="titlebg">$counter</td>
		<td align="left" width="95%" class="titlebg">&nbsp;<a href="$scripturl?catselect=$catid{$board}"><u>$catname{$board}</u></a> / <a href="$scripturl?board=$board"><u>$boardname{$board}</u></a> / <a href="$scripturl?num=$tnum/$c#$c"><u>$msub</u></a><br />
		&nbsp;<span class="small">$maintxt{'30'}: $mdate</span>&nbsp;</td>
	</tr>
	<tr>
		<td colspan="2">
			<table border="0" width="100%" class="catbg">
				<tr>
					<td align="left">$maintxt{'109'} $tname | $maintxt{'197'} $mname</td>
					<td align="right">&nbsp;~;

		if ($tstate != 1 && (!$iamguest || $enable_guestposting)) {
			$yymain .= qq~<a href="$scripturl?board=$board;action=post;num=$tnum/$c#$c;title=PostReply">$img{'reply'}</a>$menusep<a href="$scripturl?board=$board;action=post;num=$tnum;quote=$c;title=PostReply">$img{'recentquote'}</a>$notify &nbsp;~;
		}

		$yymain .= qq~
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td align="left" height="80" colspan="2" class="windowbg2" valign="top"><div class="message" style="float: left; width: 99%; overflow: auto;">$message</div></td>
	</tr>
</table><br />
~;
		++$counter;
	}

	$yynavigation = qq~&rsaquo; $maintxt{'215'}~;
	$yytitle = $maintxt{'215'};
	&template;
}

sub RecentPosts {
	&spam_protection;

	my $display = $FORM{'display'} ||= 10;
	if ($display < 0) { $display = 5; }
	elsif ($display > $maxrecentdisplay) { $display = $maxrecentdisplay; } 
	my (@memset, @categories, %data, $numfound, $curcat, %catid, %catname, %cataccess, %catboards, $openmemgr, @membergroups, %openmemgr, $curboard, @threads, @boardinfo, $i, $c, @messages, $tnum, $tsub, $tname, $temail, $tdate, $treplies, $tusername, $ticon, $tstate, $mname, $memail, $mdate, $musername, $micon, $mattach, $mip, $mns, $mtime, $counter, $board, $notify);
	$numfound = 0;

	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	foreach $catid (@categoryorder) {
		$boardlist = $cat{$catid};

		(@bdlist) = split(/\,/, $boardlist);
		($catname, $catperms) = split(/\|/, $catinfo{$catid});
		$cataccess = &CatAccess($catperms);
		if (!$cataccess) { next; }

		foreach $curboard (@bdlist) {
			($boardname{$curboard}, $boardperms, $boardview) = split(/\|/, $board{$curboard});

			my $access = &AccessCheck($curboard, '', $boardperms);
			if (!$iamadmin && $access ne "granted") { next; }

			$catid{$curboard} = $catid;
			$catname{$curboard} = $catname;

			fopen(REC_BDTXT, "$boardsdir/$curboard.txt");
			for ($i = 0; $i < $display && ($buffer = <REC_BDTXT>); $i++) {
				($tnum, $tsub, $tname, $temail, $tdate, $treplies, $tusername, $ticon, $tstate) = split(/\|/, $buffer);
				chomp $tstate;
				if ($tstate !~ /h/ || $iamadmin || $iamgmod) {
					$mtime = $tdate;
					$data[$numfound] = "$mtime|$curboard|$tnum|$treplies|$tusername|$tname|$tstate";
					$numfound++;
				}
			}
			fclose(REC_BDTXT);
		}
	}

	@data = sort {$b <=> $a} @data;

	$numfound    = 0;
	$threadfound = @data > $display ? $display : @data;

	for ($i = 0; $i < $threadfound; $i++) {
		($mtime, $curboard, $tnum, $treplies, $tusername, $tname, $tstate) = split(/\|/, $data[$i]);
		# No need to check for hidden topics here, it was done above
		$tstart = $mtime;
		fopen(REC_THRETXT, "$datadir/$tnum.txt") || next;
		@mess = <REC_THRETXT>;
		fclose(REC_THRETXT);

		$threadfrom = @mess > $display ? @mess - $display : 0;
		for ($ii = $threadfrom; $ii < @mess + 1; $ii++) {
			if ($mess[$ii]) {
				($msub, $mname, $memail, $mdate, $musername, $micon, $mattach, $mip, $message, $mns) = split(/\|/, $mess[$ii]);
				$mtime = $mdate;
				$messages[$numfound] = "$mtime|$curboard|$tnum|$ii|$tusername|$tname|$msub|$mname|$memail|$mdate|$musername|$micon|$mattach|$mip|$message|$mns|$tstate|$tstart";
				$numfound++;
			}
		}
	}

	@messages  = sort {$b <=> $a} @messages;

	if ($numfound > 0) {
		if ($numfound > $display) { $numfound = $display; }
		$counter = 1;
		&LoadCensorList;
	} else {
		$yymain .= qq~<hr class="hr"><b>$maintxt{'170'}</b><hr>~;
	}

	for ($i = 0; $i < $numfound; $i++) {
		($dummy, $board, $tnum, $c, $tusername, $tname, $msub, $mname, $memail, $mdate, $musername, $micon, $mattach, $mip, $message, $mns, $tstate, $trstart) = split(/\|/, $messages[$i]);
		$displayname = $mname;

		if ($tusername ne 'Guest' && -e ("$memberdir/$tusername.vars")) { &LoadUser($tusername); }
		if (${$uid.$tusername}{'regtime'}) {
			$registrationdate = ${$uid.$tusername}{'regtime'};
		} else {
			$registrationdate = $date;
		}

		if (${$uid.$tusername}{'regdate'} && $trstart > $registrationdate) {
			$tname = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$tusername}">${$uid.$tusername}{'realname'}</a>~;
		} elsif ($tusername !~ m~Guest~ && $trstart < $registrationdate) {
			$tname = qq~$tname - $maintxt{'470a'}~;
		} else {
			$tname = "$tname ($maintxt{'28'})";
		}

		if ($musername ne 'Guest' && -e ("$memberdir/$musername.vars")) { &LoadUser($musername); }
		if (${$uid.$musername}{'regtime'}) {
			$registrationdate = ${$uid.$musername}{'regtime'};
		} else {
			$registrationdate = $date;
		}

		if (${$uid.$musername}{'regdate'} && $mdate > $registrationdate) {
			$mname = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">${$uid.$musername}{'realname'}</a>~;
		} elsif ($musername !~ m~Guest~ && $mdate < $registrationdate) {
			$mname = qq~$mname - $maintxt{'470a'}~;
		} else {
			$mname = "$mname ($maintxt{'28'})";
		}

		&wrap;
		($message, undef) = &Split_Splice_Move($message,$tnum);
		if ($enable_ubbc) {
			$ns = $mns;
			if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
			&DoUBBC;
		}
		&wrap2;
		&ToChars($message);
		$message = &Censor($message);

		($msub, undef) = &Split_Splice_Move($msub,0);
		&ToChars($msub);
		$msub = &Censor($msub);

		if ($iamguest) {
			$notify = ''; 
		} else {
			if (${$uid.$username}{'thread_notifications'} =~ /\b$tnum\b/) {
				$notify = qq~$menusep<a href="$scripturl?action=notify3;num=$tnum/$c;oldnotify=1">$img{'del_notify'}</a>~;
			} else {
				$notify = qq~$menusep<a href="$scripturl?action=notify2;num=$tnum/$c;oldnotify=1">$img{'add_notify'}</a>~;
			}
		}
		$mdate = &timeformat($mdate);
		$yymain .= qq~
<table border="0" width="100%" cellspacing="1" class="bordercolor" style="table-layout: fixed;">
	<tr>
		<td align="center" width="5%" class="titlebg">$counter</td>
		<td align="left" width="95%" class="titlebg">&nbsp;<a href="$scripturl?catselect=$catid{$board}"><u>$catname{$board}</u></a> / <a href="$scripturl?board=$board"><u>$boardname{$board}</u></a> / <a href="$scripturl?num=$tnum/$c#$c"><u>$msub</u></a><br />
		&nbsp;<span class="small">$maintxt{'30'}: $mdate</span>&nbsp;</td>
	</tr>
	<tr>
		<td colspan="2">
			<table border="0" width="100%" class="catbg">
				<tr>
					<td align="left">$maintxt{'109'} $tname | $maintxt{'197'} $mname</td>
					<td align="right">&nbsp;~;

		if ($tstate != 1 && (!$iamguest || $enable_guestposting)) {
			$yymain .= qq~<a href="$scripturl?board=$board;action=post;num=$tnum/$c#$c;title=PostReply">$img{'reply'}</a>$menusep<a href="$scripturl?board=$board;action=post;num=$tnum;quote=$c;title=PostReply">$img{'recentquote'}</a>$notify &nbsp;~;
		}

		$yymain .= qq~
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td align="left" height="80" colspan="2" class="windowbg2" valign="top"><div style="float: left; width: 99%; overflow: auto;">$message</div></td>
	</tr>
</table><br />
~;
		++$counter;
	}

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

	$yynavigation = qq~&rsaquo; $maintxt{'214'}~;
	$yytitle = $maintxt{'214'};
	&template;
}

1;