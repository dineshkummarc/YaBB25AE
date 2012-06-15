###############################################################################
# Load.pl                                                                     #
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

$loadplver = 'YaBB 2.5 AE $Revision: 1.43 $';

sub LoadBoardControl {
	my ($cntcat, $cntboard, $cntpic, $cntdescription, $cntmods, $cntmodgroups, $cnttopicperms, $cntreplyperms, $cntpollperms, $cntzero, $dummy, $dummy, $dummy, $cnttotals);
	$binboard = "";
	$annboard = "";

	fopen(FORUMCONTROL, "$boardsdir/forum.control") || &fatal_error('cannot_open', "$boardsdir/forum.control", 1);
	my @boardcontrols = <FORUMCONTROL>;
	fclose(FORUMCONTROL);
	$maxboards = $#boardcontrols;

	foreach my $boardline (@boardcontrols) {
		$boardline =~ s/[\r\n]//g; # Built in chomp

		($cntcat, $cntboard, $cntpic, $cntdescription, $cntmods, $cntmodgroups, $cnttopicperms, $cntreplyperms, $cntpollperms, $cntzero, $cntmembergroups, $cntann, $cntrbin, $cntattperms, $cntminageperms, $cntmaxageperms, $cntgenderperms) = split(/\|/, $boardline);
		## create a global boards array
		push(@allboards, $cntboard);

		$cntdescription =~ s/\&/\&amp;/g;

		%{ $uid . $cntboard } = (
			'cat'          => $cntcat,
			'description'  => $cntdescription,
			'pic'          => $cntpic,
			'mods'         => $cntmods,
			'modgroups'    => $cntmodgroups,
			'topicperms'   => $cnttopicperms,
			'replyperms'   => $cntreplyperms,
			'pollperms'    => $cntpollperms,
			'zero'         => $cntzero,
			'membergroups' => $cntmembergroups,
			'ann'          => $cntann,
			'rbin'         => $cntrbin,
			'attperms'     => $cntattperms,
			'minageperms'  => $cntminageperms,
			'maxageperms'  => $cntmaxageperms,
			'genderperms'  => $cntgenderperms,);
		if ($cntann == 1)  { $annboard = $cntboard; }
		if ($cntrbin == 1) { $binboard = $cntboard; }
	}
}

sub LoadIMs {
	return if ($iamguest || $PM_level == 0 || ($maintenance && !$iamadmin) || ($PM_level == 2 && (!$iamadmin && !$iamgmod && !$iammod)) || ($PM_level == 3 && (!$iamadmin && !$iamgmod)));

	&buildIMS($username, 'load') unless exists ${$username}{'PMmnum'};

	my $imnewtext;
	if (${$username}{'PMimnewcount'} == 1) { $imnewtext = qq~<a href="$scripturl?action=imshow;caller=1;id=-1">1 $load_txt{'155'}</a>~; }
	elsif (!${$username}{'PMimnewcount'}) { $imnewtext = $load_txt{'nonew'}; }
	else { $imnewtext = qq~<a href="$scripturl?action=imshow;caller=1;id=-1">${$username}{'PMimnewcount'} $load_txt{'154'}</a>~; }

	if (${$username}{'PMmnum'} == 1) { $yyim = qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'471'}</a>, $imnewtext~; }
	elsif (!${$username}{'PMmnum'} && !${$username}{'PMimnewcount'}) { $yyim = qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'153'}</a>~; }
	else { $yyim = qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'153'}</a>, $imnewtext~; }

	if (!$user_ip && $iamadmin) { $yyim .= qq~<br /><b>$load_txt{'773'}</b>~; }
}

