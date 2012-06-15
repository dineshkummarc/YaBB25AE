###############################################################################
# Poll.pl                                                                     #
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

$pollplver = 'YaBB 2.5 AE $Revision: 1.18 $';
if ($action eq 'detailedversion') { return 1; }

&LoadLanguage('Poll');

sub DoVote {
	$pollnum = $INFO{'num'};
	$start   = $INFO{'start'};
	unless (-e "$datadir/$pollnum.poll") { &fatal_error('poll_not_found',$pollnum); }

	$novote = 0;
	$vote   = "";
	fopen(FILE, "$datadir/$pollnum.poll");
	$poll_question = <FILE>;
	@poll_data     = <FILE>;
	fclose(FILE);
	chomp $poll_question;
	(undef, $poll_locked, undef, undef, undef, undef, $guest_vote, undef, $multi_vote, undef, undef, undef, $vote_limit,undef) = split(/\|/, $poll_question, 14);
	for (my $i = 0; $i < @poll_data; $i++) {
		chomp $poll_data[$i];
		($votes[$i], $options[$i], $slicecols[$i], $split[$i]) = split(/\|/, $poll_data[$i]);
		$tmp_vote = qq~$FORM{"option$i"}~;
		if ($multi_vote && $tmp_vote ne "") {
			$votes[$i]++;
			$novote = 1;
			if ($vote ne '') { $vote .= ","; }
			$vote .= $tmp_vote;
		}
	}
	$tmp_vote = $FORM{'option'};
	if (!$multi_vote && $tmp_vote ne '') { $vote = $tmp_vote; $votes[$tmp_vote]++; $novote = 1; }

	if ($novote == 0 || $vote eq '') { &fatal_error('no_vote_option'); }
	if ($iamguest && !$guest_vote) { &fatal_error('members_only'); }
	if ($poll_locked) { &fatal_error('locked_poll_no_count'); }

	fopen(FILE, "$datadir/$pollnum.polled");
	@polled = <FILE>;
	fclose(FILE);

	for (my $i = 0; $i < @polled; $i++) {
		($voters_ip, $voters_name, $voters_vote, $vote_time) = split(/\|/, $polled[$i]);
		chomp $voters_vote;
		if ($iamguest && $voters_name eq 'Guest' && lc $voters_ip eq lc $user_ip) { &fatal_error('ip_guest_used'); }
		elsif ($iamguest  && $voters_name ne 'Guest' && lc $voters_ip eq lc $user_ip) { &fatal_error('ip_member_used'); }
		elsif (!$iamguest && $voters_name ne 'Guest' && lc $username  eq lc $voters_name) { &fatal_error('voted_already'); }
		elsif (!$iamguest && $voters_name eq 'Guest' && lc $voters_ip eq lc $user_ip) {
			foreach $oldvote (split(/\,/, $voters_vote)) {
				$votes[$oldvote]--;
			}
			$polled[$i] = '';
			last;
		}
	}

	fopen(FILE, ">$datadir/$pollnum.poll");
	print FILE "$poll_question\n";
	for (my $i = 0; $i < @poll_data; $i++) { print FILE "$votes[$i]|$options[$i]|$slicecols[$i]|$split[$i]\n"; }
	fclose(FILE);

	fopen(FILE, ">$datadir/$pollnum.polled");
	print FILE "$user_ip|$username|$vote|$date\n";
	print FILE @polled;
	fclose(FILE);
			
	if ($start) { $start = "/$start"; }
	if ($INFO{'scp'}) {
		$yySetLocation = qq~$scripturl~;
	} else {
		$yySetLocation = qq~$scripturl?num=$pollnum$start~;
	}
	&redirectexit;
}

