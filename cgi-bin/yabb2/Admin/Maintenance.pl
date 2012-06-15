###############################################################################
# Maintenance.pl                                                              #
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

$maintenanceplver = 'YaBB 2.5 AE $Revision: 1.3 $';
if ($action eq 'detailedversion') { return 1; }

sub RebuildMessageIndex {
	&is_admin_or_gmod();

	# Set up the multi-step action
	$time_to_jump = time() + $max_process_time;

	require "$boardsdir/forum.master";

	my %rebuildboards;
	if (!$INFO{'rebuild'}) {
		$yymain .= qq~<b>$admin_txt{'530'}</b>
		<a href="$adminurl?action=rebuildmesindex;rebuild=1"><b>$admin_txt{'531'}</b></a><br />
		($admin_txt{'532'} $max_process_time $admin_txt{'533'}.)~;
		$yytitle = $admin_txt{'506'};
		$action_area = 'rebuildmesindex';
		&AdminTemplate;

	# delete old rebuldings when starting or if maintenance mode was 'off'
	} elsif (!-e "$vardir/maintenance.lock" || (!$INFO{'next'} && $INFO{'rebuild'} == 1)) {
		opendir(BOARDSDIR, $boardsdir) || &admin_fatal_error('cannot_open', "$boardsdir", 1);
		my @blist = grep { /\.tmp$/ } readdir(BOARDSDIR);
		closedir(BOARDSDIR);

		foreach (@blist) { unlink "$boardsdir/$_"; }

		foreach (keys %board) { push(@{$rebuildboards{$_}}, ''); }

		&automaintenance('on');
	}

	if ($INFO{'rebuild'} == 1) {
		require "$admindir/Attachments.pl";
		my %attachfile;

		# storing the 'board' and the 'status' of all threads
		foreach $oldboard (keys %board) {
			my @temparray;
			fopen(OLDBOARD, "$boardsdir/$oldboard.txt") || &admin_fatal_error('cannot_open', "$boardsdir/$oldboard.txt", 1);
			my @temparray = <OLDBOARD>;
			fclose(OLDBOARD);
			chomp(@temparray);

			foreach (@temparray) {
				($mnum, undef, undef, undef, undef, undef, undef, undef, $mstate) = split(/\|/, $_);
				$thread_status{$mnum} = $mstate ? $mstate : "0";
				$thread_boards{$mnum} = $oldboard;
			}
		}

		opendir(TXT, $datadir) || &admin_fatal_error('cannot_open', "$datadir", 1);
		my @threadlist = sort( grep { /\d+\.txt$/ } readdir(TXT) );
		closedir(TXT);

		$totalthreads = @threadlist;
		for (my $j = ($INFO{'next'} || 0); $j < $totalthreads; $j++) {
			$thread = $threadlist[$j];
			$thread =~ s/\.txt$//;

			if ($thread eq '' || !-e "$datadir/$thread.txt" || -s "$datadir/$thread.txt" < 35) {
				unlink("$datadir/$thread.txt");
				unlink("$datadir/$thread.ctb");
				unlink("$datadir/$thread.mail");
				unlink("$datadir/$thread.poll");
				unlink("$datadir/$thread.polled");
				$attachfile{$thread} = undef;
				$INFO{'count_del_threads'}++;
				next;
			}

			if (!-e "$datadir/$thread.ctb") {
				${$thread}{'board'} = '';
			} else {
				# &MessageTotals("load", $thread) not used here
				# for upgraders form 2-2.1 to the actual version.
				fopen(CTB, "$datadir/$thread.ctb",1);
				my @ctb = <CTB>;
				fclose(CTB);
				if ($ctb[0] =~ /###/) { # new format
					foreach (@ctb) {
						if ($_ =~ /^'(.*?)',"(.*?)"/) { ${$thread}{$1} = $2; }
					}
					@repliers = split(",", ${$thread}{'repliers'});
				} else {                # old format
					chomp(@ctb);
					my @tag = qw(board replies views lastposter lastpostdate threadstatus repliers);
					for (my $cnt = 0; 7 > $cnt; $cnt++) {
						${$thread}{$tag[$cnt]} = $ctb[$cnt];
					}
					@repliers = ();
					for (my $repcnt = 7; @ctb > $repcnt ; $repcnt++) {
						push(@repliers, $ctb[$repcnt]);
					}
				}
			}

			# set correct board
			$theboard = exists $thread_boards{$thread} ? $thread_boards{$thread} : ${$thread}{'board'};
			# if boardname is wrong - > put to recycle
			if (!exists $board{$theboard}) {
				if ($binboard) {
					$theboard = $binboard;
				} else {
					unlink("$datadir/$thread.txt");
					unlink("$datadir/$thread.ctb");
					unlink("$datadir/$thread.mail");
					unlink("$datadir/$thread.poll");
					unlink("$datadir/$thread.polled");
					$attachfile{$thread} = undef;
					$INFO{'count_del_threads'}++;
					next;
				}
			}

			fopen(FILETXT, "$datadir/$thread.txt") || &admin_fatal_error('cannot_open', "$datadir/$thread.txt", 1);
			my @threaddata = <FILETXT>;
			fclose(FILETXT);

			@firstinfo = split(/\|/, $threaddata[0]);
			@lastinfo = split(/\|/, $threaddata[$#threaddata]);
			$lastpostdate = sprintf("%010d", $lastinfo[3]);

			# rewrite/create a correct threadnumber.ctb
			${$thread}{'board'} = $theboard;
			${$thread}{'replies'} = $#threaddata;
			${$thread}{'views'} = ${$thread}{'views'} || 1; # is never = 0 !
			${$thread}{'lastposter'} = $lastinfo[4] eq 'Guest' ? qq~Guest-$lastinfo[1]~ : $lastinfo[4];
			${$thread}{'lastpostdate'} = $lastpostdate;
			${$thread}{'threadstatus'} = $thread_status{$thread};
			&MessageTotals("update", $thread);

			push(@{$rebuildboards{$theboard}}, qq~$lastpostdate|$thread|$firstinfo[0]|$firstinfo[1]|$firstinfo[2]|$lastinfo[3]|$#threaddata|$firstinfo[4]|$firstinfo[5]|$thread_status{$thread}\n~);

			if (time() > $time_to_jump && ($j + 1) < $totalthreads) {
				foreach (keys %rebuildboards) {
					fopen(REBBOARD, ">>$boardsdir/$_.tmp") || &admin_fatal_error('cannot_open', "$boardsdir/$_.tmp", 1);
					print REBBOARD @{$rebuildboards{$_}};
					fclose(REBBOARD);
				}

				&RemoveAttachments(\%attachfile);

				&RebuildMessageIndexText($INFO{'rebuild'},$j,$totalthreads);
			}
		}
	
		foreach (keys %rebuildboards) {
			fopen(REBBOARD, ">>$boardsdir/$_.tmp") || &admin_fatal_error('cannot_open', "$boardsdir/$_.tmp", 1);
			print REBBOARD @{$rebuildboards{$_}};
			fclose(REBBOARD);
		}

		&RemoveAttachments(\%attachfile);

		$INFO{'next'} = 0;
		$INFO{'rebuild'} = 2;
	}

	if ($INFO{'rebuild'} == 2) {
		opendir(REBUILDS, $boardsdir);
		my @rebuilds = sort( grep(/\.tmp$/, readdir(REBUILDS)) );
		closedir(REBUILDS);

		$totalrebuilds = @rebuilds;
		for(my $j = 0; $j < $totalrebuilds; $j++) {
			my $boardname = $rebuilds[$j];
			$boardname =~ s/\.tmp$//;

			fopen(FILETXT, "$boardsdir/$boardname.tmp") || &admin_fatal_error('cannot_open', "$boardsdir/$boardname.tmp", 1);
			my @tempboard = <FILETXT>;
			fclose(FILETXT);

			fopen(NEWBOARD, ">$boardsdir/$boardname.txt") || &admin_fatal_error('cannot_open', "$boardsdir/$boardname.txt", 1);
			print NEWBOARD map({ s/^.*?\|//; $_; } sort({ lc($b) cmp lc($a) } @tempboard) );
			fclose(NEWBOARD);

			unlink "$boardsdir/$boardname.tmp";

			if (time() > $time_to_jump && ($j + 1) < $totalrebuilds) {
				&RebuildMessageIndexText($INFO{'rebuild'},-1,$totalrebuilds);
			}
		}
	}

	&RebuildMessageIndexText(3,0,0) if $INFO{'rebuild'} < 3;

	foreach (keys %board) { &BoardCountTotals($_); }

	# remove from movedthreads.cgi only if it's the final thread
	# then look backwards to delete the other entries in
	# the Moved-Info-row if their files were deleted
	eval { require "$datadir/movedthreads.cgi" };
	my $save_moved;
	foreach my $th (keys %moved_file) {
		if (exists $moved_file{$th}) { # 'exists' because may be deleted in &moved_loop
			while (exists $moved_file{$th}) { # to get the final/last thread
				$th = $moved_file{$th};
			}
			unless (-e "$datadir/$th.txt") { &moved_loop($th); }
		}
	}
	sub moved_loop {
		my $th = shift;
		foreach (keys %moved_file) {
			if (exists $moved_file{$_} && $moved_file{$_} == $th && !-e "$datadir/$th.txt") {
				delete $moved_file{$_};
				$save_moved = 1;
				&moved_loop($_);
			}
		}
	}
	&save_moved_file if $save_moved;

	&automaintenance('off');
	$yymain .= qq~<b>$admin_txt{'507'}</b>~;
	$yytitle = $admin_txt{'506'};
	$action_area = 'rebuildmesindex';
	&AdminTemplate;
}

sub RebuildMessageIndexText {
	my ($part,$j,$total) = @_;

	$j++;
	$INFO{'st'} = int($INFO{'st'} + time() - $time_to_jump + $max_process_time);

	$yymain .= qq~<b>$admin_txt{'534'} <i>$max_process_time $admin_txt{'533'}</i>.<br />
	$admin_txt{'535'} <i>~ . (time() - $time_to_jump + $max_process_time) . qq~ $admin_txt{'533'}</i>.<br />
	$admin_txt{'536'} <i>~ . int(($INFO{'st'} + 60)/60) . qq~ $admin_txt{'537'}</i>.<br />
	<br />~;
	$yymain .= qq~$INFO{'count_del_threads'} $admin_txt{'538'}.<br />
	<br />~ if $INFO{'count_del_threads'};


	if ($part == 1) {
		$yymain .= qq~$j/$total $admin_txt{'539'}~;
	} elsif ($part == 2) {
		$yymain .= qq~$j/$total $admin_txt{'540'}~;
	} else {
		$yymain .= $admin_txt{'541'};
	}

	$yymain .= qq~</b>
	<p id="memcontinued">$admin_txt{'542'} <a href="$adminurl?action=rebuildmesindex;rebuild=$part;st=$INFO{'st'};next=$j;count_del_threads=$INFO{'count_del_threads'}" onclick="PleaseWait();">$admin_txt{'543'}</a>...<br />$admin_txt{'544'}
	</p>

	<script type="text/javascript">
	 <!--
		function PleaseWait() {
			document.getElementById("memcontinued").innerHTML = '<font color="red"><b>$admin_txt{'545'}</b></font><br />&nbsp;<br />&nbsp;';
		}

		function stoptick() { stop = 1; }

		stop = 0;
		function membtick() {
			if (stop != 1) {
				PleaseWait();
				location.href="$adminurl?action=rebuildmesindex;rebuild=$part;st=$INFO{'st'};next=$j;count_del_threads=$INFO{'count_del_threads'}";
			}
		}

		setTimeout("membtick()",2000);
	 // -->
	</script>~;

			$yytitle = $admin_txt{'506'};
			$action_area = 'rebuildmesindex';
			&AdminTemplate;
}

sub AdminBoardRecount {
	&is_admin_or_gmod();
	&automaintenance('on');

	$action_area = 'boardrecount';
	$yytitle = $admin_txt{'502'};

	# Set up the multi-step action
	$begin_time = time();
	$topicnum = $INFO{'topicnum'} || 0;

	if (!$INFO{'tnext'}) {
		# Get the thread list
		opendir(TXT, $datadir);
		@topiclist = sort( grep { /^\d+\.txt$/ } readdir(TXT) );
		closedir(TXT);

		for ($i = $topicnum; $i < @topiclist; $i++) {
			($filename, undef) = split(/\./, $topiclist[$i]);

			fopen(MSG, "$datadir/$filename.txt");
			@messages = <MSG>;
			fclose(MSG);

			@lastmessage = split(/\|/, $messages[$#messages]);
			&MessageTotals("load", $filename);
			${$filename}{'replies'} = $#messages;
			if ($lastmessage[0] =~ /^\[m.*?\]/) { ${$filename}{'lastposter'} = $lastmessage[11]; }
			else { ${$filename}{'lastposter'} = $lastmessage[4] eq 'Guest' ? qq~Guest-$lastmessage[1]~ : $lastmessage[4]; }
			&MessageTotals("update", $filename);

			$topicnum++;
			last if time() > ($begin_time + $max_process_time);
		}

		# Prepare to continue...
		$numleft = @topiclist - $topicnum;
		if ($numleft == 0) { # go to finish
			$yySetLocation = qq~$adminurl?action=boardrecount;tnext=1~;
			&redirectexit;
		}

		# Continue
		$sumtopic = @topiclist;
		$resttopic = $sumtopic - $topicnum;

		$yymain .= qq~
		<br />
		$rebuild_txt{'1'}
		<br />
		$rebuild_txt{'5'} $max_process_time $rebuild_txt{'6'}
		<br /><br />
		$rebuild_txt{'13'} $sumtopic
		<br />
		$rebuild_txt{'14'} $resttopic
		<br />
		<br />
		<br />
		<div id="boardrecountcontinued">
		<br />
		$rebuild_txt{'1'}<br />
		$rebuild_txt{'2'} <a href="$adminurl?action=boardrecount;topicnum=$topicnum" onclick="rebRecount();">$rebuild_txt{'3'}</a>
		</div>
		<script type="text/javascript" language="JavaScript">
		<!--
		function rebRecount() {
			document.getElementById("boardrecountcontinued").innerHTML = '$rebuild_txt{'4'}';
		}

		function recounttick() {
			rebRecount();
			location.href="$adminurl?action=boardrecount;topicnum=$topicnum";
		}

		setTimeout("recounttick()",2000)
		// -->
		</script>
		~;
		&AdminTemplate();
	}

	# Get the board list from the forum.master file
	require "$boardsdir/forum.master";
	foreach (keys %board) { &BoardCountTotals($_); }

	$yymain .= qq~<b>$admin_txt{'503'}</b>~;
	&automaintenance('off');
	&AdminTemplate;
}

sub AdminMembershipRecount {
	&is_admin_or_gmod;

	&automaintenance('on');
	&MembershipCountTotal;
	&automaintenance('off');

	$yymain     .= qq~<b>$admin_txt{'505'}</b>~;
	$yytitle     = $admin_txt{'504'};
	$action_area = "membershiprecount";
	&AdminTemplate;
}

sub RebuildMemList {
	my (@contents, $begin_time, $start_time, $timeleft, $hour, $min, $sec, $sumuser, $savesettings, @grpexist);

	# Security
	&is_admin_or_gmod;
	&automaintenance("on");

	# Set up the multi-step action
	$begin_time = time();

	if (-e "$memberdir/memberrest.txt.rebuild" && -M "$memberdir/memberrest.txt.rebuild" < 1) {
		fopen(MEMBERREST, "$memberdir/memberrest.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/memberrest.txt.rebuild", 1);
		@contents = <MEMBERREST>;
		fclose(MEMBERREST);

		fopen(MEMBERCALC, "$memberdir/membercalc.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/membercalc.txt.rebuild", 1);
		$start_time = <MEMBERCALC>;
		$sumuser = <MEMBERCALC>;
		fclose(MEMBERCALC);
		chomp ($start_time, $sumuser);

	} else {
		unlink("$memberdir/memberlist.txt.rebuild");
		unlink("$memberdir/memberinfo.txt.rebuild");
	}

	if (!@contents) {
		# Get the list
		opendir(MEMBERS, $memberdir) || die "$txt{'230'} ($memberdir) :: $!";
		@contents = map { $_ =~ s/\.vars$//; "$_\n"; } grep { /.\.vars$/ } readdir(MEMBERS);
		closedir(MEMBERS);

		$start_time = $begin_time;
		$sumuser = @contents;
		fopen(MEMBERCALC, ">$memberdir/membercalc.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/membercalc.txt.rebuild", 1);
		print MEMBERCALC "$start_time\n$sumuser\n";
		fclose(MEMBERCALC);
	}

	# Loop through each -rest- member
	while (@contents) {
		my $member = pop @contents;
		chomp $member;

		&LoadUser($member);

		$savesettings = 0;
		@grpexist = ();
		foreach (split(/, ?/, ${$uid.$member}{'addgroups'})) {
			if (!exists $NoPost{$_}) { $savesettings = 1; }
			else { push(@grpexist, $_); }
		}
		if ($savesettings) {
			${$uid.$member}{'addgroups'} = join(',', @grpexist);
		}
		if (!exists $Group{ ${$uid.$member}{'position'} } && !exists $NoPost{ ${$uid.$member}{'position'} }) {
			${$uid.$member}{'position'} = "";
		}
		if (!${$uid.$member}{'position'}) {
			${$uid.$member}{'position'} = &MemberPostGroup(${$uid.$member}{'postcount'});
			$savesettings = 1;
		}
		&UserAccount($member, "update") if $savesettings == 1;

		$memberlist{$member} = sprintf("%010d", (&stringtotime(${$uid.$member}{'regdate'}) || &stringtotime($forumstart)));
		$memberinf{$member}  = qq~${$uid.$member}{'realname'}|${$uid.$member}{'email'}|${$uid.$member}{'position'}|${$uid.$member}{'postcount'}|${$uid.$member}{'addgroups'}~;

		undef %{$uid.$member} if $member ne $username;
		last if time() > ($begin_time + $max_process_time);
	}

	# Save what we have rebuilt so far
	fopen(MEMBERLIST, ">>$memberdir/memberlist.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/memberlist.txt.rebuild", 1);
	foreach (keys %memberlist) { print MEMBERLIST "$_\t$memberlist{$_}\n" };
	fclose(MEMBERLIST);

	fopen(MEMBERINFO, ">>$memberdir/memberinfo.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/memberinfo.txt.rebuild", 1);
	foreach (keys %memberinf) { print MEMBERINFO "$_\t$memberinf{$_}\n" };
	fclose(MEMBERINFO);

	# If it is completely done ...
	if(!@contents) {
		%memberlist = ();
		# Sort memberlist.txt
		fopen(MEMBERLIST, "$memberdir/memberlist.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/memberlist.txt.rebuild", 1);
		my %memberlist = map {split(/\t/, $_)} <MEMBERLIST>;
		fclose(MEMBERLIST);

		fopen(MEMBERLIST, ">$memberdir/memberlist.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/memberlist.txt.rebuild", 1);
		foreach (sort {$memberlist{$a} <=> $memberlist{$b}} keys %memberlist) {
			print MEMBERLIST "$_\t$memberlist{$_}";
		}
		fclose(MEMBERLIST);

		# Move the updated copy back
		rename("$memberdir/memberlist.txt.rebuild", "$memberdir/memberlist.txt");
		rename("$memberdir/memberinfo.txt.rebuild", "$memberdir/memberinfo.txt");
		unlink("$memberdir/memberrest.txt.rebuild");
		unlink("$memberdir/membercalc.txt.rebuild");

		$regcounter = &MembershipCountTotal();

		&automaintenance("off");

		if ($INFO{'actiononfinish'}) {
			$yySetLocation = qq~$adminurl?action=$INFO{'actiononfinish'}~;
			&redirectexit;
		}
		$yymain     .= qq~<b>$admin_txt{'594'} $regcounter $admin_txt{'594a'}</b>~;
		$yytitle     = "$admin_txt{'593'}";
		$action_area = "rebuildmemlist";

	# ... or continue looping
	} else {
		fopen(MEMBERREST, ">$memberdir/memberrest.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/memberrest.txt.rebuild", 1);
		print MEMBERREST @contents;
		fclose(MEMBERREST);

		$restuser = @contents;
		$run_time = int(time() - $start_time);
		$run_time ||= 1;
		$time_left = int($restuser / (($sumuser - $restuser + 1) / $run_time));

		$hour= int($run_time/3600);
		$min = int(($run_time-$hour*3600)/60);
		$sec = $run_time - $hour*3600 - $min*60;
		$hour = "0$hour" if $hour<10; $min = "0$min" if $min<10; $sec = "0$sec" if $sec<10;

		$run_time = "$hour:$min:$sec";

		$hour= int($time_left/3600);
		$min = int(($time_left-$hour*3600)/60);
		$sec = $time_left - $hour*3600 - $min*60;
		$hour = "0$hour" if $hour<10; $min = "0$min" if $min<10; $sec = "0$sec" if $sec<10;

		$time_left = "$hour:$min:$sec";

		if ($INFO{'actiononfinish'} eq 'modmemgr') {
			$yymain     .= $rebuild_txt{'20'} ;
			$yytitle     = $admin_txt{'8'};
			$action_area = "modmemgr";
		} else {
			$yytitle     = $admin_txt{'593'};
			$action_area = "rebuildmemlist";
		}

		$yymain .= qq~
<br />
$rebuild_txt{'1'}
<br />
$rebuild_txt{'5'} = $max_process_time $rebuild_txt{'6'}
<br /><br />
$rebuild_txt{'10'} $sumuser
<br />
$rebuild_txt{'10a'} $restuser
<br />
<br />
$rebuild_txt{'7'} $run_time
<br />
$rebuild_txt{'8'} $time_left
<br />
<br />
<div id="memcontinued">
$rebuild_txt{'2'} <a href="$adminurl?action=rebuildmemlist;actiononfinish=$INFO{'actiononfinish'}" onclick="clearMeminfo();">$rebuild_txt{'3'}</a>
</div>
<script type="text/javascript" language="JavaScript">
 <!--
	function clearMeminfo() {
		document.getElementById("memcontinued").innerHTML = '$rebuild_txt{'4'}';
	}

	function membtick() {
		clearMeminfo();
		location.href="$adminurl?action=rebuildmemlist;actiononfinish=$INFO{'actiononfinish'}";
	}

	setTimeout("membtick()", 2000)
 // -->
</script>~;
	}

	&AdminTemplate();
}

sub RebuildMemHistory {
	my (@contents,$begin_time,$start_time,$timeleft,$hour,$min,$sec,$sumtopic,$resttopic,$mdate,$user);

	# Security
	&is_admin_or_gmod;
	&automaintenance("on");

	# Set up the multi-step action
	$begin_time = time();

	if (-e "$datadir/topicrest.txt.rebuild"  && -M "$datadir/topicrest.txt.rebuild" < 1) {
		fopen(TOPICREST, "$datadir/topicrest.txt.rebuild") || &fatal_error('cannot_open', "$datadir/topicrest.txt.rebuild", 1);
		@contents = <TOPICREST>;
		fclose(TOPICREST);

		fopen(TOPICCALC, "$datadir/topiccalc.txt.rebuild") || &fatal_error('cannot_open', "$datadir/topiccalc.txt.rebuild", 1);
		$start_time = <TOPICCALC>;
		$sumtopic = <TOPICCALC>;
		fclose(TOPICCALC);
		chomp ($begin_time,$sumtopic);
	}

	if (!@contents) {
		# Delete all rlog
		opendir(MEMBERS, $memberdir) || die "$txt{'230'} ($memberdir) :: $!";
		@contents = grep { /\.rlog$/ } readdir(MEMBERS);
		closedir(MEMBERS);
		foreach (@contents) {
			unlink "$memberdir/$_";
		}

		# Get and store the thread list
		opendir(TXT, $datadir);
		@contents = map { $_ =~ s/\.txt$//; "$_\n"; } grep { /^\d+\.txt$/ } readdir(TXT);
		closedir(TXT);

		$start_time = $begin_time;
		$sumtopic = @contents;
		fopen(TOPICCALC, ">$datadir/topiccalc.txt.rebuild") || &fatal_error('cannot_open', "$datadir/topiccalc.txt.rebuild", 1);
		print TOPICCALC "$start_time\n$sumtopic\n";
		fclose(TOPICCALC);
	}

	# Loop through each -rest- topic
	while (@contents) {
		$topic = pop @contents;
		chomp $topic;

		fopen(TOPIC, "$datadir/$topic.txt");
		my @topic = <TOPIC>;
		fclose(TOPIC);

		my %dates = ();
		my %posts = ();
		foreach (@topic) {
			(undef, undef, undef, $mdate, $user, undef) = split(/\|/, $_, 6);
			if($user ne 'Guest') {
				$posts{$user}++;
				$dates{$user} = $mdate;
			}
		}

		foreach $user (keys %posts) {
			if (-e "$memberdir/$user.vars") {
				fopen(HIST, ">>$memberdir/$user.rlog");
				print HIST "$topic\t$posts{$user},$dates{$user}\n";
				fclose(HIST);
			}
		}

		last if time() > ($begin_time + $max_process_time);
	}

	# See if we're completely done
	if(!@contents) {
		&automaintenance("off");

		unlink("$datadir/topicrest.txt.rebuild");
		unlink("$datadir/topiccalc.txt.rebuild");

		$yymain .= qq~<b>$admin_txt{'598'}</b>~;

	# Or prepare to continue looping
	} else {
		fopen(TOPICREST, ">$datadir/topicrest.txt.rebuild") || &fatal_error('cannot_open', "$datadir/topicrest.txt.rebuild", 1);
		print TOPICREST @contents;
		fclose(TOPICREST);

		$resttopic = @contents;

		$run_time = int(time() - $start_time);
		$run_time = 1 if !$run_time;
		$time_left = int($resttopic / (($sumtopic - $resttopic) / $run_time));

		$hour= int($run_time/3600);
		$min = int(($run_time - $hour * 3600) / 60);
		$sec = $run_time - $hour * 3600 - $min * 60;
		$hour = "0$hour" if $hour < 10; $min = "0$min" if $min < 10; $sec = "0$sec" if $sec < 10;

		$run_time = "$hour:$min:$sec";

		$hour= int($time_left / 3600);
		$min = int(($time_left - $hour * 3600) / 60);
		$sec = $time_left - $hour * 3600 - $min * 60;
		$hour = "0$hour" if $hour < 10; $min = "0$min" if $min < 10; $sec = "0$sec" if $sec < 10;

		$time_left = "$hour:$min:$sec";

		$yymain .= qq~
<br />
$rebuild_txt{'1'}
<br />
$rebuild_txt{'5'} $max_process_time $rebuild_txt{'6'}
<br /><br />
$rebuild_txt{'13'} $sumtopic
<br />
$rebuild_txt{'14'} $resttopic
<br />
<br />
$rebuild_txt{'7'} $run_time
<br />
$rebuild_txt{'8'} $time_left
<br />
<br />
<div id="memcontinued">
$rebuild_txt{'2'} <a href="$adminurl?action=rebuildmemhist" onclick="clearMeminfo();">$rebuild_txt{'3'}</a>
</div>
<script type="text/javascript" language="JavaScript">
 <!--
	function clearMeminfo() {
		document.getElementById("memcontinued").innerHTML = '$rebuild_txt{'4'}';
	}

	function membtick() {
		clearMeminfo();
		location.href="$adminurl?action=rebuildmemhist";
	}

	setTimeout("membtick()", 2000)
 // -->
</script>~;
	}

	$yytitle = $admin_txt{'597'};
	$action_area = "rebuildmemhist";
	&AdminTemplate();
}

sub RebuildNotifications {
	&is_admin_or_gmod();
	&automaintenance('on');

	# Set up the multi-step action
	my $begin_time = time();

	my (%members, $sumuser, $sumbo, $sumthr, $sumtotal, $start_time, $exitloop);
	require "$sourcedir/Notify.pl";

	if (-e "$memberdir/NotificationsRebuild.txt.rebuild" && -M "$memberdir/NotificationsRebuild.txt.rebuild" < 1) {
		fopen(MEMBNOTIF, "$memberdir/NotificationsRebuild.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/NotificationsRebuild.txt.rebuild", 1);
		%members = map /(.*)\t(.*)/, <MEMBNOTIF>;
		fclose(MEMBNOTIF);

		fopen(CALCNOTIF, "$vardir/NotificationsCalc.txt.rebuild") || &fatal_error('cannot_open', "$vardir/NotificationsCalc.txt.rebuild", 1);
		$start_time = <CALCNOTIF>;
		$sumuser = <CALCNOTIF>;
		$sumbo = <CALCNOTIF>;
		$sumthr = <CALCNOTIF>;
		fclose(CALCNOTIF);
		chomp($start_time,$sumuser,$sumbo,$sumthr);
		$sumtotal = $sumuser + $sumbo + $sumthr;

		fopen(BOARDNOTIF, "$boardsdir/NotificationsBmaildir.txt.rebuild") || &fatal_error('cannot_open', "$boardsdir/NotificationsBmaildir.txt.rebuild", 1);
		@bmaildir = <BOARDNOTIF>;
		fclose(BOARDNOTIF);
		chomp(@bmaildir);
		fopen(THREADNOTIF, "$datadir/NotificationsTmaildir.txt.rebuild") || &fatal_error('cannot_open', "$datadir/NotificationsTmaildir.txt.rebuild", 1);
		@tmaildir = <THREADNOTIF>;
		fclose(THREADNOTIF);
		chomp(@tmaildir);

	} else {
		unlink("$memberdir/NotificationsRebuild.txt.rebuild");
		unlink("$vardir/NotificationsCalc.txt.rebuild");
		unlink("$boardsdir/NotificationsBmaildir.txt.rebuild");
		unlink("$datadir/NotificationsTmaildir.txt.rebuild");
	}

	if (!%members) {
		opendir(MEMBNOTIF, $memberdir) || &fatal_error('cannot_open', "$memberdir", 1);
		map { $_ =~ /(.+)\.(vars|wait|pre)$/; $members{$1} = $2; } grep { /.\.(vars|wait|pre)$/ } readdir(MEMBNOTIF);
		closedir(MEMBNOTIF);

		# get list of board (@bmaildir) and post (@tmaildir) .mail files
		&getMailFiles;

		$start_time = $begin_time;
		$sumuser = keys %members;
		$sumbo = @bmaildir;
		$sumthr = @tmaildir;
		$sumtotal = $sumuser + $sumbo + $sumthr;
		fopen(CALCNOTIF, ">$vardir/NotificationsCalc.txt.rebuild") || &fatal_error('cannot_open', "$vardir/NotificationsCalc.txt.rebuild", 1);
		print CALCNOTIF "$start_time\n$sumuser\n$sumbo\n$sumthr\n";
		fclose(CALCNOTIF);
	}

	# Loop through each -rest- board-mail
	while (@bmaildir) {
		# board name
		$myboard = pop @bmaildir;

		# load in hash of name / detail
		&ManageBoardNotify("load", $myboard);

		my @temp = keys %theboard;
		undef %theboard;
		foreach my $user (@temp) {
			unless (exists $members{$user}) {
				&ManageBoardNotify("delete",$myboard,$user);
			}

			# update Board-Notifications
			&LoadUser($user,$members{$user});
			my %b;
			foreach (split(/,/, ${$uid.$user}{'board_notifications'})) {
				$b{$_} = 1;
			}
			$b{$myboard} = 1;
			${$uid.$user}{'board_notifications'} = join(',', keys %b);
			&UserAccount($user);

			undef %{$uid.$user} if $user ne $username;
		}

		if (time() > ($begin_time + $max_process_time)) { $exitloop = 1; last; }
	}

	if (!$exitloop) {
		# Loop through each -rest- thread-mail
		while (@tmaildir) {
			# number of the thread
			$mythread = pop @tmaildir;

			# load in hash of name / detail
			&ManageThreadNotify("load",$mythread);

			my @temp = keys %thethread;
			undef %thethread;
			foreach my $user (@temp) {
				unless (exists $members{$user}) {
					&ManageThreadNotify("delete",$mythread,$user);
					next;
				}

				# update Thread-Notifications
				&LoadUser($user,$members{$user});
				my %t;
				foreach (split(/,/, ${$uid.$user}{'thread_notifications'})) {
					$t{$_} = 1;
				}
				$t{$mythread} = 1;
				${$uid.$user}{'thread_notifications'} = join(',', keys %t);
				&UserAccount($user);

				undef %{$uid.$user} if $user ne $username;
			}

			if (time() > ($begin_time + $max_process_time)) { $exitloop = 1; last; }
		}
	}

	if (!$exitloop) {
		my @temp = keys %members;
		while (@temp) {
			$user = pop @temp; 

			&LoadUser($user,$members{$user});
			# update notification method. Not used by YaBB versions >= 2.2.3
			if (exists ${$uid.$user}{'im_notify'}) { ${$uid.$user}{'notify_me'} = ${$uid.$user}{'im_notify'} ? 3 : 0; }

			# Control Notifications
			my (%b,%t);
			foreach (split(/,/, ${$uid.$user}{'board_notifications'})) {
				&ManageBoardNotify("load", $_);
				$b{$_} = 1 if $theboard{$user};
			}
			${$uid.$user}{'board_notifications'} = join(',', keys %b);
			foreach (split(/,/, ${$uid.$user}{'thread_notifications'})) {
				&ManageThreadNotify("load", $_);
				$t{$_} = 1 if $thethread{$user};
			}
			${$uid.$user}{'thread_notifications'} = join(',', keys %t);
			&UserAccount($user);

			undef %{$uid.$user} if $user ne $username;
			delete $members{$user};

			if (time() > ($begin_time + $max_process_time)) { $exitloop = 1; last; }
		}
	}

	# If it is completely done ...
	if(!$exitloop) {
		unlink("$memberdir/NotificationsRebuild.txt.rebuild");
		unlink("$vardir/NotificationsCalc.txt.rebuild");
		unlink("$boardsdir/NotificationsBmaildir.txt.rebuild");
		unlink("$datadir/NotificationsTmaildir.txt.rebuild");

		&automaintenance('off');

		$yymain .= qq~<b>$rebuild_txt{'150b'}</b>~;

	# ... or continue looping
	} else {
		fopen(MEMBNOTIF, ">$memberdir/NotificationsRebuild.txt.rebuild") || &fatal_error('cannot_open', "$memberdir/NotificationsRebuild.txt.rebuild", 1);
		print MEMBNOTIF map { "$_\t$members{$_}\n" } keys %members;
		fclose(MEMBNOTIF);

		fopen(BOARDNOTIF, ">$boardsdir/NotificationsBmaildir.txt.rebuild") || &fatal_error('cannot_open', "$boardsdir/NotificationsBmaildir.txt.rebuild", 1);
		print BOARDNOTIF map { "$_\n" } @bmaildir;
		fclose(BOARDNOTIF);
		fopen(THREADNOTIF, ">$datadir/NotificationsTmaildir.txt.rebuild") || &fatal_error('cannot_open', "$datadir/NotificationsTmaildir.txt.rebuild", 1);
		print THREADNOTIF map { "$_\n" } @tmaildir;
		fclose(THREADNOTIF);

		$restuser  = keys %members;
		$restbo    = @bmaildir;
		$restthr   = @tmaildir;
		$resttotal = $restuser + $restbo + $restthr;

		$run_time  = int(time() - $start_time);
		$time_left = int($resttotal / (($sumtotal - $resttotal) / $run_time));

		$hour = int($run_time / 3600);
		$min  = int(($run_time - ($hour * 3600)) / 60);
		$sec  = $run_time - ($hour * 3600) - ($min * 60);
		$hour = "0$hour" if $hour < 10; $min = "0$min" if $min < 10; $sec = "0$sec" if $sec < 10;
		$run_time = "$hour:$min:$sec";

		$hour = int($time_left / 3600);
		$min  = int(($time_left - ($hour * 3600)) / 60);
		$sec  = $time_left - ($hour * 3600) - ($min * 60);
		$hour = "0$hour" if $hour < 10; $min = "0$min" if $min < 10; $sec = "0$sec" if $sec < 10;
		$time_left = "$hour:$min:$sec";

		$yymain .= qq~
<br />
$rebuild_txt{'1'}<br />
$rebuild_txt{'5'} = $max_process_time $rebuild_txt{'6'}<br />
<br />
$rebuild_txt{'15'} $sumbo<br />
$rebuild_txt{'15a'} $restbo<br />
<br />
$rebuild_txt{'16'} $sumthr<br />
$rebuild_txt{'16a'} $restthr<br />
<br />
$rebuild_txt{'10'} $sumuser<br />
$rebuild_txt{'10a'} $restuser<br />
<br />
<br />
$rebuild_txt{'7'} $run_time<br />
$rebuild_txt{'8'} $time_left<br />
<br />
<div id="memcontinued">
$rebuild_txt{'2'} <a href="$adminurl?action=rebuildnotifications" onclick="clearMeminfo();">$rebuild_txt{'3'}</a>
</div>
<script type="text/javascript" language="JavaScript">
 <!--
	function clearMeminfo() {
		document.getElementById("memcontinued").innerHTML = '$rebuild_txt{'4'}';
	}

	function membtick() {
		clearMeminfo();
		location.href="$adminurl?action=rebuildnotifications";
	}

	setTimeout("membtick()", 2000)
 // -->
</script>
<br />
<br />
~;
	}

	$yytitle = $rebuild_txt{'150a'};
	$action_area = "rebuildnotifications";

	&AdminTemplate;
}

sub clean_log {
	&is_admin_or_gmod;

	# Overwrite with a blank file
	&RemoveUserOnline();

	$yymain .= qq~<b>$admin_txt{'596'}</b>~;
	$yytitle     = "$admin_txt{'595'}";
	$action_area = "clean_log";
	&AdminTemplate;
}

1;