sub LoadCensorList {
	if ($#censored > 0 || -s "$langdir/$language/censor.txt" < 3 || !-e "$langdir/$language/censor.txt") { return; }
	fopen(CENSOR, "$langdir/$language/censor.txt") || &fatal_error("cannot_open","$langdir/$language/censor.txt", 1);
	while (chomp($buffer = <CENSOR>)) {
		$buffer =~ s/\r(?=\n*)//g;
		if ($buffer =~ m/\~/) {
			($tmpa, $tmpb) = split(/\~/, $buffer);
			$tmpc = 0;
		} else {
			($tmpa, $tmpb) = split(/=/, $buffer);
			$tmpc = 1;
		}
		push(@censored, [$tmpa, $tmpb, $tmpc]);
	}
	fclose(CENSOR);
}

sub LoadUserSettings {
	&LoadBoardControl;
	$iamguest = $username eq 'Guest' ? 1 : 0;
	if ($username ne 'Guest') {
		&LoadUser($username);
		if (!$maintenance || ${$uid.$username}{'position'} eq 'Administrator') {
			$iammod = &is_moderator($username);
			if (${$uid.$username}{'position'} eq 'Administrator' || ${$uid.$username}{'position'} eq 'Global Moderator' || $iammod) { $staff = 1; }
			else { $staff = 0; }
			$sessionvalid = 1;
			if ($sessions == 1 && $staff == 1) {
				$cursession = &encode_password($user_ip);
				chomp $cursession;
				if (${$uid.$username}{'session'} ne $cursession || ${$uid.$username}{'session'} ne $cookiesession) { $sessionvalid = 0; }
			}
			$spass = ${$uid.$username}{'password'};

			# Make sure that if the password doesn't match you get FULLY Logged out
			if ($spass && $spass ne $password && $action ne 'logout') {
				$yySetLocation = $guestaccess ? qq~$scripturl~ : qq~$scripturl?action=login~;
				&UpdateCookie("delete");
				&redirectexit;
			}

			$iamadmin  = (${$uid.$username}{'position'} eq 'Administrator' && $sessionvalid == 1) ? 1 : 0;
			$iamgmod   = (${$uid.$username}{'position'} eq 'Global Moderator' && $sessionvalid == 1) ? 1 : 0;
			if ($sessionvalid == 1) { ${$uid.$username}{'session'} = $cursession; }
			&CalcAge($username, "calc");
			# Set the order how Topic summaries are displayed
			$ttsreverse = ${$uid.$username}{'reversetopic'} if !$adminscreen && $ttsureverse;
			return;
		}
	}

	&FormatUserName('');
	&UpdateCookie("delete");
	$username           = 'Guest';
	$iamguest           = '1';
	$iamadmin           = '';
	$iamgmod            = '';
	$password           = '';
	$ENV{'HTTP_COOKIE'} = '';
	$yyim               = '';
	$yyuname            = '';
}

sub FormatUserName {
	my $user = $_[0];
	return if $useraccount{$user};
	$useraccount{$user} = $do_scramble_id ? &cloak($user) : $user;
}

sub LoadUser {
	my ($user,$userextension) = @_;
	return 1 if exists ${$uid.$user}{'realname'};
	return 0 if $user eq '' || $user eq 'Guest';

	if (!$userextension){ $userextension = 'vars'; }
	if (($regtype == 1 || $regtype == 2) && -e "$memberdir/$user.pre") { $userextension = 'pre'; }
	elsif ($regtype == 1 && -e "$memberdir/$user.wait") { $userextension = 'wait'; }

	if (-e "$memberdir/$user.$userextension") {
		if ($user ne $username) {
			fopen(LOADUSER, "$memberdir/$user.$userextension") || &fatal_error('cannot_open', "$memberdir/$user.$userextension", 1);
			my @settings = <LOADUSER>;
			fclose(LOADUSER);
			foreach (@settings) { if ($_ =~ /'(.*?)',"(.*?)"/) { ${$uid.$user}{$1} = $2; } }
		} else {
			fopen(LOADUSER, "+<$memberdir/$user.$userextension") || &fatal_error('cannot_open', "$memberdir/$user.$userextension", 1);
			my @settings = <LOADUSER>;
			for (my $i = 0; $i < @settings; $i++) {
				if ($settings[$i] =~ /'(.*?)',"(.*?)"/) {
					${$uid.$user}{$1} = $2;
					if($1 eq 'lastonline' && $INFO{'action'} ne "login2") {
						${$uid.$user}{$1} = $date;
						$settings[$i] = qq~'lastonline',"$date"\n~;
					}
				}
			}
			seek LOADUSER, 0, 0;
			truncate LOADUSER, 0;
			print LOADUSER @settings;
			fclose(LOADUSER);
		}

		&FormatUserName($user);
		&LoadMiniUser($user);

		return 1;
	}

	return 0; # user not found
}

sub is_moderator {
	my $user = $_[0];
	my @checkboards;
	if ($_[1]) { @checkboards = ($_[1]); }
	else { @checkboards = @allboards; }

	foreach (@checkboards) {
		# check if user is in the moderator list
		foreach (split(/, ?/, ${$uid.$_}{'mods'})) {
			if ($_ eq $user) { return 1; }
		}

		# check if user is member of a moderatorgroup
		foreach my $testline (split(/, /, ${$uid.$_}{'modgroups'})) {
			if ($testline eq ${$uid.$user}{'position'}) { return 1; }

			foreach (split(/,/, ${$uid.$user}{'addgroups'})) {
				if ($testline eq $_) { return 1; }
			}
		}
	}
	return 0;
}

sub KillModerator {
	my $killmod = $_[0];
	my ($cntcat, $cntboard, $cntpic, $cntdescription, $cntmods, $cntmodgroups, $cnttopicperms, $cntreplyperms, $cntpollperms, $cntzero, $dummy, $dummy, $dummy, $cnttotals, @boardcontrol);
	fopen(FORUMCONTROL, "+<$boardsdir/forum.control") || &fatal_error('cannot_open', "$boardsdir/forum.control", 1);
	@oldcontrols = <FORUMCONTROL>;

	my @newmods;
	foreach $boardline (@oldcontrols) {
		chomp $boardline;
		if ($boardline ne "") {
			@newmods = ();
			($cntcat, $cntboard, $cntpic, $cntdescription, $cntmods, $cntmodgroups, $cnttopicperms, $cntreplyperms, $cntpollperms, $cntzero, $cntpassword, $cnttotals, $cntattperms, $spare, $cntminageperms, $cntmaxageperms, $cntgenderperms) = split(/\|/, $boardline);
			foreach (split(/, /, $cntmods)) {
				if ($killmod ne $_) { push(@newmods, $_); }
			}
			$cntmods = join(", ", @newmods);
			push(@boardcontrol, "$cntcat|$cntboard|$cntpic|$cntdescription|$cntmods|$cntmodgroups|$cnttopicperms|$cntreplyperms|$cntpollperms|$cntzero|$cntpassword|$cnttotals|$cntattperms|$spare|$cntminageperms|$cntmaxageperms|$cntgenderperms\n");
		}
	}
	seek FORUMCONTROL, 0, 0;
	truncate FORUMCONTROL, 0;
	@boardcontrol = &undupe(@boardcontrol);
	print FORUMCONTROL @boardcontrol;
	fclose(FORUMCONTROL);
}

sub KillModeratorGroup {
	my $killmod = $_[0];
	my ($cntcat, $cntboard, $cntpic, $cntdescription, $cntmods, $cntmodgroups, $cnttopicperms, $cntreplyperms, $cntpollperms, $cntzero, $dummy, $dummy, $dummy, $cnttotals, @boardcontrol);
	fopen(FORUMCONTROL, "+<$boardsdir/forum.control") || &fatal_error('cannot_open', "$boardsdir/forum.control", 1);
	@oldcontrols = <FORUMCONTROL>;

	my @newmods;
	foreach $boardline (@oldcontrols) {
		chomp $boardline;
		if ($boardline ne "") {
			@newmods = ();
			($cntcat, $cntboard, $cntpic, $cntdescription, $cntmods, $cntmodgroups, $cnttopicperms, $cntreplyperms, $cntpollperms, $cntzero, $cntpassword, $cnttotals, $cntattperms, $spare, $cntminageperms, $cntmaxageperms, $cntgenderperms) = split(/\|/, $boardline);
			foreach (split(/, /, $cntmodgroups)) {
				if ($killmod ne $_) { push(@newmods, $_); }
			}
			$cntmodgroups = join(", ", @newmods);
			push(@boardcontrol, "$cntcat|$cntboard|$cntpic|$cntdescription|$cntmods|$cntmodgroups|$cnttopicperms|$cntreplyperms|$cntpollperms|$cntzero|$cntpassword|$cnttotals|$cntattperms|$spare|$cntminageperms|$cntmaxageperms|$cntgenderperms\n");
		}
	}
	seek FORUMCONTROL, 0, 0;
	truncate FORUMCONTROL, 0;
	@boardcontrol = &undupe(@boardcontrol);
	print FORUMCONTROL @boardcontrol;
	fclose(FORUMCONTROL);
}

sub LoadUserDisplay {
	my $user = $_[0];
	if (exists ${$uid.$user}{'password'}) {
		if ($yyUDLoaded{$user}) { return 1; }
	} else {
		&LoadUser($user);
	}
	&LoadCensorList;

	${$uid.$user}{'weburl'} = ${$uid.$user}{'weburl'} ? qq~<a href="${$uid.$user}{'weburl'}" target="_blank">~ . ($sm ? $img{'website_sm'} : $img{'website'}) . '</a>' : '';

	$displayname = ${$uid.$user}{'realname'};
	if (${$uid.$user}{'signature'}) {
		$message = ${$uid.$user}{'signature'};

		if ($enable_ubbc) {
			if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
			&DoUBBC(1);
		}

		&ToChars($message);

		${$uid.$user}{'signature'} = &Censor($message);

		# use height like code boxes do. Set to 200px at > 15 newlines
		if (15 < ${$uid.$user}{'signature'} =~ /<br \/>|<tr>/g) {
			${$uid.$user}{'signature'} = qq~<div style="float: left; font-size: 10px; font-family: verdana, sans-serif; overflow: auto; max-height: 200px; height: 200px; width: 99%;">${$uid.$user}{'signature'}</div>~;
		} else {
			${$uid.$user}{'signature'} = qq~<div style="float: left; font-size: 10px; font-family: verdana, sans-serif; overflow: auto; max-height: 200px; width: 99%;">${$uid.$user}{'signature'}</div>~;
		}
	}

	$themsnuser   = $user;
	$themsnname   = ${$uid.$user}{'realname'};
	$thegtalkuser = $user;
	$thegtalkname = ${$uid.$user}{'realname'};

	if ($UseMenuType == 0) {
		$yimimg = qq~<img src="$imagesdir/yim.gif" alt="${$uid.$user}{'yim'}" title="${$uid.$user}{'yim'}" border="0" />~;
		$aimimg = qq~<img src="$imagesdir/aim.gif" alt="${$uid.$user}{'aim'}" title="${$uid.$user}{'aim'}" border="0" />~;
		$skypeimg = qq~<img src="$imagesdir/skype.gif" alt="${$uid.$user}{'skype'}" title="${$uid.$user}{'skype'}" border="0" />~;
		$myspaceimg = qq~<img src="$imagesdir/myspace.gif" alt="${$uid.$user}{'myspace'}" title="${$uid.$user}{'myspace'}" border="0" />~;
		$facebookimg = qq~<img src="$imagesdir/facebook.gif" alt="${$uid.$user}{'facebook'}" title="${$uid.$user}{'facebook'}" border="0" />~;
		$msnimg = qq~<img src="$imagesdir/msn.gif" style="cursor: pointer" onclick="window.open('$scripturl?action=setmsn;msnname=$themsnuser','','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'); return false" alt="$themsnname" title="$themsnname" border="0" />~;
		$gtalkimg = qq~<img src="$imagesdir/gtalk2.gif" style="cursor: pointer" onclick="window.open('$scripturl?action=setgtalk;gtalkname=$thegtalkuser','','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'); return false" alt="$thegtalkname" title="$thegtalkname" border="0" />~;
		$icqimg = qq~<img src="http://web.icq.com/whitepages/online?icq=${$uid.$user}{'icq'}&#38;img=5" alt="${$uid.$user}{'icq'}" title="${$uid.$user}{'icq'}" border="0" />~;
	} elsif ($UseMenuType == 1) {
		$yimimg = qq~<span class="imgwindowbg">YIM</span>~;
		$aimimg = qq~<span class="imgwindowbg">AIM</span>~;
		$skypeimg = qq~<span class="imgwindowbg">Skype/VoIP</span>~;
		$myspaceimg = qq~<span class="imgwindowbg">MySpace</span>~;
		$facebookimg = qq~<span class="imgwindowbg">Facebook</span>~;
		$msnimg = qq~<span class="imgwindowbg" style="cursor: pointer" onclick="window.open('$scripturl?action=setmsn;msnname=$themsnuser','','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'); return false">MSN</span>~;
		$gtalkimg = qq~<span class="imgwindowbg" style="cursor: pointer" onclick="window.open('$scripturl?action=setgtalk;gtalkname=$thegtalkuser','','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'); return false">GTalk</span>~;
		$icqimg   = qq~<span class="imgwindowbg">ICQ</span>~;
	} else {
		$yimimg = qq~<img src="$yyhtml_root/Buttons/$language/yim.png" alt="${$uid.$user}{'yim'}" title="${$uid.$user}{'yim'}" border="0" />~;
		$aimimg = qq~<img src="$yyhtml_root/Buttons/$language/aim.png" alt="${$uid.$user}{'aim'}" title="${$uid.$user}{'aim'}" border="0" />~;
		$skypeimg = qq~<img src="$yyhtml_root/Buttons/$language/skype.png" alt="${$uid.$user}{'skype'}" title="${$uid.$user}{'skype'}" border="0" />~;
		$myspaceimg = qq~<img src="$yyhtml_root/Buttons/$language/myspace.png" alt="${$uid.$user}{'myspace'}" title="${$uid.$user}{'myspace'}" border="0" />~;
		$facebookimg = qq~<img src="$yyhtml_root/Buttons/$language/facebook.png" alt="${$uid.$user}{'facebook'}" title="${$uid.$user}{'facebook'}" border="0" />~;
		$msnimg = qq~<img src="$yyhtml_root/Buttons/$language/msn.png" style="cursor: pointer" onclick="window.open('$scripturl?action=setmsn;msnname=$themsnuser','','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'); return false" alt="$themsnname" title="$themsnname" border="0" />~;
		$gtalkimg = qq~<img src="$yyhtml_root/Buttons/$language/gtalk.png" style="cursor: pointer" onclick="window.open('$scripturl?action=setgtalk;gtalkname=$thegtalkuser','','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'); return false" alt="$thegtalkname" title="$thegtalkname" border="0" />~;
		$icqimg = qq~<img src="$yyhtml_root/Buttons/$language/icq.png" alt="${$uid.$user}{'icq'}" title="${$uid.$user}{'icq'}" border="0" />~;
	}

	$icqad{$user} = $icqad{$user} ? qq~<a href="http://web.icq.com/${$uid.$user}{'icq'}" target="_blank"><img src="$imagesdir/icqadd.gif" alt="${$uid.$user}{'icq'}" title="${$uid.$user}{'icq'}" border="0" /></a>~ : '';
	${$uid.$user}{'icq'} = ${$uid.$user}{'icq'} ? qq~<a href="http://web.icq.com/${$uid.$user}{'icq'}" title="${$uid.$user}{'icq'}" target="_blank">$icqimg</a>~ : '';
	${$uid.$user}{'aim'} = ${$uid.$user}{'aim'} ? qq~<a href="aim:goim?screenname=${$uid.$user}{'aim'}&#38;message=Hi.+Are+you+there?">$aimimg</a>~ : '';
	${$uid.$user}{'skype'} = ${$uid.$user}{'skype'} ? qq~<a href="javascript:void(window.open('callto://${$uid.$user}{'skype'}','skype','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'))">$skypeimg</a>~ : '';
	${$uid.$user}{'myspace'} = ${$uid.$user}{'myspace'} ? qq~<a href="http://www.myspace.com/${$uid.$user}{'myspace'}" target="_blank">$myspaceimg</a>~ : '';
	${$uid.$user}{'facebook'} = ${$uid.$user}{'facebook'} ? qq~<a href="http://www.facebook.com/~ . (${$uid.$user}{'facebook'} !~ /\D/ ? "profile.php?id=" : "") . qq~${$uid.$user}{'facebook'}" target="_blank">$facebookimg</a>~ : '';
	${$uid.$user}{'msn'} = ${$uid.$user}{'msn'}   ? $msnimg : '';
	${$uid.$user}{'gtalk'} = ${$uid.$user}{'gtalk'} ? $gtalkimg : '';
	$yimon{$user} = $yimon{$user} ? qq~<img src="http://opi.yahoo.com/online?u=${$uid.$user}{'yim'}&#38;m=g&#38;t=0" border="0" alt="" />~ : '';
	${$uid.$user}{'yim'} = ${$uid.$user}{'yim'} ? qq~<a href="http://edit.yahoo.com/config/send_webmesg?.target=${$uid.$user}{'yim'}" target="_blank">$yimimg</a>~ : '';

	if ($showgenderimage && ${$uid.$user}{'gender'}) {
		${$uid.$user}{'gender'} = ${$uid.$user}{'gender'} =~ m~Female~i ? 'female' : 'male';
		${$uid.$user}{'gender'} = ${$uid.$user}{'gender'} ? qq~$load_txt{'231'}: <img src="$imagesdir/${$uid.$user}{'gender'}.gif" border="0" alt="${$uid.$user}{'gender'}" title="${$uid.$user}{'gender'}" /><br />~ : '';
	} else {
		${$uid.$user}{'gender'} = '';
	}

	if ($showusertext && ${$uid.$user}{'usertext'}) { # Censor the usertext and wrap it
		${$uid.$user}{'usertext'} = &WrapChars(&Censor(${$uid.$user}{'usertext'}),20);
	} else {
		${$uid.$user}{'usertext'} = "";
	}

	# Create the userpic / avatar html
	if ($showuserpic && $allowpics) {
		${$uid.$user}{'userpic'} ||= 'blank.gif';
		${$uid.$user}{'userpic'} = qq~<img src="~ .(${$uid.$user}{'userpic'} =~ m~\A[\s\n]*https?://~i ? ${$uid.$user}{'userpic'} : "$facesurl/${$uid.$user}{'userpic'}") . qq~" name="avatar_img_resize" alt="" border="0" style="display:none" /><br />~;
	} else {
		${$uid.$user}{'userpic'} = '<br />';
	}

	&LoadMiniUser($user);

	$yyUDLoaded{$user} = 1;
	return 1;
}

sub LoadMiniUser {
	my $user = $_[0];
	my $load = '';
	my $key  = '';
	$g = 0;
	my $dg = 0;
	my ($tempgroup, $temp_postgroup);
	my $noshow = 0;
	my $bold   = 0;

	$tempgroupcheck = ${$uid.$user}{'position'} || "";

	if (exists $Group{$tempgroupcheck} && $tempgroupcheck ne "") {
		($title, $stars, $starpic, $color, $noshow, $viewperms, $topicperms, $replyperms, $pollperms, $attachperms) = split(/\|/, $Group{$tempgroupcheck});
		$temptitle = $title;
		$tempgroup = $Group{$tempgroupcheck};
		if ($noshow == 0) { $bold = 1; }
		$memberunfo{$user} = $tempgroupcheck;
	} elsif ($moderators{$user}) {
		($title, $stars, $starpic, $color, $noshow, $viewperms, $topicperms, $replyperms, $pollperms, $attachperms) = split(/\|/, $Group{'Moderator'});
		$temptitle         = $title;
		$tempgroup         = $Group{'Moderator'};
		$memberunfo{$user} = $tempgroupcheck;
	} elsif (exists $NoPost{$tempgroupcheck} && $tempgroupcheck ne "") {
		($title, $stars, $starpic, $color, $noshow, $viewperms, $topicperms, $replyperms, $pollperms, $attachperms) = split(/\|/, $NoPost{$tempgroupcheck});
		$temptitle         = $title;
		$tempgroup         = $NoPost{$tempgroupcheck};
		$memberunfo{$user} = $tempgroupcheck;
	}

	if (!$tempgroup) {
		foreach $postamount (sort { $b <=> $a } keys %Post) {
			if (${$uid.$user}{'postcount'} >= $postamount) {
				($title, $stars, $starpic, $color, $noshow, $viewperms, $topicperms, $replyperms, $pollperms, $attachperms) = split(/\|/, $Post{$postamount});
				$tempgroup = $Post{$postamount};
				last;
			}
		}
		$memberunfo{$user} = $title;
	}

	if ($noshow == 1) {
		$temptitle = $title;
		foreach $postamount (sort { $b <=> $a } keys %Post) {
			if (${$uid.$user}{'postcount'} > $postamount) {
				($title, $stars, $starpic, $color, undef) = split(/\|/, $Post{$postamount},5);
				last;
			}
		}
	}

	if (!$tempgroup) {
		$temptitle   = "no group";
		$title       = "";
		$stars       = 0;
		$starpic     = "";
		$color       = "";
		$noshow      = 1;
		$viewperms   = "";
		$topicperms  = "";
		$replyperms  = "";
		$pollperms   = "";
		$attachperms = "";
	}

	# The following puts some new has variables in if this user is the user browsing the board
	if ($user eq $username) {
		if ($tempgroup) {
			($trash, $trash, $trash, $trash, $trash, $viewperms, $topicperms, $replyperms, $pollperms, $attachperms) = split(/\|/, $tempgroup);
		}
		${$uid.$user}{'perms'} = "$viewperms|$topicperms|$replyperms|$pollperms|$attachperms";
	}

	$userlink = ${$uid.$user}{'realname'} || $user;
	$userlink = qq~<b>$userlink</b>~;
	if (!$scripturl) { $scripturl = qq~$boardurl/$yyexec.$yyext~; }
	if ($bold != 1) { $memberinfo{$user} = qq~$title~; }
	else { $memberinfo{$user} = qq~<b>$title</b>~; }

	if ($color ne "") {
		$link{$user}      = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}" style="color:$color;">$userlink</a>~;
		$format{$user}    = qq~<span style="color: $color;">$userlink</span>~;
		$col_title{$user} = qq~<span style="color: $color;">$memberinfo{$user}</span>~;
	} else {
		$link{$user}      = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}">$userlink</a>~;
		$format{$user}    = qq~$userlink~;
		$col_title{$user} = qq~$memberinfo{$user}~;
	}
	$addmembergroup{$user} = "<br />";
	foreach $addgrptitle (split(/,/, ${$uid.$user}{'addgroups'})) {
		foreach $key (sort { $a <=> $b } keys %NoPost) {
			($atitle, $t, $t, $t, $anoshow, $aviewperms, $atopicperms, $areplyperms, $apollperms, $aattachperms) = split(/\|/, $NoPost{$key});
			if ($addgrptitle eq $key && $atitle ne $title) {
				if ($user eq $username && !$iamadmin) {
					if ($aviewperms == 1)   { $viewperms   = 1; }
					if ($atopicperms == 1)  { $topicperms  = 1; }
					if ($areplyperms == 1)  { $replyperms  = 1; }
					if ($apollperms == 1)   { $pollperms   = 1; }
					if ($aattachperms == 1) { $attachperms = 1; }
					${$uid.$user}{'perms'} = "$viewperms|$topicperms|$replyperms|$pollperms|$attachperms";
				}
				if ($anoshow && ($iamadmin || ($iamgmod && $gmod_access2{"profileAdmin"}))) {
					$addmembergroup{$user} .= qq~($atitle)<br />~;
				} elsif (!$anoshow) {
					$addmembergroup{$user} .= qq~$atitle<br />~;
				}
			}
		}
	}
	$addmembergroup{$user} =~ s/<br \/>\Z//;

	if ($username eq "Guest") { $memberunfo{$user} = "Guest"; }

	$topicstart{$user} = "";
	$viewnum = "";
	if ($INFO{'num'} || $FORM{'threadid'} && $user eq $username) {
		if ($INFO{'num'}) {
			$viewnum = $INFO{'num'};
		} elsif ($FORM{'threadid'}) {
			$viewnum = $FORM{'threadid'};
		}
		if ($viewnum =~ m~/~) { ($viewnum, undef) = split('/', $viewnum); }

		# No need to open the message file so many times.
		# Opening it once is enough to do the access checks.
		unless ($topicstarter) {
			if (-e "$datadir/$viewnum.txt") {
				unless (ref($thread_arrayref{$viewnum})) {
					fopen(TOPSTART, "$datadir/$viewnum.txt");
					@{$thread_arrayref{$viewnum}} = <TOPSTART>;
					fclose(TOPSTART);
				}
				(undef, undef, undef, undef, $topicstarter, undef) = split(/\|/, ${$thread_arrayref{$viewnum}}[0], 6);
			}
		}

		if ($user eq $topicstarter) { $topicstart{$user} = "Topic Starter"; }
	}
	$memberaddgroup{$user} = ${$uid.$user}{'addgroups'};

	my $starnum = $stars;
	my $memberstartemp = '';
	if ($starpic !~ /\//) { $starpic = "$imagesdir/$starpic"; }
	while ($starnum-- > 0) {
		$memberstartemp .= qq~<img src="$starpic" border="0" alt="*" />~;
	}
	$memberstar{$user} = $memberstartemp ? "$memberstartemp<br />" : "";
}