sub UndoVote {
	$pollnum = $INFO{'num'};
	unless (-e "$datadir/$pollnum.poll") { &fatal_error('poll_not_found',$pollnum); }

	&check_deletepoll;
	if (!$iamadmin && $poll_nodelete{$username}) { &fatal_error('no_access'); }

	fopen(FILE, "$datadir/$pollnum.poll");
	$poll_question = <FILE>;
	@poll_data     = <FILE>;
	fclose(FILE);
	$poll_locked = (split /\|/, $poll_question, 2)[1];
	my @options;
	my @votes;

	for (my $i = 0; $i < @poll_data; $i++) {
		chomp $poll_data[$i];
		($votes[$i], $options[$i], $slicecols[$i], $split[$i]) = split(/\|/, $poll_data[$i]);
	}

	fopen(FILE, "$datadir/$pollnum.polled");
	@polled = <FILE>;
	fclose(FILE);

	if ($FORM{'multidel'} eq "1") {
		&is_admin;
		for (my $i = 0; $i < @polled; $i++) {
			($voters_ip, $voters_name, $voters_vote, $vote_date) = split(/\|/, $polled[$i]);
			chomp $voters_vote;
			$id = $FORM{"$voters_ip-$voters_name"};
			if ($id eq "1") {
				foreach $oldvote (split(/\,/, $voters_vote)) {
					$votes[$oldvote]--;
				}
				$polled[$i] = '';
			}
		}
	} else {
		if ($iamguest)  { &fatal_error('not_allowed'); }
		if ($poll_lock) { &fatal_error('locked_poll_no_delete'); }
		$found = 0;
		for (my $i = 0; $i < @polled; $i++) {
			($voters_ip, $voters_name, $voters_vote, $vote_date) = split(/\|/, $polled[$i]);
			chomp $voters_vote;
			if ($voters_name eq $username) {
				$found = 1;
				foreach $oldvote (split(/\,/, $voters_vote)) {
					$votes[$oldvote]--;
				}
				$polled[$i] = '';
				last;
			}
		}
		if (!$found) { &fatal_error('not_completed'); }
	}

	fopen(FILE, ">$datadir/$pollnum.poll");
	print FILE $poll_question;
	for (my $i = 0; $i < @poll_data; $i++) { print FILE "$votes[$i]|$options[$i]|$slicecols[$i]|$split[$i]\n"; }
	fclose(FILE);

	fopen(FILE, ">$datadir/$pollnum.polled");
	print FILE @polled;
	fclose(FILE);
			
	if ($start) { $start = "/$start"; }
	if ($INFO{'scp'}) {
		$yySetLocation = qq~$scripturl~;
	} else {
		$yySetLocation = qq~$scripturl?num=$pollnum$start~;
	}
	&redirectexit;
}

sub LockPoll {
	$pollnum = $INFO{'num'};
	unless (-e "$datadir/$pollnum.poll") { &fatal_error('poll_not_found',$pollnum); }

	fopen(FILE, "$datadir/$pollnum.poll");
	$poll_question = <FILE>;
	@poll_data     = <FILE>;
	fclose(FILE);
	chomp $poll_question;
	($poll_question, $poll_locked, $poll_uname, $poll_stuff) = split(/\|/, $poll_question, 4);
	unless ($username eq $poll_uname || $iamadmin || $iamgmod || $iammod) { &fatal_error('not_allowed'); }

	if ($poll_locked) { $poll_locked = 0; }
	else { $poll_locked = 1; }

	fopen(FILE, ">$datadir/$pollnum.poll");
	print FILE "$poll_question|$poll_locked|$poll_uname|$poll_stuff\n";
	print FILE @poll_data;
	fclose(FILE);

	if ($start) { $start = "/$start"; }
	if ($INFO{'scp'}){
		$yySetLocation = qq~$scripturl~;
	} else {
		$yySetLocation = qq~$scripturl?num=$pollnum$start~;
	}
	&redirectexit;
}