sub QuickLinks {
	my $user = $_[0];
	my $lastonline;
	if ($iamguest) { return ($_[1] ? ${$uid.$user}{'realname'} : $format{$user}); }

	if ($iamadmin || $iamgmod || $lastonlineinlink) {
		if(${$uid.$user}{'lastonline'}) {
			$lastonline = $date - ${$uid.$user}{'lastonline'};
			my $days  = int($lastonline / 86400);
			my $hours = sprintf("%02d", int(($lastonline - ($days * 86400)) / 3600));
			my $mins  = sprintf("%02d", int(($lastonline - ($days * 86400) - ($hours * 3600)) / 60));
			my $secs  = sprintf("%02d", ($lastonline - ($days * 86400) - ($hours * 3600) - ($mins * 60)));
			if (!$mins) {
				$lastonline = "00:00:$secs";
			} elsif (!$hours) {
				$lastonline = "00:$mins:$secs";
			} elsif (!$days) {
				$lastonline = "$hours:$mins:$secs";
			} else {
				$lastonline = "$days $maintxt{'11'} $hours:$mins:$secs";
			}
				$lastonline = qq~ title="$maintxt{'10'} $lastonline $maintxt{'12'}."~;
		} else {
			$lastonline = qq~ title="$maintxt{'13'}."~;
		}
	}
	if ($usertools) {
		$qlcount++;
		my $display = "display:inline";
		if ($ENV{'HTTP_USER_AGENT'} =~ /opera/i) {
			$display = "display:inline-block";
		} elsif ($ENV{'HTTP_USER_AGENT'} =~ /firefox/i) {
			$display = "display:inline-block";
		}
		my $quicklinks = qq~<div style="position:relative;$display">
			<ul id="ql$useraccount{$user}$qlcount" class="QuickLinks" onmouseover="keepLinks('$useraccount{$user}$qlcount')" onmouseout="TimeClose('$useraccount{$user}$qlcount')">
				<li>~ . &userOnLineStatus($user) . qq~<a href="javascript:closeLinks('$useraccount{$user}$qlcount')" style="position:absolute;right:3px"><b>X</b></a></li>\n~;
		if ($user ne $username) {
			$quicklinks .= qq~				<li><a href="$scripturl?action=viewprofile;username=$useraccount{$user}">$maintxt{'2'} ${$uid.$user}{'realname'}$maintxt{'3'}</a></li>\n~;
			&CheckUserPM_Level($user);
			if ($PM_level == 1 || ($PM_level == 2 && $UserPM_Level{$user} > 1 && $staff) || ($PM_level == 3 && $UserPM_Level{$user} == 3 && ($iamadmin || $iamgmod))) {
				$quicklinks .= qq~				<li><a href="$scripturl?action=imsend;to=$useraccount{$user}">$maintxt{'0'} ${$uid.$user}{'realname'}</a></li>\n~;
			}
			if (!${$uid.$user}{'hidemail'} || $iamadmin) {
				$quicklinks .= "				<li>" . &enc_eMail("$maintxt{'1'} ${$uid.$user}{'realname'}",${$uid.$user}{'email'},'','') . "</li>\n";
			}
			if (!%mybuddie) { &loadMyBuddy; }
			if ($buddyListEnabled && !$mybuddie{$user}) {
				$quicklinks .= qq~				<li><a href="$scripturl?action=addbuddy;name=$useraccount{$user}">$maintxt{'4'} ${$uid.$user}{'realname'} $maintxt{'5'}</a></li>\n~;
			}

		} else {
			$quicklinks .= qq~				<li><a href="$scripturl?action=viewprofile;username=$useraccount{$user}">$maintxt{'6'}</a></li>\n~;
		}
		$quicklinks .= qq~			</ul><a href="javascript:quickLinks('$useraccount{$user}$qlcount')"$lastonline>~;
		$quicklinks .= $_[1] ? ${$uid.$user}{'realname'} : $format{$user};
		qq~$quicklinks</a></div>~;

	} else {
		qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}"$lastonline>~ . ($_[1] ? ${$uid.$user}{'realname'} : $format{$user}) . qq~</a>~;
	}
}

sub LoadCookie {
	foreach (split(/; /, $ENV{'HTTP_COOKIE'})) {
		$_ =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		($cookie, $value) = split(/=/);
		$yyCookies{$cookie} = $value;
	}
	if ($yyCookies{$cookiepassword}) {
		$password      = $yyCookies{$cookiepassword};
		$username      = $yyCookies{$cookieusername} || 'Guest';
		$cookiesession = $yyCookies{$session_id};
	} else {
		$password = '';
		$username = 'Guest';
	}
	if ($yyCookies{'guestlanguage'} && !$FORM{'guestlang'} && $enable_guestlanguage) {
		$language = $guestLang = $yyCookies{'guestlanguage'};
	}
}

sub UpdateCookie {
	my ($what, $user, $passw, $sessionval, $pathval, $expire) = @_;
	my ($valid, $expiration);
	if ($what eq "delete") {
		$expiration = "Thursday, 01-Jan-1970 00:00:00 GMT";
		if ($pathval eq "") { $pathval = qq~/~; }
		if ($iamguest && $FORM{'guestlang'} && $enable_guestlanguage) {
			if($FORM{'guestlang'} && !$guestLang) { $guestLang = qq~$FORM{'guestlang'}~; }
			$language = qq~$guestLang~;
			$cookiepassword = "guestlanguage";
			$passw = qq~$language~;
			$expire = "persistent";
		}
		$valid = 1;
	} elsif ($what eq "write") {
		$expiration = $expire;
		if ($pathval eq "") { $pathval = qq~/~; }
		$valid = 1;
	}

	if ($valid) {
		if ($expire eq "persistent") { $expiration = "Sunday, 17-Jan-2038 00:00:00 GMT"; }
		$yySetCookies1 = &write_cookie(
			-name    => "$cookieusername",
			-value   => "$user",
			-path    => "$pathval",
			-expires => "$expiration");
		$yySetCookies2 = &write_cookie(
			-name    => "$cookiepassword",
			-value   => "$passw",
			-path    => "$pathval",
			-expires => "$expiration");
		$yySetCookies3 = &write_cookie(
			-name    => "$cookiesession_name",
			-value   => "$sessionval",
			-path    => "$pathval",
			-expires => "$expiration");
	}
}