sub votedetails {
	&is_admin;

	$pollnum = $INFO{'num'};
	unless (-e "$datadir/$pollnum.poll") { &fatal_error('poll_not_found',$pollnum); }
	if ($start) { $start = "/$start"; }

	&LoadCensorList;

	# Figure out the name of the category
	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	($curcat, $catperms) = split(/\|/, $catinfo{"$cat"});

	fopen(FILE, "$datadir/$pollnum.poll");
	$poll_question = <FILE>;
	@poll_data     = <FILE>;
	fclose(FILE);
	chomp $poll_question;
	($poll_question, $poll_locked, $poll_uname, $poll_name, $poll_email, $poll_date, $guest_vote, $hide_results, $multi_vote, $poll_mod, $poll_modname, $poll_comment, undef) = split(/\|/, $poll_question, 13);
	unless (ref($thread_arrayref{$pollnum})) {
		fopen(POLLTP, "$datadir/$pollnum.txt");
		@{$thread_arrayref{$pollnum}} = <POLLTP>;
		fclose(POLLTP);
	}
	$psub = (split /\|/, ${$thread_arrayref{$pollnum}}[0], 2)[0];
	&ToChars($psub);

	# Censor the options.
	$poll_question = &Censor($poll_question);
	if ($ubbcpolls) {
		if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
		$message = $poll_question;
		&DoUBBC;
		$poll_question = $message;
	}
	&ToChars($poll_question);

	my @options;
	my @votes;
	my $totalvotes = 0;
	my $maxvote    = 0;
	for (my $i = 0; $i < @poll_data; $i++) {
		chomp $poll_data[$i];
		($votes[$i], $options[$i]) = split(/\|/, $poll_data[$i]);
		$totalvotes += int($votes[$i]);
		if (int($votes[$i]) >= $maxvote) { $maxvote = int($votes[$i]); }
		$options[$i] = &Censor($options[$i]);
		if ($ubbcpolls) {
			$message = $options[$i];
			&DoUBBC;
			$options[$i] = $message;
		}
		&ToChars($options[$i]);
	}

	fopen(FILE, "$datadir/$pollnum.polled");
	@polled = <FILE>;
	fclose(FILE);

	if ($poll_modname ne '' && $poll_mod ne '') {
		$poll_mod = &timeformat($poll_mod);
		&LoadUser($poll_modname);
		$displaydate = qq~<span class="small">&#171; $polltxt{'45a'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_modname}">${$uid.$poll_modname}{'realname'}</a> $polltxt{'46'}: $poll_mod &#187;</span>~;
	}
	if ($poll_uname ne '' && $poll_date ne '') {
		$poll_date = &timeformat($poll_date);
		if ($poll_uname ne 'Guest' && -e "$memberdir/$poll_uname.vars") {
			&LoadUser($poll_uname);
			$displaydate = qq~<span class="small">&#171; $polltxt{'45'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_uname}">${$uid.$poll_uname}{'realname'}</a> $polltxt{'46'}: $poll_date &#187;</span>~;
		} else {
			$displaydate = qq~<span class="small">&#171; $polltxt{'45'}: $poll_name $polltxt{'46'}: $poll_date &#187;</span>~;
		}
	}
	&ToChars($boardname);
	$yytitle = $polltxt{'42'};
	
	$template_home = qq~<a href="$scripturl" class="nav">$mbname</a>~;
	$template_cat = qq~<a href="$scripturl?catselect=$curcat" class="nav">$cat</a>~;
	$template_board = qq~<a href="$scripturl?board=$currentboard" class="nav">$boardname</a>~;
	$curthreadurl = qq~<a href="$scripturl?num=$pollnum" class="nav">$psub</a> &rsaquo; $polltxt{'42'}~;
	
	$yynavigation = qq~&rsaquo; $template_cat &rsaquo; $template_board &rsaquo; $curthreadurl~;
	
	$yymain .= qq~
<br />
<form action="$scripturl?action=undovote;num=$pollnum$start" method="post" style="display: inline;">
<input type="hidden" name="multidel" value="1" />
<table cellpadding="4" cellspacing="1" border="0" width="90%" class="bordercolor" align="center">
        <tr>
          <td class="titlebg" colspan="5">$img{'pollicon'} <span class="text1"><b>$polltxt{'42'}</b></span></td>
        </tr><tr>
          <td class="windowbg2" colspan="5"><br /><b>$polltxt{'16'}:</b> $poll_question<br /><br /></td>
        </tr><tr>
          <td class="catbg" align="center"><b>&nbsp;</b></td>
          <td class="catbg" align="center"><b>$polltxt{'35'}</b></td>
          <td class="catbg" align="center"><b>$polltxt{'30'}</b></td>
          <td class="catbg" align="center"><b>$polltxt{'31'}</b></td>
          <td class="catbg" align="center"><b>$polltxt{'24'}</b></td>
        </tr><tr>~;

	foreach $entry (@polled) {
		chomp $entry;
		$voted = '';
		($voters_ip, $voters_name, $voters_vote, $vote_date) = split(/\|/, $entry);
		$id = qq~$voters_ip-$voters_name~;
		if ($voters_name ne 'Guest' && -e "$memberdir/$voters_name.vars") {
			&LoadUser($voters_name);
			$voters_name = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$voters_name}">${$uid.$voters_name}{'realname'}</a>~;
		}
		foreach $oldvote (split(/\,/, $voters_vote)) {
			if ($ubbcpolls) {
				$message = $options[$oldvote];
				&DoUBBC;
				$options[$oldvote] = $message;
			}
			&ToChars($options[$oldvote]);
			$voted .= qq~$options[$oldvote]<br />~;
		}

		$vote_date = &timeformat($vote_date);
		$yymain .= qq~
          <td class="windowbg2" align="center"><input type="checkbox" name="$id" value="1" /></td>
          <td class="windowbg2">$voters_name</td>
          <td class="windowbg2" align="center">$voters_ip</td>
          <td class="windowbg2" align="center">$vote_date</td>
          <td class="windowbg2">$voted</td>
        </tr><tr>~;
	}

	$yymain .= qq~
          <td class="titlebg" align="center" colspan="5"><input type="submit" value="$polltxt{'49'}" class="button" /></td>
        </tr>