sub LoadAccess {
	$yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'808'}<br />";
	$noaccesses = "";

	# Reply Check
	my $rcaccess = &AccessCheck($currentboard, 2) || 0;
	if ($rcaccess eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'809'}<br />"; }
	else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'809'}<br />"; }

	# Topic Check
	my $tcaccess = &AccessCheck($currentboard, 1) || 0;
	if ($tcaccess eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'810'}<br />"; }
	else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'810'}<br />"; }

	# Poll Check
	my $access = &AccessCheck($currentboard, 3) || 0;
	if ($access eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'811'}<br />"; }
	else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'811'}<br />"; }

	# Zero Post Check
	if ($username ne 'Guest') {
		if ($INFO{'zeropost'} != 1 && $rcaccess eq "granted") { $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'812'}<br />"; }
		else { $noaccesses .= "$load_txt{'805'} $load_txt{'807'} $load_txt{'812'}<br />"; }
	}

	$accesses = qq~$yesaccesses<br />$noaccesses~;
}

sub WhatTemplate {
	$found = 0;
	while (($curtemplate, $value) = each(%templateset)) {
		if ($curtemplate eq $default_template) { $template = $curtemplate; $found = 1; }
	}
	if (!$found) { $template = 'Forum default'; }
	if (${$uid.$username}{'template'} ne '') {
		if (!exists $templateset{${$uid.$username}{'template'}}) {
			${$uid.$username}{'template'} = 'Forum default';
			&UserAccount($username, "update");
		}
		while (($curtemplate, $value) = each(%templateset)) {
			if ($curtemplate eq ${$uid.$username}{'template'}) { $template = $curtemplate; }
		}
	}
	($usestyle, $useimages, $usehead, $useboard, $usemessage, $usedisplay, $usemycenter, $UseMenuType) = split(/\|/, $templateset{$template});

	if (!-e "$forumstylesdir/$usestyle.css") { $usestyle = 'default'; }
	if (!-e "$templatesdir/$usehead/$usehead.html") { $usehead = 'default'; }
	if (!-e "$templatesdir/$useboard/BoardIndex.template") { $useboard = 'default'; }
	if (!-e "$templatesdir/$usemessage/MessageIndex.template") { $usemessage = 'default'; }
	if (!-e "$templatesdir/$usedisplay/Display.template") { $usedisplay = 'default'; }
	if (!-e "$templatesdir/$usemycenter/MyCenter.template") { $usemycenter = 'default'; }

	if ($UseMenuType eq '') { $UseMenuType = $MenuType; }

	if (-d "$forumstylesdir/$useimages") { $imagesdir = "$forumstylesurl/$useimages"; }
	else { $imagesdir = "$forumstylesurl/default"; }
	$defaultimagesdir = "$forumstylesurl/default";
	$extpagstyle = qq~$forumstylesurl/$usestyle.css~;
	$extpagstyle =~ s~$usestyle\/~~g;
}

sub WhatLanguage {
	if (${$uid.$username}{'language'} ne '') {
		$language = ${$uid.$username}{'language'};
	} elsif($FORM{'guestlang'} && $enable_guestlanguage) {
		$language = $FORM{'guestlang'};
	} elsif($guestLang && $enable_guestlanguage) {
		$language = $guestLang;
	} else	{
		$language = $lang;
	}

	&LoadLanguage('Main');
	&LoadLanguage('Menu');

	if ($adminscreen) {
		&LoadLanguage('Admin');
		&LoadLanguage('FA');
	}

}

# build the .ims file from scratch
# here because its needed by admin and user
#messageid|[blank]|touser(s)|(ccuser(s))|(bccuser(s))|
#	subject|date|message|(parentmid)|(reply#)|ip|
#		messagestatus|flags|storefolder|attachment
# messagestatus = c(confidential)/h(igh importance)/s(tandard)
# parentmid stays same, reply# increments for replies, so we can build conversation threads
# storefolder = name of storage folder. Start with in & out for everyone. 
# flags - u(nread)/f(orward)/q(oute)/r(eply)/c(alled back)
#
# old file
#1	$mnum = 3;
#2	$imnewcount = 0;
#3	$moutnum = 17;
#4	$storenum = 0;
#5	$draftnum = 0;
#6	@folders  (name1|name2|name3);

# new .ims file format
#	### UserIMS YaBB 2.2 Version ###
#	'${$username}{'PMmnum'}',"value"
#	'${$username}{'PMimnewcount'}',"value"
#	'${$username}{'PMmoutnum'}',"value"
#	'${$username}{'PMstorenum'}',"value"
#	'${$username}{'PMdraftnum'}',"value"
#	'${$username}{'PMfolders'}',"value"
#	'${$username}{'PMfoldersCount'}',"value"
#	'${$username}{'PMbcRead'}',"value"