</table>
</form>~;

	$display_template =~ s/({|<)yabb home(}|>)/$template_home/g;
	$display_template =~ s/({|<)yabb category(}|>)/$template_cat/g;
	$display_template =~ s/({|<)yabb board(}|>)/$template_board/g;
	$display_template =~ s/({|<)yabb threadurl(}|>)/$curthreadurl/g;

	&template;
}

sub display_poll {
	$pollnum = @_[0];

	# showcase poll start
	$brdpoll = @_[1];
	$scp = '';
	$viewthread = '';
	$boardpoll = '';
	if ($brdpoll) {
		$scp = qq~;scp=1~;
		$viewthread = qq~<a href="$scripturl?num=$pollnum" class="altlink">$img{'viewthread'}</a>~;
		$boardpoll = qq~&nbsp;/ <a href="$scripturl?action=scpolldel" class="altlink">$polltxt{'showcaserem'}</a>~ if ($iamadmin || $iamgmod);
	} elsif (-e "$datadir/showcase.poll") {
		fopen (FILE, "$datadir/showcase.poll");
		$boardpoll = qq~&nbsp;/ $polltxt{'showcased'}~ if $pollnum == <FILE>;
		fclose (FILE);
		if ($iamadmin || $iamgmod) {
			$boardpoll = $boardpoll ? qq~&nbsp;/ <a href="$scripturl?action=scpolldel" class="altlink">$polltxt{'showcaserem'}</a>~ : qq~&nbsp;/ <a href="javascript:Check=confirm('$polltxt{'confirm'}');if(Check==true){window.location.href='$scripturl?action=scpoll;num=$pollnum';}else{void Check;}" class="altlink">$polltxt{'setshowcased'}</a>~;
		}
	} else {
		$boardpoll = qq~&nbsp;/ <a href="$scripturl?action=scpoll;num=$pollnum" class="altlink">$polltxt{'setshowcased'}</a>~ if ($iamadmin || $iamgmod);
	}
	# showcase poll end

	&LoadCensorList;

	fopen(FILE, "$datadir/$pollnum.poll");
	$poll_question = <FILE>;
	@poll_data = <FILE>;
	fclose(FILE);
	chomp $poll_question;
	($poll_question, $poll_locked, $poll_uname, $poll_name, $poll_email, $poll_date, $guest_vote, $hide_results, $multi_vote, $poll_mod, $poll_modname, $poll_comment, $vote_limit, $pie_radius, $pie_legends, $poll_end) = split(/\|/, $poll_question);

	if ($poll_end && !$poll_locked && $poll_end < $date) {
		$poll_locked = 1;
		$poll_end = '';
		fopen(FILE, ">$datadir/$pollnum.poll");
		print FILE "$poll_question|$poll_locked|$poll_uname|$poll_name|$poll_email|$poll_date|$guest_vote|$hide_results|$multi_vote|$poll_mod|$poll_modname|$poll_comment|$vote_limit|$pie_radius|$pie_legends|$poll_end\n";
		print FILE @poll_data;
		fclose(FILE);
	}

	$pie_radius ||= 100;
	$pie_legends ||= 0;

	$users_votetext = '';
	$has_voted = 0;
	if (!$guest_vote && $iamguest) { $has_voted = 4; }
	else {
		fopen(FILE, "$datadir/$pollnum.polled");
		@polled = <FILE>;
		fclose(FILE);
		foreach $tmpLine (@polled) {
			chomp $tmpline;
			($voters_ip, $voters_name, $voters_vote, $vote_date) = split(/\|/, $tmpLine);
			if ($iamguest && $voters_name eq 'Guest' && lc $voters_ip eq lc $user_ip) { $has_voted = 1; last; }
			elsif ($iamguest && $voters_name ne 'Guest' && lc $voters_ip eq lc $user_ip) { $has_voted = 2; last; }
			elsif (!$iamguest && lc $username eq lc $voters_name) {
				$has_voted = 3;
				$users_votedate = &timeformat($vote_date);
				@users_vote = split(/\,/, $voters_vote);
				my $users_votecount = @users_vote;
				if ($users_votecount == 1) {
					$users_votetext = qq~<br /><span style="font-weight: bold;">$polltxt{'64'}:</span> $users_votedate<br /><span style="font-weight: bold;">$polltxt{'65'}:</span> ~;
				} else {
					$users_votetext = qq~<br /><span style="font-weight: bold;">$polltxt{'64'}:</span> $users_votedate<br /><span style="font-weight: bold;">$polltxt{'66'}:</span> ~;
				}
				last;
			}
		}
	}

	my @options;
	my @votes;
	my $totalvotes = 0;
	my $maxvote    = 0;
	$piearray = qq~[~;
	for (my $i = 0; $i < @poll_data; $i++) {
		chomp $poll_data[$i];
		($votes[$i], $options[$i], $slicecolor[$i], $split[$i]) = split(/\|/, $poll_data[$i]);
		# Censor the options.
		$options[$i] = &Censor($options[$i]);
		$options[$i] =~ s~[\n\r]~~g;
		if ($ubbcpolls) {
			if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
			$message = $options[$i];
			&DoUBBC;
			$options[$i] = $message;
		}
		&ToChars($options[$i]);
		$piearray .= qq~"$votes[$i]|$options[$i]|$slicecolor[$i]|$split[$i]", ~;
		$totalvotes += int($votes[$i]);
		if (int($votes[$i]) >= $maxvote) { $maxvote = int($votes[$i]); }
	}
	$piearray =~ s/\, $//i;
	$piearray .= qq~]~;

	my ($endedtext, $displayvoters);
	if (!$iamguest && ($username eq $poll_uname || $iamadmin || $iamgmod || $iammod)) {
		if ($poll_locked) {
			$lockpoll = qq~<a href="$scripturl?action=lockpoll;num=$pollnum$scp" class="altlink">$img{'openpoll'}</a>~;
		} else {
			$lockpoll = qq~<a href="$scripturl?action=lockpoll;num=$pollnum$scp" class="altlink">$img{'closepoll'}</a>~;
		}
		$modifypoll = qq~$menusep<a href="$scripturl?board=$currentboard;action=modify;message=Poll;thread=$pollnum" class="altlink">$img{'modifypoll'}</a>~;
		$deletepoll = qq~$menusep<a href="javascript:document.removepoll.submit();" class="altlink" onclick="return confirm('$polltxt{'44'}')">$img{'deletepoll'}</a>~;
		if ($iamadmin) {
			$displayvoters = $menusep if $viewthread;
			$displayvoters .= qq~<a href="$scripturl?action=showvoters;num=$pollnum">$img{'viewvotes'}</a>~;
		}
		if ($hide_results) {
			$endedtext = qq~<span style="color: #FF0000;"><b>$polltxt{'53'}</b></span></td>
                </tr>
                <tr>
                  <td colspan="2" align="center" class="windowbg2"><br />~;
			$hide_results = 0;
			$bgclass = 'windowbg2';
		}
	}

	if ($poll_modname ne '' && $poll_mod ne '' && $showmodify) {
		$poll_mod = &timeformat($poll_mod);
		&LoadUser($poll_modname);
		$displaydate = qq~<span class="small">&#171; $polltxt{'45a'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_modname}">${$uid.$poll_modname}{'realname'}</a> $polltxt{'46'}: $poll_mod &#187;</span>~;
	} elsif ($poll_uname ne '' && $poll_date ne '') {
		$poll_date = &timeformat($poll_date);
		if ($poll_uname ne 'Guest' && -e "$memberdir/$poll_uname.vars") {
			&LoadUser($poll_uname);
			$displaydate = qq~<span class="small">&#171; $polltxt{'45'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_uname}">${$uid.$poll_uname}{'realname'}</a> $polltxt{'46'}: $poll_date &#187;</span>~;
		} elsif ($poll_name ne '') {
			$displaydate = qq~<span class="small">&#171; $polltxt{'45'}: $poll_name $polltxt{'46'}: $poll_date &#187;</span>~;
		} else {
			$displaydate = '';
		}
	} else {
		$displaydate = '';
	}

	if ($poll_locked) {
		$bgclass = 'windowbg2';
		$endedtext = qq~<span style="color: #FF0000;"><b>$polltxt{'22'}</b></span></td>
                </tr>
                <tr>
                  <td colspan="2" align="center" class="windowbg2"><br />~;
		$poll_icon = $img{'polliconclosed'};
		$has_voted = 5;
	} else {
		$bgclass = 'windowbg2';
		$poll_icon = $img{'pollicon'};
	}

	# Censor the question.
	$poll_question = &Censor($poll_question);
	if ($ubbcpolls) {
		if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
		my $message = $poll_question;
		&DoUBBC;
		$poll_question = $message;
	}
	&ToChars($poll_question);

	$deletevote = '';
	if ($has_voted) {
		if ($users_votetext) {
			if (!$yyYaBBCloaded && $ubbcpolls) { require "$sourcedir/YaBBC.pl"; }
			$footer = $users_votetext;
			for ($i = 0; $i < @users_vote; $i++) {
				$optnum = $users_vote[$i];
				# Censor the user answer.
				$options[$optnum] = &Censor($options[$optnum]);
				if ($ubbcpolls) {
					$message = $options[$optnum];
					&DoUBBC;
					$options[$optnum] = $message;
				}
				&ToChars($options[$optnum]);
				$footer .= qq~$options[$optnum], ~;
			}
		}
		$footer =~ s/, \Z//;
		$footer .= qq~<br /><br /><span style="font-weight: bold;">$polltxt{'17'}: $totalvotes</span>~;
		$width = '';
		$deletevote .= $menusep if $viewthread;
		$deletevote .= qq~<a href="$scripturl?action=undovote;num=$pollnum$scp">$img{'deletevote'}</a>~;
		$deletevote .= $menusep if !$viewthread && $displayvoters;
	} else {
		$footer  = qq~<input type="submit" value="$polltxt{'18'}" class="button" />~;
		$width = qq~ width="80%"~;
		$bgclass = 'windowbg2';
	}
	&check_deletepoll;
	if ($iamguest || $poll_locked || $poll_nodelete{$username}) { $deletevote = ''; }

	$pollmain = qq~
<form name="removepoll" action="$scripturl?action=modify2;d=1" method="post" style="display: inline">
	<input type="hidden" name="thread" value="$pollnum" />
	<input type="hidden" name="id" value="Poll" />
</form>

<form name="poll" method="post" action="$scripturl?action=vote;num=$pollnum$scp" style="display: inline;">
<table cellpadding="4" cellspacing="1" border="0" width="100%" class="bordercolor" align="center">
<tr>
<td class="titlebg" valign="middle" align="left">
	<div style="float: left; width: 50%; text-align: left;">
		<span class="text1">$poll_icon <b>$polltxt{'15'}</b>$boardpoll</span>
	</div>
	<div style="float: left; width: 50%; text-align: right;">
		<span class="small">$lockpoll$modifypoll$deletepoll</span>
	</div>
</td>
</tr>
<tr>
<td valign="top" class="catbg">
	<div style="float: left; width: 80%;">
		<b>$polltxt{'16'}:</b> $poll_question
	</div>
	~;
	if($has_voted) {
		unless($hide_results && !$poll_locked) {
			$pollmain .= qq~
	<div style="float: left; width: 20%; text-align: right;">
		<script language="JavaScript1.2" type="text/javascript">
		<!--
		document.write('<a href="$scripturl?num=$viewnum"><img src="$imagesdir/bars.gif" border="0" alt="" /></a>');
		document.write('<a href="$scripturl?num=$viewnum;view=pie"><img src="$imagesdir/pie.gif" border="0" alt="" /></a>');
		//-->
		</script>
	</div>
	~;
		}
	}
	$pollmain .= qq~
</td>
</tr>
<tr>
<td colspan="2" align="center" class="$bgclass">
	$endedtext
	<div class="$bgclass" id="piestyle" style="width: 100%;"><br />~;

	if ($has_voted && $hide_results && !$poll_locked) {

		# Display Poll Hidden Message
		$pollmain .= qq~$polltxt{'47'}<br /><span class="small">($polltxt{'48'})</span><br />~;

	} else {
		if($has_voted) {
			if($INFO{'view'} eq "pie") {
				$pollmain .= qq~
		<script language="JavaScript1.2" src="$yyhtml_root/piechart.js" type="text/javascript"></script>
		<script language="JavaScript1.2" type="text/javascript">
		<!--
			if (document.getElementById('piestyle').currentStyle) {
				pie_colorstyle = document.getElementById('piestyle').currentStyle['color'];
			} else if (window.getComputedStyle) {
				var compStyle = window.getComputedStyle(document.getElementById('piestyle'), "");
				pie_colorstyle = compStyle.getPropertyValue('color');
			}
			else pie_colorstyle = "#000000";

			var pie = new pieChart();
			pie.pie_array = $piearray;
			pie.radius = $pie_radius;
			pie.use_legends = $pie_legends;
			pie.color_style = pie_colorstyle;
			pie.sliceAdd();
			//-->
		</script>~;
			}
			else {
				for ($i = 0; $i < @options; $i++) {
					unless ($options[$i]) { next; }
					# Display Poll Results
					$pollpercent = 0;
					$pollbar     = 0;
					if ($totalvotes > 0 && $maxvote > 0) {
						$pollpercent = (100 * $votes[$i]) / $totalvotes;
						$pollpercent = sprintf("%.1f", $pollpercent);
						$pollbar = int(150 * $votes[$i] / $maxvote);
					}
					$pollbar .= 'px';
					$pollmain .= qq~
		<div style="clear: both; height: 18px; vertical-align: middle;">
		<div style="float: left; width: 50%; text-align: right;">$options[$i]&nbsp;&nbsp;&nbsp;&nbsp;</div>
		<div style="float: left; text-align: left; width: $pollbar; height: 10px; background-color: $slicecolor[$i]; border: 1px outset $slicecolor[$i];"></div>
		<div class="small" style="float: left; text-align: left;">&nbsp;&nbsp;$votes[$i] ($pollpercent%)</div>
	</div>~;
				}
			}
		}
		else {
			for ($i = 0; $i < @options; $i++) {
				unless ($options[$i]) { next; }
				# Display Poll Options
				if ($multi_vote) { $input = qq~<input type="checkbox" name="option$i" id="option$i" value="$i" style="margin: 0; padding: 0; vertical-align: middle;" />~; }
				else { $input = qq~<input type="radio" name="option" id="option$i" value="$i" style="margin: 0; padding: 0; vertical-align: middle;" />~; }
				$pollmain .= qq~
	<div style="clear: both;">
		<div style="float: left; height: 22px; text-align: right;">$input <label for="option$i"><b>$options[$i]</b></label></div>
		</div>~;
			}
		}
	}
	$pollmain .= qq~
		<br />
	</div>
	<div style="width: 100%;">
		<br />$footer
	</div>~;
	if ($poll_comment ne '') {
		$poll_comment = &Censor($poll_comment);
		$message = $poll_comment;
		if ($enable_ubbc) {
			if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
			&DoUBBC;
		}
		$poll_comment = $message;
		&ToChars($poll_comment);
		$pollmain .= qq~
	<div style="width: 100%;"><br />$poll_comment</div>~;
	}
	if (!$poll_locked && $poll_end) {
		my $x = $poll_end - $date;
		my $days  = int($x / 86400);
		my $hours = int(($x - ($days * 86400)) / 3600);
		my $min   = int(($x - ($days * 86400) - ($hours * 3600)) / 60);
		$poll_end = "$post_polltxt{'100'} ";
		$poll_end .= "$days $post_polltxt{'100a'}" . ($hours ? ", " : " $post_polltxt{'100c'} ") if $days;
		$poll_end .= "$hours $post_polltxt{'100b'} $post_polltxt{'100c'} " if $hours;
		$poll_end .= "$min $post_polltxt{'100d'}<br />";
	} else {
		$poll_end = '';
	}
	$pollmain .= qq~
	<div style="float: left; width: 49%; text-align: left;">
		<span class="small">$poll_end$displaydate</span>
	</div>
	<div style="float: left; width: 50%; text-align: right;">
		<span class="small">$viewthread$deletevote$displayvoters</span>
	</div>
    </td>
  </tr>
</table>
</form>~;
}