# usage: &buildIMS(<user>, 'tasks');
# tasks: load, update, '' [= rebuild]
sub buildIMS {
	my ($incurr, $inunr, $outcurr, $draftcount, @imstore, $storetotal, @storefoldersCount, $storeCounts);
	my ($builduser,$job) = @_;

	if ($job) {
		if ($job eq 'load') {
			&load_IMS($builduser);
		} else {
			&update_IMS($builduser);
		}
		return;
	}

	## inbox if it exists, either load and count totals or parse and update format.
	if (-e "$memberdir/$builduser.msg") {
		fopen(USERMSG, "$memberdir/$builduser.msg") || &fatal_error('cannot_open', "$memberdir/$builduser.msg", 1); # open inbox
		my @messages = <USERMSG>;
		fclose(USERMSG);

		# test the data for version. 16 elements in new format, no more than 8 in old.
		if (split(/\|/, $messages[0]) > 8) { # new format, so just need to check the flags
			foreach my $message (@messages) {
				# If the message is flagged as u(nopened), add to the new count
				if ((split /\|/, $message)[12] =~ /u/) { $inunr++; }
			}
			$incurr = @messages;

		} else { # old format, needs rearranging
			($inunr,$incurr) = &convert_MSG($builduser);
		}
	}

	## do the outbox
	if (-e "$memberdir/$builduser.outbox") {
		fopen("OUTMESS", "$memberdir/$builduser.outbox") || &fatal_error('cannot_open', "$memberdir/$builduser.outbox", 1);
		my @outmessages = <OUTMESS>;
		fclose("OUTMESS");
		if (split(/\|/, $outmessages[0]) > 8) { # > 10 elements in new format, no more than 8 in old
			$outcurr = @outmessages;
		} else {
			$outcurr = &convert_OUTBOX($builduser);
		}
	}

	## do the draft store - slightly easier - only exists in y22
	if (-e "$memberdir/$builduser.imdraft") {
		fopen("DRAFTMESS", "$memberdir/$builduser.imdraft") || &fatal_error('cannot_open', "$memberdir/$builduser.imdraft", 1);
		my @d = <DRAFTMESS>;
		fclose("DRAFTMESS");
		$draftcount = @d;
	}

	## grab the current list of store folders
	## else, create an entry for the two 'default ones' for the in/out status stuff
	my $storefolders = ${$builduser}{'PMfolders'} || "in|out";
	my @currStoreFolders = split(/\|/, $storefolders);
	if (-e "$memberdir/$builduser.imstore") {
		fopen(STOREMESS, "$memberdir/$builduser.imstore") || &fatal_error('cannot_open', "$memberdir/$builduser.imstore", 1);
		@imstore = <STOREMESS>;
		fclose (STOREMESS);
		if (@imstore) {
			# > 10 elements in new format, no more than 8 in old
			#messageid0|[blank]1|touser(s)2|(ccuser(s))3|(bccuser(s))4|
			#        subject5|date6|message7|(parentmid)8|(reply#)9|ip10|messagestatus11|flags12|storefolder13|attachment14
			if (split(/\|/, $imstore[0]) <= 8) { @imstore = &convert_IMSTORE($builduser); }

			my ($storeUpdated,$storeMessLine) = (0,0);
			foreach my $message (@imstore) {
				my @messLine = split(/\|/, $message);
				## look through list for folder name
				if ($messLine[13] eq '') { # some folder missing within imstore
					if ($messLine[1] ne '') { # 'from' name so inbox
						$messLine[13] = 'in';
					} else { # no 'from' so outbox
						$messLine[13] = 'out';
					}
					$imstore[$storeMessLine] = join('|', @messLine);
					$storeUpdated = 1;
				}
				unless ($storefolders =~ /\b$messLine[13]\b/) {
					push(@currStoreFolders, $messLine[13]);
					$storefolders = join('|', @currStoreFolders);
				}
				$storeMessLine++;
			}
			if ($storeUpdated == 1) {
				fopen(STRMESS, "+>$memberdir/$builduser.imstore") || &fatal_error('cannot_open', "$memberdir/$builduser.imstore", 1);
				print STRMESS @imstore;
				fclose(STRMESS);
			}
			$storetotal = @imstore;
			$storefolders = join('|', @currStoreFolders);

		} else {
			unlink "$memberdir/$builduser.imstore";
		}
	}
	## run through the messages and count against the folder name
	for (my $y = 0; $y < @currStoreFolders; $y++) {
		$storefoldersCount[$y] = 0;
		for (my $x = 0; $x < @imstore; $x++) {
			if ((split(/\|/, $imstore[$x]))[13] eq $currStoreFolders[$y]) {
				$storefoldersCount[$y]++;
			}
		} 
	}
	$storeCounts = join('|', @storefoldersCount);

	&LoadBroadcastMessages($builduser);

	${$builduser}{'PMmnum'} = $incurr || 0;
	${$builduser}{'PMimnewcount'} = $inunr || 0;
	${$builduser}{'PMmoutnum'} = $outcurr || 0;
	${$builduser}{'PMdraftnum'} = $draftcount || 0;
	${$builduser}{'PMstorenum'} = $storetotal || 0;
	${$builduser}{'PMfolders'} = $storefolders;
	${$builduser}{'PMfoldersCount'} = $storeCounts || 0;
	&update_IMS($builduser);
}

sub update_IMS {
	my $builduser = shift;
	my @tag = qw(PMmnum PMimnewcount PMmoutnum PMstorenum PMdraftnum PMfolders PMfoldersCount PMbcRead);

	fopen(UPDATE_IMS, ">$memberdir/$builduser.ims",1) || &fatal_error('cannot_open', "$memberdir/$builduser.ims", 1);
	print UPDATE_IMS qq~### UserIMS YaBB 2.2 Version ###\n\n~;
	for (my $cnt = 0; $cnt < @tag; $cnt++) {
		print UPDATE_IMS qq~'$tag[$cnt]',"${$builduser}{$tag[$cnt]}"\n~;
	}
	fclose(UPDATE_IMS);
}

sub load_IMS {
	my $builduser = shift;
	my @ims;
	if (-e "$memberdir/$builduser.ims") {
		fopen ("IMSFILE", "$memberdir/$builduser.ims") || &fatal_error('cannot_open', "$memberdir/$builduser.ims", 1);
		@ims = <IMSFILE>;
		fclose("IMSFILE");
	}

	if ($ims[0] =~ /###/) {
		foreach (@ims) { if ($_ =~ /'(.*?)',"(.*?)"/) { ${$builduser}{$1} = $2; } }
	} else {
		&buildIMS($builduser, '');
	}
}

sub LoadBroadcastMessages { #check broadcast messages
	return if ($iamguest || $PM_level == 0 || ($maintenance && !$iamadmin) || ($PM_level == 2 && (!$iamadmin && !$iamgmod && !$iammod)) || ($PM_level == 3 && (!$iamadmin && !$iamgmod)));

	my $builduser = shift;
	$BCnewMessage = 0;
	$BCCount = 0;
	if (-e "$memberdir/broadcast.messages") {
		my %PMbcRead;
		map { $PMbcRead{$_} = 0; } split(/,/, ${$builduser}{'PMbcRead'});

		fopen(BCMESS, "<$memberdir/broadcast.messages") || &fatal_error('cannot_open', "$memberdir/broadcast.messages", 1);
		my @bcmessages = <BCMESS>;
		fclose(BCMESS);
		foreach (@bcmessages) {
			my ($mnum, $mfrom, $mto, undef) = split (/\|/, $_, 4);
			if ($mfrom eq $username) { $BCCount++; $PMbcRead{$mnum} = 1; }
			elsif (&BroadMessageView($mto)) {
				$BCCount++;
				if (exists $PMbcRead{$mnum}) { $PMbcRead{$mnum} = 1; }
				else { $BCnewMessage++; }
			}
		}
		${$builduser}{'PMbcRead'} = '';
		foreach (keys %PMbcRead) {
			if ($PMbcRead{$_}) {
				${$builduser}{'PMbcRead' . $_} = 1;
				${$builduser}{'PMbcRead'} .= ${$builduser}{'PMbcRead'} ? ",$_" : $_;
			}
		}
	} else {
		${$builduser}{'PMbcRead'} = '';
	}
}

sub convert_MSG {
	my $builduser = shift;
	my $inunr;
	# clean out msg file and rebuild in new format
	# new format:
	# messageid(0)|from(1)|touser(2)|ccuser(3)|bccuser(4)|subject(5)|date(6)|message(7)|parentmid(8)|reply#(9)|ip(10)|messagestatus(11)|flags(12)|storefolder(13)|attachment(14)
	# old format:
	# from(0)|subject(1)|date(2)|message(3)|messageid(4)|ip(5)|read/replied(6)
	fopen(OLDMESS, "+<$memberdir/$builduser.msg") || &fatal_error('cannot_open', "$memberdir/$builduser.msg", 1);
	my @oldmessages = <OLDMESS>;
	chomp @oldmessages;
	seek OLDMESS , 0, 0;
	truncate OLDMESS, 0;
	foreach my $oldmessage (@oldmessages) { # parse messages for flags
		my @oldformat = split(/\|/,$oldmessage);
		# under old format, unread,and replied are exclusive, so no need to go mixing them
		if ($oldformat[6] == 1) { $oldformat[6] = 'u' ; $inunr++; } # if 6 (status) is 1 then change to u(nread) flag
		elsif ($oldformat[6] == 2) { $oldformat[6] = 'r'; } # if 6 (status) is 2 then change to r(eplied) flag
		# if any old style message ids still there, or odd blank ones, correct them to = date value
		if ($oldformat[4] < 101) { $oldformat[4] = $oldformat[2]; }
		# reassemble to new format and print back to file
		print OLDMESS "$oldformat[4]|$oldformat[0]|$builduser|||$oldformat[1]|$oldformat[2]|$oldformat[3]|$oldformat[4]|0|$oldformat[5]|s|$oldformat[6]||\n";
	}
	fclose(OLDMESS);
	($inunr,scalar @oldmessages);
}

sub convert_OUTBOX {
	my $builduser = shift;
	## clean out msg file and rebuild in new format
	fopen(OLDOUTBOX, "+<$memberdir/$builduser.outbox") || &fatal_error('cannot_open', "$memberdir/$builduser.outbox", 1);
	my @oldoutmessages = <OLDOUTBOX>;
	chomp @oldoutmessages;
	seek OLDOUTBOX, 0, 0;
	truncate OLDOUTBOX, 0;
	# clean out msg file and rebuild in new format
	# new format:
	# messageid(0)|from(1)|touser(2)|ccuser(3)|bccuser(4)|subject(5)|date(6)|message(7)|parentmid(8)|reply#(9)|ip(10)|messagestatus(11)|flags(12)|storefolder(13)|attachment(14)
	# old format:
	# from(0)|subject(1)|date(2)|message(3)|messageid(4)|ip(5)|read/replied(6)
	foreach my $oldmessage (@oldoutmessages) {
		my @oldformat = split(/\|/, $oldmessage);
		## if any old style message ids still there, or odd blank ones, correct them to = date value
		if ($oldformat[4] < 101 || $oldformat[4] eq '') { $oldformat[4] = $oldformat[2]; }
		## outbox can't be replied to ;) and forwarding doesn't exist in old format
		if (!$oldformat[6]) { $oldformat[6] = 'u'; }
		elsif ($oldformat[6] == 1) { $oldformat[6] = ''; }
		print OLDOUTBOX "$oldformat[4]|$builduser|$oldformat[0]|||$oldformat[1]|$oldformat[2]|$oldformat[3]|$oldformat[4]|0|$oldformat[5]|s|$oldformat[6]||\n";
	}
	fclose(OLDOUTBOX);
	return scalar @oldoutmessages;
}

sub convert_IMSTORE {
	my $builduser = shift;
	my @imstore;
	fopen(OLDIMSTORE, "+<$memberdir/$builduser.imstore") || &fatal_error('cannot_open', "$memberdir/$builduser.imstore", 1);
	my @oldstoremessages = <OLDIMSTORE>;
	chomp @oldstoremessages;
	seek OLDIMSTORE, 0, 0;
	truncate OLDIMSTORE, 0;
	# new format:
	# messageid(0)|from(1)|touser(2)|ccuser(3)|bccuser(4)|subject(5)|date(6)|message(7)|parentmid(8)|reply#(9)|ip(10)|messagestatus(11)|flags(12)|storefolder(13)|attachment(14)
	# old format:
	# from(0)|subject(1)|date(2)|message(3)|messageid(4)|ip(5)|read/replied(6)|folder/imwhere(7)
	foreach my $oldmessage (@oldstoremessages) {
		my @oldformat = split(/\|/, $oldmessage);
		my ($touser, $fromuser);
		if ($oldformat[7] eq 'outbox') { 
			$oldformat[7] = 'out';
			$touser = $oldformat[0];
			$fromuser = $builduser;
			if (!$oldformat[6]) { $oldformat[6] = 'u'; }
			elsif ($oldformat[6] == 1) { $oldformat[6] = 'r'; }
		} elsif ($oldformat[7] eq 'inbox') { 
			$oldformat[7] = 'in';
			$touser = $builduser;
			$fromuser = $oldformat[0];
			if ($oldformat[6] == 1) { $oldformat[6] = 'u'; }
			elsif ($oldformat[6] == 2) { $oldformat[6] = 'r'; }
		} 
		push (@imstore, "$oldformat[4]|$fromuser|$touser|||$oldformat[1]|$oldformat[2]|$oldformat[3]|$oldformat[4]|0|$oldformat[5]|s|$oldformat[6]|$oldformat[7]|\n");
	}
	print OLDIMSTORE @imstore;
	fclose(OLDIMSTORE);
	@imstore;
}

1;