sub check_deletepoll {
	fopen(FILE, "$datadir/$pollnum.poll");
	$poll_chech = <FILE>;
	fclose(FILE);
	chomp $poll_chech;
	$vote_limit = (split /\|/, $poll_chech, 14)[12];
	$poll_nodelete{$username} = 0;
	if (!$vote_limit) {
		$poll_nodelete{$username} = 1;
		return;
	}
	if (-e "$datadir/$pollnum.polled") {
		fopen(FILE, "$datadir/$pollnum.polled");
		@chpolled = <FILE>;
		fclose(FILE);
		foreach $chvoter (@chpolled) {
			(undef, $chvotersname, undef, $chvotedate) = split(/\|/, $chvoter);
			if ($chvotersname eq $username) {
				$chdiff = $date - $chvotedate;
				if ($chdiff > ($vote_limit * 60)) {
					$poll_nodelete{$username} = 1;
					last;
				}
			}
		}
	}
}

sub ShowcasePoll {
	is_admin_or_gmod;
	my $thrdid = $INFO{'num'};
	fopen (SCFILE, ">$datadir/showcase.poll");
	print SCFILE $thrdid;
	fclose (SCFILE);
	$yySetLocation = qq~$scripturl~;
	&redirectexit;
}

sub DelShowcasePoll{
	is_admin_or_gmod;
	if (-e "$datadir/showcase.poll") { unlink("$datadir/showcase.poll"); }
	$yySetLocation = qq~$scripturl~;
	&redirectexit;
}

1;