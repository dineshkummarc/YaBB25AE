###############################################################################
# Subs.pl                                                                     #
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

$subsplver = 'YaBB 2.5 AE $Revision: 1.133 $';
if ($debug) { &LoadLanguage('Debug'); }

use subs 'exit';

$yymain = '';
$yyjavascript = '';
$langopt = '';

# set line wrap limit in Display.
$linewrap = 80;
$newswrap = 0;

# get the current date/time
$date = int(time() + $timecorrection);

# check if browser accepts encoded output
$gzaccept = $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/ || $gzforce;

# parse the query string
&readform;

$uid = substr($date, length($date) - 3, 3);
$session_id = $cookiesession_name;

$randaction = substr($date,0,length($date)-2);

$user_ip = $ENV{'REMOTE_ADDR'};
if ($user_ip eq "127.0.0.1") {
	if    ($ENV{'HTTP_CLIENT_IP'}       && $ENV{'HTTP_CLIENT_IP'}       ne "127.0.0.1") { $user_ip = $ENV{'HTTP_CLIENT_IP'}; }
	elsif ($ENV{'X_CLIENT_IP'}          && $ENV{'X_CLIENT_IP'}          ne "127.0.0.1") { $user_ip = $ENV{'X_CLIENT_IP'}; }
	elsif ($ENV{'HTTP_X_FORWARDED_FOR'} && $ENV{'HTTP_X_FORWARDED_FOR'} ne "127.0.0.1") { $user_ip = $ENV{'HTTP_X_FORWARDED_FOR'}; }
}

if (-e "$yyexec.cgi") { $yyext = "cgi"; }
else { $yyext = "pl"; }
if (-e "AdminIndex.cgi") { $yyaext = "cgi"; }
else { $yyaext = "pl"; }

sub automaintenance {
	my $maction = $_[0];
	my $mreason = $_[1];
	if (lc($maction) eq "on") {
		fopen (MAINT, ">$vardir/maintenance.lock");
		print MAINT qq~Remove this file if your board is in maintenance for no reason\n~;
		fclose (MAINT);
		if ($mreason eq "low_disk"){ 
			&LoadLanguage('Error');
			&alertbox($error_txt{'low_diskspace'}); 
		}
		$maintenance = 2 if !$maintenance;
	} elsif (lc($maction) eq "off") {
		unlink "$vardir/maintenance.lock" || &admin_fatal_error("cannot_open_dir","$vardir/maintenance.lock");
		$maintenance = 0 if $maintenance == 2;
	}
}

sub getnewid {
	my $newid = $date;
	while (-e "$datadir/$newid.txt") { ++$newid; }
	return $newid;
}

sub undupe {
	my (@out,$duped,$check);
	foreach $check (@_) {
		$duped = 0;
		foreach (@out) { if ($_ eq $check) { $duped = 1; last; } }
		if (!$duped) { push(@out, $check); }
	}
	return @out;
}

sub exit {
	local $| = 1;
	local $\ = '';
	print '';
	wait if $child_pid;
	CORE::exit($_[0] || 0);
}

sub print_output_header {
	$headerstatus ||= '200 OK';
	$contenttype  ||= 'text/html';

	my $ret = $yyIIS ? "HTTP/1.0 $headerstatus\n" : "Status: $headerstatus\n";

	foreach ($yySetCookies1,$yySetCookies2,$yySetCookies3) { $ret .= "Set-Cookie: $_\n" if $_; }

	if ($yySetLocation) {
		$ret .= "Location: $yySetLocation";
	} else {
		$ret .= "Cache-Control: no-cache, must-revalidate\nPragma: no-cache\n" if !$cachebehaviour;
		$ret .= "ETag: \"$ETag\"\n" if $ETag;
		$ret .= "Last-Modified: $LastModified\n" if $LastModified;
		$ret .= "Content-Encoding: gzip\n" if $gzcomp && $gzaccept;
		$ret .= "Content-Type: $contenttype";
		$ret .= "; charset=$yycharset" if $yycharset;
	}
	print $ret . "\r\n\r\n";
}

sub print_HTML_output_and_finish {
	if ($gzcomp && $gzaccept) {
		my $filehandle_exists = fileno GZIP;
		if ($gzcomp == 1 || $filehandle_exists) {
			$| = 1;
			open(GZIP, "| gzip -f") unless $filehandle_exists;
			print GZIP $output;
			close(GZIP);
		} else {
			require Compress::Zlib;
			binmode STDOUT;
			print Compress::Zlib::memGzip($output);
		}
	} else {
		print $output;
	}
	exit;
}

sub write_cookie {
	my %params = @_;

	if ($params{'-expires'} =~ /\+(\d+)m/) {
		my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($date + $1 * 60);

		$year += 1900;
		my @mos = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
		my @dys = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
		$mon  = $mos[$mon];
		$wday = $dys[$wday];

		$params{'-expires'} = sprintf("%s, %02i-%s-%04i %02i:%02i:%02i GMT", $wday, $mday, $mon, $year, $hour, $min, $sec);
	}

	$params{'-path'}    = " path=$params{'-path'};"       if $params{'-path'};
	$params{'-expires'} = " expires=$params{'-expires'};" if $params{'-expires'};

	"$params{'-name'}=$params{'-value'};$params{'-path'}$params{'-expires'}";
}

sub redirectexit {
	$headerstatus = '302 Moved Temporarily';
	&print_output_header;
	exit;
}

sub redirectinternal {
	if ($currentboard) {
		if ($INFO{'num'}) { require "$sourcedir/Display.pl"; &Display; }
		else { require "$sourcedir/MessageIndex.pl"; &MessageIndex; }
	} else {
		require "$sourcedir/BoardIndex.pl";
		&BoardIndex;
	}
}

sub ImgLoc {
	return (!-e "$forumstylesdir/$useimages/$_[0]" ? qq~$forumstylesurl/default/$_[0]~ : qq~$imagesdir/$_[0]~);
}

sub template {
	&print_output_header;

	if ($yytitle ne $maintxt{'error_description'}) { 
		if (!$iamguest || ($iamguest && $guestaccess == 1)) { $yyforumjump = &jumpto; }
	}
	$yyposition      = $yytitle;
	$yytitle         = "$mbname - $yytitle";
	$yyimages        = $imagesdir;
	$yydefaultimages = $defaultimagesdir;

	$yystyle  = qq~<link rel="stylesheet" href="$forumstylesurl/$usestyle.css" type="text/css" />\n~;
	$yystyle  =~ s~$usestyle\/~~g;
	$yystyle  .= qq~<link rel="stylesheet" href="$yyhtml_root/shjs/styles/sh_style.css" type="text/css" />\n~;
	$yystyle .= $yyinlinestyle; # This is for the Help Center and anywhere else that wants to add inline CSS.
$yysyntax_js = qq~
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_main.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_cpp.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_css.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_html.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_java.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_javascript.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_pascal.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_perl.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_php.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/shjs/sh_sql.js"></script>
<script language="JavaScript1.2" type="text/javascript" src="$yyhtml_root/YaBB.js"></script>
~;

	# add 'back to top' Button on the end of each page
	$yynavback .= qq~<img src="$imagesdir/tabsep211.png" border="0" alt="" style="vertical-align: middle;" />~ if !$yynavback;
	$yynavback .= qq~ <a href="#pagetop" class="nav">$img_txt{'102'}</a> <img src="$imagesdir/tabsep211.png" border="0" alt="" style="vertical-align: middle;" />~;

	if (!$usehead) { $usehead = qq~default~; }
	$yytemplate = "$templatesdir/$usehead/$usehead.html";
	fopen(TEMPLATE, $yytemplate) || die("$maintxt{'23'}: $yytemplate");
	$output = join('', <TEMPLATE>);
	fclose(TEMPLATE);

	if ($iamadmin || $iamgmod) {
		if ($maintenance) { $yyadmin_alert .= qq~<br /><span class="highlight"><b>$load_txt{'616'}</b></span>~; }
		if ($iamadmin && $rememberbackup) {
			if ($lastbackup && $date > $rememberbackup + $lastbackup) {
				$yyadmin_alert .= qq~<br /><span class="highlight"><b>$load_txt{'617'} ~ . &timeformat($lastbackup) . qq~</b></span>~;
			}
		}
	}

	$yyboardname = "$mbname";
	$yyboardlink = qq~<a href="$scripturl">$mbname</a>~;

	# static/dynamic clock
	$yytime = &timeformat($date, 1);
	if ($mytimeselected != 7 && (($iamguest && $dynamic_clock) || ${$uid.$username}{'dynamic_clock'})) {
		$yytime =~ /(.*?)\d+:\d+((\w+)|:\d+)?/;
		my ($a,$b) = ($1,$3);
		$a =~ s/<.+?>//g;
		$b = ' ' if $mytimeselected == 6;
		$yytime = qq~&nbsp;<script language="javascript" type="text/javascript">\n<!--\nWriteClock('yabbclock','$a','$b');\n//-->\n</script>~;
		$yyjavascript .= qq~\n\nvar OurTime = ~ . ($date + (3600 * $toffs)) . qq~000;\nvar YaBBTime = new Date();\nvar TimeDif = YaBBTime.getTime() - (YaBBTime.getTimezoneOffset() * 60000) - OurTime - 1000; // - 1000 compromise to transmission time~;
	}

	$yyjavascript .= qq~

	function txtInFields(thefield, defaulttxt) {
		if (thefield.value == defaulttxt) thefield.value = "";
		else { if (thefield.value == "") thefield.value = defaulttxt; }
	}
	~;
	if ($output =~ /\{yabb tabmenu\}/) {
		require "$sourcedir/TabMenu.pl";
		&mainMenu;

	} else {
		$yymenu = qq~<a href="$scripturl">$img{'home'}</a>$menusep<a href="$scripturl?action=help" style="cursor:help;">$img{'help'}</a>~;
		# remove search from menu if disabled by the admin
		if ($maxsearchdisplay > -1) {
			$yymenu .= qq~$menusep<a href="$scripturl?action=search">$img{'search'}</a>~;
		}
		if (!$ML_Allowed || ($ML_Allowed == 1 && !$iamguest) || ($ML_Allowed == 2 && $staff) || ($ML_Allowed == 3 && ($iamadmin || $iamgmod))) {
			$yymenu .= qq~$menusep<a href="$scripturl?action=ml">$img{'memberlist'}</a>~;
		}

		if ($iamadmin) { $yymenu .= qq~$menusep<a href="$boardurl/AdminIndex.$yyaext">$img{'admin'}</a>~; }
		if ($iamgmod) {
			if (-e ("$vardir/gmodsettings.txt")) {
				require "$vardir/gmodsettings.txt";
			}
			if ($allow_gmod_admin) { $yymenu .= qq~$menusep<a href="$boardurl/AdminIndex.$yyaext">$img{'admin'}</a>~; }
		}
		if ($sessionvalid == 0 && !$iamguest) {
			my $sesredir;
			unless (!$testenv || $action eq "revalidatesession" || $action eq "revalidatesession2") {
				$sesredir = $testenv;
				$sesredir =~ s/\=/\~/g;
				$sesredir =~ s/;/x3B/g;
				$sesredir = qq~;sesredir=$sesredir~;
			}
			$yymenu .= qq~$menusep<a href="$scripturl?action=revalidatesession$sesredir">$img{'sessreval'}</a>~;
		}
		if ($iamguest) {
			my $sesredir;
			if ($testenv) {
				$sesredir = $testenv;
				$sesredir =~ s/\=/\~/g;
				$sesredir =~ s/;/x3B/g;
				$sesredir = qq~;sesredir=$sesredir~;
			}
			$yymenu .= qq~$menusep<a href="~ . ($loginform ? "javascript:if(jumptologin>1)alert('$maintxt{'35'}');jumptologin++;window.scrollTo(0,10000);document.loginform.username.focus();" : "$scripturl?action=login$sesredir") . qq~">$img{'login'}</a>~;
			if ($regtype != 0) { $yymenu .= qq~$menusep<a href="$scripturl?action=register">$img{'register'}</a>~; }
			if ($PMenableGuestButton && $PM_level > 0 && $PMenableBm_level > 0) {
				$yymenu .= qq~$menusep<a href="$scripturl?action=guestpm">$img{'pmadmin'}</a>~; }

		} else {
			## pointing towards pm now
			$yymenu .= qq~$menusep<a href="$scripturl?action=mycenter">$img{'mycenter'}</a>~;
			$yymenu .= qq~$menusep<a href="$scripturl?action=logout">$img{'logout'}</a>~;
		}
	}

	$yylangChooser = "";
	if (($iamguest && !$guestLang) && $enable_guestlanguage && $guestaccess) {
		if (!$langopt) {&guestLangSel;}
		if ($morelang > 1) {
			$yylangChooser = qq~$guest_txt{'sellanguage'}: <form action="$scripturl?action=guestlang" method="post" name="sellanguage">
			<select name="guestlang" onchange="submit();">
			$langopt
			</select>
			<noscript><input type="submit" value="$maintxt{'32'}" class="button" /></noscript>
			</form>~;
		}

	} elsif (($iamguest && $guestLang) && $enable_guestlanguage && $guestaccess) {
		if (!$langopt) {&guestLangSel;}
		if ($morelang > 1) {
			$yylangChooser = qq~$guest_txt{'changelanguage'}: <form action="$scripturl?action=guestlang" method="post" name="changelanguage">
			<select name="guestlang" onchange="submit();">
			$langopt
			</select>
			<noscript><input type="submit" value="$maintxt{'32'}" class="button" /></noscript>
			</form>~;
		}
	}

	my $wmessage;
	if    ($hour >= 12 && $hour < 18) { $wmessage = $maintxt{'247a'}; } # Afternoon
	elsif ($hour <  12 && $hour >= 0) { $wmessage = $maintxt{'247m'}; } # Morning
	else                              { $wmessage = $maintxt{'247e'}; } # Evening 
	if ($iamguest) {
		$yyuname = qq~$maintxt{'248'} $maintxt{'28'}. $maintxt{'249'} <a href="~ . ($loginform ? "javascript:if(jumptologin>1)alert('$maintxt{'35'}');jumptologin++;window.scrollTo(0,10000);document.loginform.username.focus();" : "$scripturl?action=login") . qq~">$maintxt{'34'}</a>~;
		$yyuname .= qq~ $maintxt{'377'} <a href="$scripturl?action=register">$maintxt{'97'}</a>~ if $regtype;
		$yyjavascript .= "\njumptologin = 1;";
	} else {
		if (${$uid.$username}{'bday'} ne '') {
			my ($usermonth, $userday, $useryear) = split(/\//, ${$uid.$username}{'bday'});
			if ($usermonth == $mon_num && $userday == $mday) { $wmessage = $maintxt{'247bday'}; }
		}
		$yyuname = ($PM_level == 0 || ($PM_level == 2 && !$iamadmin && !$iamgmod && !$iammod) || ($PM_level == 3 && !$iamadmin && !$iamgmod)) ? "$wmessage ${$uid.$username}{'realname'}" : "$wmessage ${$uid.$username}{'realname'}, ";
	}

	# Add new notifications if allowed
	if (!$iamguest && $NewNotificationAlert) {
		unless ($board_notify || $thread_notify) {
			require "$sourcedir/Notify.pl";
			($board_notify,$thread_notify) = &NotificationAlert;
		}
		my ($bo_num,$th_num);
		foreach (keys %$board_notify) { # boardname, boardnotifytype , new
			$bo_num++ if ${$$board_notify{$_}}[2];
		}
		foreach (keys %$thread_notify) { # mythread, msub, new, username_link, catname_link, boardname_link, lastpostdate
			$th_num++ if ${$$thread_notify{$_}}[2];
		}
		if ($bo_num || $th_num) {
			my $noti_text = ($bo_num ? "$notify_txt{'201'} $notify_txt{'205'} ($bo_num)" : "") . ($th_num ? ($bo_num ? " $notify_txt{'202'} " : "") . "$notify_txt{'201'}  $notify_txt{'206'} ($th_num)" : "");
			$yyadmin_alert = qq~<br />$notify_txt{'200'} <a href="$scripturl?action=shownotify">$noti_text</a>.$yyadmin_alert~;
			$yymain .= qq~<script language="javascript" type="text/javascript">
			<!--
			window.setTimeout("Noti_Popup();", 1000);
			function Noti_Popup() {
				if (confirm('$notify_txt{'200'} $noti_text.\\n$notify_txt{'203'}'))
					window.location.href='$scripturl?action=shownotify';
			}
			//-->
			</script>~ if ${$uid.$username}{'onlinealert'} and $boardindex_template;
		}
	}

	# This next line fixes problems created when a fatal_error is called before Security.pl is loaded
	# We don't want to require since it's an error and trying to do anything extra for an error could be bad
	if ($output =~ m~<yabb copyright>~ || $output =~ m~{yabb copyright}~) { $yycopyin = 1; } ## new template style in also
	$yysearchbox = '';
	unless ($iamguest && $guestaccess == 0) {
		if ($maxsearchdisplay > -1) {
			$yysearchbox = qq~
		<script language="JavaScript1.2" src="$yyhtml_root/ubbc.js" type="text/javascript"></script>
		<form action="$scripturl?action=search2" method="post">
		<input type="hidden" name="searchtype" value="allwords" />
		<input type="hidden" name="userkind" value="any" />
		<input type="hidden" name="subfield" value="on" />
		<input type="hidden" name="msgfield" value="on" />
		<input type="hidden" name="age" value="31" />
		<input type="hidden" name="numberreturned" value="$maxsearchdisplay" />
		<input type="hidden" name="oneperthread" value="1" />
		<input type="hidden" name="searchboards" value="!all" />
		<input type="text" name="search" size="16" id="search1" value="$img_txt{'182'}" style="font-size: 11px;" onfocus="txtInFields(this, '$img_txt{'182'}');" onblur="txtInFields(this, '$img_txt{'182'}')" />
		<input type="image" src="$imagesdir/search.gif" style="border: 0; background-color: transparent; margin-right: 5px; vertical-align: middle;" />
		</form>
		~;
		}
	}
	if ($enable_news && -s "$vardir/news.txt" > 5) {
		fopen(NEWS, "$vardir/news.txt");
		my @newsmessages = <NEWS>;
		fclose(NEWS);
		chomp(@newsmessages);
		my $startnews = int(rand(@newsmessages));
		my $newstitle = qq~<b>$maintxt{'102'}:</b>~;
		$newstitle =~ s/'/\\'/g;
		$guest_media_disallowed = 0;
		$newswrap = 40;
		if ($shownewsfader) {
			$fadedelay = $maxsteps * $stepdelay;
			$yynews .= qq~
			<script language="JavaScript1.2" type="text/javascript">
				<!--
					var index = $startnews;
					var maxsteps = "$maxsteps";
					var stepdelay = "$stepdelay";
					var fadelinks = $fadelinks;
					var delay = "$fadedelay";
					function convProp(thecolor) {
						if(thecolor.charAt(0) == "#") {
							if(thecolor.length == 4) thecolor=thecolor.replace(/(\\#)([a-f A-F 0-10]{1,1})([a-f A-F 0-10]{1,1})([a-f A-F 0-10]{1,1})\/i, "\$1\$2\$2\$3\$3\$4\$4");
							var thiscolor = new Array(HexToR(thecolor), HexToG(thecolor), HexToB(thecolor));
							return thiscolor;
						}
						else if(thecolor.charAt(3) == "(") {
							thecolor=thecolor.replace(/rgb\\((\\d+?\\%*?)\\,(\\s*?)(\\d+?\\%*?)\\,(\\s*?)(\\d+?\\%*?)\\)/i, "\$1|\$3|\$5");
							var thiscolor = thecolor.split("|");
							return thiscolor;
						}
						else {
							thecolor=thecolor.replace(/\\"/g, "");
							thecolor=thecolor.replace(/maroon/ig, "128|0|0");
							thecolor=thecolor.replace(/red/i, "255|0|0");
							thecolor=thecolor.replace(/orange/i, "255|165|0");
							thecolor=thecolor.replace(/olive/i, "128|128|0");
							thecolor=thecolor.replace(/yellow/i, "255|255|0");
							thecolor=thecolor.replace(/purple/i, "128|0|128");
							thecolor=thecolor.replace(/fuchsia/i, "255|0|255");
							thecolor=thecolor.replace(/white/i, "255|255|255");
							thecolor=thecolor.replace(/lime/i, "00|255|00");
							thecolor=thecolor.replace(/green/i, "0|128|0");
							thecolor=thecolor.replace(/navy/i, "0|0|128");
							thecolor=thecolor.replace(/blue/i, "0|0|255");
							thecolor=thecolor.replace(/aqua/i, "0|255|255");
							thecolor=thecolor.replace(/teal/i, "0|128|128");
							thecolor=thecolor.replace(/black/i, "0|0|0");
							thecolor=thecolor.replace(/silver/i, "192|192|192");
							thecolor=thecolor.replace(/gray/i, "128|128|128");
							var thiscolor = thecolor.split("|");
							return thiscolor;
						}
					}

					if (ie4 || DOM2) document.write('$newstitle<div class="windowbg2" id="fadestylebak" style="display: none;"><div class="newsfader" id="fadestyle" style="display: none;"> </div></div>');

					if (document.getElementById('fadestyle').currentStyle) {
						tcolor = document.getElementById('fadestyle').currentStyle['color'];
						bcolor = document.getElementById('fadestyle').currentStyle['backgroundColor'];
						fntsize = document.getElementById('fadestyle').currentStyle['fontSize'];
						fntstyle = document.getElementById('fadestyle').currentStyle['fontStyle'];
						fntweight = document.getElementById('fadestyle').currentStyle['fontWeight'];
						fntfamily = document.getElementById('fadestyle').currentStyle['fontFamily'];
						txtdecoration = document.getElementById('fadestyle').currentStyle['textDecoration'];
					}
					else if (window.getComputedStyle) {
						tcolor = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('color');
						bcolor = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('background-color');
						fntsize = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-size');
						fntstyle = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-style');
						fntweight = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-weight');
						fntfamily = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-family');
						txtdecoration = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('text-decoration');
					}
					if (bcolor == "transparent" || bcolor == "rgba\\(0\\, 0\\, 0\\, 0\\)") {
						if (document.getElementById('fadestylebak').currentStyle) {
							tcolor = document.getElementById('fadestylebak').currentStyle['color'];
							bcolor = document.getElementById('fadestylebak').currentStyle['backgroundColor'];
						}
						else if (window.getComputedStyle) {
							tcolor = window.getComputedStyle(document.getElementById('fadestylebak'), null).getPropertyValue('color');
							bcolor = window.getComputedStyle(document.getElementById('fadestylebak'), null).getPropertyValue('background-color');
						}
					}
					txtdecoration = txtdecoration.replace(/\'/g, "");
					var endcolor = convProp(tcolor);
					var startcolor = convProp(bcolor);~;
			my $greybox = $img_greybox;
			$img_greybox = 0;
			for (my $j = 0; $j < @newsmessages; $j++) {
				$message = $newsmessages[$j];
				&wrap;
				if ($enable_ubbc) {
					if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
					&DoUBBC;
					$message =~ s/ style="display:none"/ style="display:block"/g;
				}
				&wrap2;
				$message =~ s/"/\\"/g;
				&ToChars($message);
				$yynews .= qq~					fcontent[$j] = "$message";\n~;
			}
			$img_greybox = $greybox;
			$yynews .= qq~
					if (ie4 || DOM2) document.write('<div style="font-size: ' + fntsize + '\\; font-weight: ' + fntweight + '\\; font-style: ' + fntstyle + '\\; font-family: ' + fntfamily + '\\; text-decoration: ' + txtdecoration + '\\;" id="fscroller"></div>');

					if (window.addEventListener)
						window.addEventListener("load", changecontent, false);
					else if (window.attachEvent)
						window.attachEvent("onload", changecontent);
					else if (document.getElementById)
						window.onload = changecontent;
				// -->
			</script>
		~;
		} else {
			$message = $newsmessages[$startnews];
			&wrap;
			if ($enable_ubbc) {
				if (!$yyYaBBCloaded) { require "$sourcedir/YaBBC.pl"; }
				&DoUBBC;
				$message =~ s/ style="display:none"/ style="display:block"/g;
			}
			&wrap2;
			&ToChars($message);
			$yynews = $message;
		}
		$newswrap = 0;
	} else {
		$yynews = '&nbsp;';
	}
	# Moved this down here so it shows more
	##  pushed to own file for flexibility
	if ($debug == 1 or ($debug == 2 && $iamadmin)) { require "$sourcedir/Debug.pl"; &Debug; }
	$yyurl      = $scripturl;
	## new and old tag template style decoding ##
	while ($output =~ s~(<|{)yabb\s+(\w+)(}|>)~${"yy$2"}~g) {}
	$output =~ s~(a href=\S+?action=viewprofile;username=.+?)>~$1 rel="nofollow">~isg;
	if ($imagesdir ne $defaultimagesdir) {
		$output =~ s~img src=(\\*"|')$imagesdir/(.+?)(\1)~ "img src=$1" . &ImgLoc($2) . $3 ~eisg;
		$output =~ s~\.src='$imagesdir/(.+?)'~ ".src='" . &ImgLoc($1) . "'" ~eisg; # For Javascript generated images
		$output =~ s~input type="image" src="$imagesdir/(.+?)"~ 'input type="image" src="' . &ImgLoc($1) . '"' ~eisg; # For input images
		$output =~ s~option value="$imagesdir/(.+?)"~ 'option value="' . &ImgLoc($1) . '"' ~eisg; # For the post page
	}
	$output =~ s~</form>~<input type="hidden" name="formsession" value="$formsession" /></form>~g;

	&image_resize;

	# Start workaround to substitute all ';' by '&' in all URLs
	# This workaround solves problems with servers that use mod_security
	# in a very strict way. (error 406)
	# Take the comments out of the following two lines if you had this problem.
	# $output =~ s/($scripturl\?)([^'"]+)/ $1 . &URL_modify($2) /eg;
	# sub URL_modify { my $x = shift; $x =~ s/;/&/g; $x; }
	# End of workaround

	if ($yycopyin == 0) {
		$output = q~<center><h1><b>Sorry, the copyright tag <yabb copyright> must be in the template.<br />Please notify this forum's administrator that this site is using an ILLEGAL copy of YaBB!</b></h1></center>~;
	}

	&print_HTML_output_and_finish;
}

sub image_resize {
	my ($resize_js,$resize_num);
	my $perl_do_it = 0; # Hardcoded! Set to 1 for Perl to do the fix...size work here. Set to 0 for the javascript within the browser do this work.
	$output =~ s/"((avatar|post|attach|signat)_img_resize)"([^>]*>)/ &check_image_resize($1,$2,$3) /ge;

	sub check_image_resize {
		my @x = @_;
		if ($fix_avatar_img_size && $perl_do_it == 1 && $x[1] eq 'avatar') {
			if ($max_avatar_width  && $x[2] !~ / width=./)  { $x[2] =~ s/( style=.)/$1width:$max_avatar_width\px;/; }
			if ($max_avatar_height && $x[2] !~ / height=./) { $x[2] =~ s/( style=.)/$1height:$max_avatar_height\px;/; }
			$x[2] =~ s/display:none/display:inline/;
		} elsif ($fix_post_img_size && $perl_do_it == 1 && $x[1] eq 'post') {
			if ($max_post_width  && $x[2] !~ / width=./)  { $x[2] =~ s/( style=.)/$1width:$max_post_width\px;/; }
			if ($max_post_height && $x[2] !~ / height=./) { $x[2] =~ s/( style=.)/$1height:$max_post_height\px;/; }
			$x[2] =~ s/display:none/display:inline/;
		} elsif ($fix_attach_img_size && $perl_do_it == 1 && $x[1] eq 'attach') {
			if ($max_attach_width  && $x[2] !~ / width=./)  { $x[2] =~ s/( style=.)/$1width:$max_attach_width\px;/; }
			if ($max_attach_height && $x[2] !~ / height=./) { $x[2] =~ s/( style=.)/$1height:$max_attach_height\px;/; }
			$x[2] =~ s/display:none/display:inline/;
		} elsif ($fix_signat_img_size && $perl_do_it == 1 && $x[1] eq 'signat') {
			if ($max_signat_width  && $x[2] !~ / width=./)  { $x[2] =~ s/( style=.)/$1width:$max_signat_width\px;/; }
			if ($max_signat_height && $x[2] !~ / height=./) { $x[2] =~ s/( style=.)/$1height:$max_signat_height\px;/; }
			$x[2] =~ s/display:none/display:inline/;
		} else {
			$resize_num++;
			$x[0] .= "_$resize_num"; 
			$resize_js .= "'$x[0]',";
		}
		qq~"$x[0]"$x[2]~;
	}

	if ($resize_num) {
		$resize_js =~ s/,$//;
		$resize_js = qq~<script language="JavaScript1.2" type="text/javascript">
<!--
	// resize image start
	var resize_time = 2;
	var img_resize_names = new Array ($resize_js);

	var avatar_img_w    = $max_avatar_width;
	var avatar_img_h    = $max_avatar_height;
	var fix_avatar_size = $fix_avatar_img_size;
	var post_img_w      = $max_post_img_width;
	var post_img_h      = $max_post_img_height;
	var fix_post_size   = $fix_post_img_size;
	var attach_img_w    = $max_attach_img_width;
	var attach_img_h    = $max_attach_img_height;
	var fix_attach_size = $fix_attach_img_size;
	var signat_img_w    = $max_signat_img_width;
	var signat_img_h    = $max_signat_img_height;
	var fix_signat_size = $fix_signat_img_size;

	noimgdir   = '$imagesdir';
	noimgtitle = '$maintxt{'171'}';

	resize_images();
	// resize image end
// -->
</script>~;

		$output =~ s|(</body>)|$resize_js\n$1|;
	}
}

sub fatal_error_logging {
	my $tmperror = $_[0];

	# This flaw was brought to our attention by S M <savy91@msn.com> Italy
	# Thanks! We couldn't make YaBB successful without the help from the bug testers.
	&ToHTML($action);
	&ToHTML($INFO{'num'});
	&ToHTML($currentboard);

	$tmperror =~ s/\n//ig;
	fopen(ERRORLOG, "+<$vardir/errorlog.txt");
	seek ERRORLOG, 0, 0;
	my @errorlog = <ERRORLOG>;
	truncate ERRORLOG, 0;
	seek ERRORLOG, 0, 0;
	chomp @errorlog;
	$errorcount = @errorlog;

	if ($elrotate) {
		while ($errorcount >= $elmax) {
			shift @errorlog;
			$errorcount = @errorlog;
		}
	}

	foreach my $formdata (keys %FORM) {
		chomp $FORM{$formdata};
		$FORM{$formdata} =~ s/\n//ig;
	}

	if ($iamguest) {
		push @errorlog, int(time()) . "|$date|$user_ip|$tmperror|$action|$INFO{'num'}|$currentboard|$FORM{'username'}|$FORM{'passwrd'}";
	} else {
		push @errorlog, int(time()) . "|$date|$user_ip|$tmperror|$action|$INFO{'num'}|$currentboard|$username|$FORM{'passwrd'}";
	}
	foreach (@errorlog) {
		chomp;
		if ($_ ne "") {
			print ERRORLOG $_ . "\n";
		}
	}
	fclose(ERRORLOG);
}

sub fatal_error {
	my $verbose = $!;

	&LoadLanguage('Error');
	my $errormessage = "$error_txt{$_[0]} $_[1]";

	# Gets filename and line where fatal_error was called.
	# Need to go further back to get correct subroutine name,
	# otherwise will print fatal_error as current subroutine!
	(undef, $e_filename, $e_line) = caller(0);
	(undef, undef, undef, $e_subroutine) = caller(1);
	(undef, $e_subroutine) = split(/::/, $e_subroutine);
	if (($debug == 1 || ($debug == 2 && $iamadmin)) && ($e_filename || $e_line || $e_subroutine)) { $errormessage .= "<br />$maintxt{'error_location'}: $e_filename<br />$maintxt{'error_line'}: $e_line<br />$maintxt{'error_subroutine'}: $e_subroutine"; }

	if ($_[2]) { $errormessage .= "<br />$maintxt{'error_verbose'}: $verbose"; }

	if ($elenable) { &fatal_error_logging($errormessage); }

	if ($_[0] =~ /no_access|members_only|no_perm/) {
		$headerstatus = "403 Forbidden";
	} elsif ($_[0] =~ /cannot_open|no.+_found/) {
		$headerstatus = "404 Not Found";
	}

	$yymain .= qq~
<table border="0" width="80%" cellspacing="1" class="bordercolor" align="center" cellpadding="4">
	<tr>
		<td class="titlebg"><span class="text1"><b>$maintxt{'error_description'}</b></span></td>
	</tr><tr>
		<td class="windowbg"><br /><span class="text1">$errormessage</span><br /><br /></td>
	</tr>
</table>
<center><br /><a href="javascript:history.go(-1)">$maintxt{'193'}</a></center>
~;

	$yytitle = "$maintxt{'error_description'}";
	&template;
}

sub admin_fatal_error {
	my $verbose = $!;

	&LoadLanguage('Error');
	my $errormessage = "$error_txt{$_[0]} $_[1]";

	# Gets filename and line where fatal_error was called.
	# Need to go further back to get correct subroutine name,
	# otherwise will print fatal_error as current subroutine!
	(undef, $e_filename, $e_line) = caller(0);
	(undef, undef, undef, $e_subroutine) = caller(1);
	(undef, $e_subroutine) = split(/::/, $e_subroutine);
	if (($debug == 1 || ($debug == 2 && $iamadmin)) && ($e_filename || $e_line || $e_subroutine)) { $errormessage .= "<br />$maintxt{'error_location'}: $e_filename<br />$maintxt{'error_line'}: $e_line<br />$maintxt{'error_subroutine'}: $e_subroutine"; }

	if ($_[2]) { $errormessage .= "<br />$maintxt{'error_verbose'}: $verbose"; }

	if ($elenable) { &fatal_error_logging($errormessage); }

	$yymain .= qq~
<table border="0" width="80%" cellspacing="1" class="bordercolor" align="center" cellpadding="4">
	<tr>
		<td class="titlebg"><span class="text1"><b>$maintxt{'error_description'}</b></span></td>
	</tr><tr>
		<td class="windowbg"><br /><span class="text1">$errormessage</span><br /><br /></td>
	</tr>
</table>
<center><br /><a href="javascript:history.go(-1)">$admin_txt{'193'}</a></center>
~;

	$yytitle = "$maintxt{'error_description'}";
	&AdminTemplate;
}

sub FindPermalink {
	$old_env = $_[0];
	$old_env = substr($old_env,1, length($old_env));
	$permtopicfound = 0;
	$permboardfound = 0;
	$is_perm = 1;
	## strip off symlink for redirectlike e.g. /articles/ ##
	$old_env =~ s~$symlink~~g;
	## get date/time/board/topic from permalink

	($permyear, $permmonth, $permday, $permboard, $permnum) = split (/\//, $old_env);
	if(-e "$boardsdir/$permboard.txt") {
		$permboardfound = 1;
		if($permnum ne "" && -e "$datadir/$permnum.txt") {
			$new_env = qq~num=$permnum~;
			$permtopicfound = 1;
		} else { $new_env = qq~board=$permboard~; }
	}
	return $new_env;
}

sub permtimer {
	my $thetime = $_[0];
	my (undef, $pmin, $phour, $pmday, $pmon, $pyear, undef, undef, undef) = gmtime($thetime + (3600 * $timeoffset));
	my $pmon_num = $pmon + 1;
	$phour = sprintf("%02d", $phour);
	$pmin = sprintf("%02d", $pmin);
	$pyear = 1900 + $pyear;
	$pmon_num = sprintf("%02d", $pmon_num);
	$pmday = sprintf("%02d", $pmday);
	$pyear = sprintf("%04d", $pyear);
	return "$pyear/$pmon_num/$pmday";
}

sub readform {
	my (@pairs, $pair, $name, $value);
	if (substr($ENV{QUERY_STRING},0,1) eq "/" && $accept_permalink) { $ENV{QUERY_STRING} = &FindPermalink($ENV{QUERY_STRING}); }
	if ($ENV{QUERY_STRING} =~ m/action\=dereferer/) {
		$INFO{'action'} = "dereferer";
		$urlstart = index($ENV{QUERY_STRING}, "url=");
		$INFO{'url'} = substr($ENV{QUERY_STRING}, $urlstart + 4, length($ENV{QUERY_STRING}) - $urlstart + 3);
		$INFO{'url'} =~ s/\;anch\=/#/g;
		$testenv = "";
	} else {
		$testenv = $ENV{QUERY_STRING};
		$testenv =~ s/\&/\;/g;
		if ($testenv && $debug) { $getpairs = qq~<br /><u>$debug_txt{'getpairs'}:</u><br />~; }
	}
	# URL encoding for web.de http://www.blooberry.com/indexdot/html/topics/urlencoding.htm
	$testenv =~ s/\%3B/;/ig; # search must be case insensitiv for some servers!
	$testenv =~ s/\%26/&/g;

	&split_string(\$testenv, \%INFO, 1);
	if ($ENV{'SERVER_SOFTWARE'} =~ /IIS/) {
		($dummy,$IISver) = split( '\/', $ENV{'SERVER_SOFTWARE'});
		($IISver,$IISverM) = split( '.',$IISver);
		if (int($IISver) < 6 && int($IISverM) < 1) { eval 'use CGI qw(:standard)'; }
	}
	if ($ENV{REQUEST_METHOD} eq 'POST') {
		if ($debug) { $getpairs .= qq~<br /><u>$debug_txt{'postpairs'}:</u><br />~; }
		if ($ENV{CONTENT_TYPE} =~ /multipart\/form-data/) {
			require CGI;
			# A possible attack is for the remote user to force CGI.pm to accept
			# a huge file upload. CGI.pm will accept the upload and store it in
			# a temporary directory even if your script doesn't expect to receive
			# an uploaded file. CGI.pm will delete the file automatically when it
			# terminates, but in the meantime the remote user may have filled up
			# the server's disk space, causing problems for other programs.
			# The best way to avoid denial of service attacks is to limit the
			# amount of memory, CPU time and disk space that CGI scripts can use.
			# If $CGI::POST_MAX is set to a non-negative integer, this variable
			# puts a ceiling on the size of POSTings, in bytes. If CGI.pm detects
			# a POST that is greater than the ceiling, it will immediately exit
			# with an error message like this:
			# "413 Request entity too large"
			# This value will affect both ordinary POSTs and multipart POSTs,
			# meaning that it limits the maximum size of file uploads as well.
			if ($allowattach && $ENV{'QUERY_STRING'} =~ /action=(post|modify)2\b/) {
				$CGI::POST_MAX = int(1024 * $limit * $allowattach);
				$CGI::POST_MAX += 1000000 if $CGI::POST_MAX; # *
			} elsif ($upload_useravatar && $ENV{'QUERY_STRING'} =~ /action=profileOptions2\b/) {
				$CGI::POST_MAX = int(1024 * $avatar_limit);
				$CGI::POST_MAX += 1000000 if $CGI::POST_MAX; # *
			} else {
				# If NO uploads are allowed YaBB sets this default limit
				# to 1 MB. Change this values if you get error messages.
				$CGI::POST_MAX = 1000000;
			}
			# * adds volume, if a upload limit is set, to not get error if the other
			# uploaded data is larger. Change this values if you get error messages.
			$CGI_query = new CGI; # $CGI_query must be a global variable
			my ($name, @value);
			foreach $name ($CGI_query->param()) {
				next if $name =~ /^file(\d+|_avatar)$/; # files are directly called in Profile.pl, Post.pl and ModifyMessages.pl
				@value = $CGI_query->param($name);
				if ($debug) { $getpairs .= qq~[$debug_txt{'name'}-&gt;]$name=@value\[&lt;-$debug_txt{'value'}]<br />~; }
				$FORM{$name} = join(', ', @value); # multiple values are joined
			}
		} else {
			read(STDIN, my $input, $ENV{CONTENT_LENGTH});
			&split_string(\$input, \%FORM);
		}
	}
	$action = $INFO{'action'} || $FORM{'action'};
	# Formsession checking moved to YaBB.pl to fix a bug.
	if ($INFO{'username'} && $do_scramble_id) { $INFO{'username'} = &decloak($INFO{'username'}); }
	if ($FORM{'username'} && $do_scramble_id && $action ne "login2" && $action ne "reminder2" && $action ne "register2" && $action ne "profile2") { $FORM{'username'} = &decloak($FORM{'username'}); }
	if ($INFO{'to'} && $do_scramble_id) { $INFO{'to'} = &decloak($INFO{'to'}); }
	if ($FORM{'to'} && $do_scramble_id) { $FORM{'to'} = &decloak($FORM{'to'}); }

	# Dont do this here or you get problems with foreign characters!!!!
	#if ($action eq 'search2') { &FromHTML($FORM{'search'}); }
	#&ToHTML($INFO{'title'});
	#&ToHTML($FORM{'title'});
	#&ToHTML($INFO{'subject'});
	#&ToHTML($FORM{'subject'});

	sub split_string {
		my ($string, $hash, $altdelim) = @_;

		if ($altdelim && $$string =~ m~;~) { @pairs = split(/;/, $$string); }
		else { @pairs = split(/&/, $$string); }
		foreach $pair (@pairs) {
			my ($name, $value) = split(/=/, $pair);
			$name  =~ tr/+/ /;
			$name  =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			$value =~ tr/+/ /;
			$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			if ($debug) { $getpairs .= qq~[$debug_txt{'name'}-&gt;]$name=$value\[&lt;-$debug_txt{'value'}]<br />~; }
			if (exists($hash->{$name})) {
				$hash->{$name} .= ", $value";
			} else {
				$hash->{$name} = $value;
			}
		}
	}
}

sub getlog {
	return if defined %yyuserlog || $iamguest || !$max_log_days_old || !-e "$memberdir/$username.log";

	%yyuserlog = ();
	fopen(GETLOG, "$memberdir/$username.log");
	my @logentries = <GETLOG>;
	fclose(GETLOG);
	chomp(@logentries);

	my ($name,$thistime);
	foreach (@logentries) {
		($name,$thistime) = split(/\|/, $_);
		if ($name && $thistime) { $yyuserlog{$name} = $thistime; }
	}
}

sub dumplog {
	return if $iamguest || !$max_log_days_old;

	if ($_[0]) {
		&getlog;
		$yyuserlog{$_[0]} = $_[1] || $date;
	}
	if (defined %yyuserlog) {
		my $name;
		$date2 = $date;
		fopen(DUMPLOG, ">$memberdir/$username.log");
		while (($name,$date1) = each(%yyuserlog)) {
			&calcdifference; # output => $result
			if ($result <= $max_log_days_old) {
				print DUMPLOG qq~$name|$date1\n~;
			}
		}
		fclose(DUMPLOG);
	}
}

## standard jump to menu
sub jumpto {
	my (@masterdata, $category, @data, $found, $tmp, @memgroups, @newcatdata, $boardname);
	## jump links to messages/favourites/notifications.
	my $action = 'action=jump';
	my $onchange = qq~ onchange="if(this.options[this.selectedIndex].value) window.location.href='$scripturl?' + this.options[this.selectedIndex].value;"~;
	if ($templatejump == 1) { 
		$action = 'action=';
		$onchange = '';
	}
	$selecthtml = qq~
<form method="post" action="$scripturl?$action" name="jump" style="display: inline;">
<select name="values"$onchange>
	<option value="" class="forumjump">$jumpto_txt{'to'}</option>\n
	<option value="gohome">$img_txt{'103'}</option>\n~;

	## as guests don't have these, why show them?
	if (!$iamguest) {
		$selecthtml .= qq~
	<option value="action=im" class="forumjumpcatm">$jumpto_txt{'mess'}</option>~ if $PM_level == 1 || ($PM_level == 2 && ($iamadmin || $iamgmod || $iammod)) || ($PM_level == 3 && ($iamadmin || $iamgmod));
		$selecthtml .= qq~
	<option value="action=shownotify" class="forumjumpcatmf">$jumpto_txt{'note'}</option>
	<option value="action=favorites" class="forumjumpcatm">$jumpto_txt{'fav'}</option>~;
	}

	# drop in recent topics/posts lists. guests can see if browsing permitted
	$selecthtml .= qq~
	<option value="action=recent;display=10">$recent_txt{'recentposts'}</option>
	<option value="action=recenttopics;display=10">$recent_txt{'recenttopic'}</option>\n~;

	unless ($mloaded == 1) { require "$boardsdir/forum.master"; }
	foreach $catid (@categoryorder) {
		@bdlist = split(/,/, $cat{$catid});
		($catname, $catperms) = split(/\|/, $catinfo{"$catid"});

		$cataccess = &CatAccess($catperms);
		if (!$cataccess) { next; }
		&ToChars($catname);
		## I've removed the dashed bands and css handles the cat highlighting.
		$selecthtml .= $INFO{'catselect'} eq $catid ? qq~	<option selected=\"selected\" value="catselect=$catid" class="forumjumpcat">&raquo;&raquo; $catname</option>\n~ : qq~	<option value="catselect=$catid" class="forumjumpcat">$catname</option>\n~;
		foreach $board (@bdlist) {
			($boardname, $boardperms, $boardview) = split(/\|/, $board{"$board"});
			&ToChars($boardname);
			my $access = &AccessCheck($board, '', $boardperms);
			if (!$iamadmin && $access ne "granted" && $boardview != 1) { next; }
			if ($board eq $annboard && !$iamadmin && !$iamgmod) { next; }

			if ($board eq $currentboard) { $selecthtml .= $INFO{'num'} ? "	<option value=\"board=$board\" class=\"forumcurrentboard\">&nbsp; - $boardname &#171;&#171;</option>\n" : "	<option selected=\"selected\" value=\"board=$board\" class=\"forumcurrentboard\">&raquo;&raquo; $boardname</option>\n"; }
			else { $selecthtml .= "	<option value=\"board=$board\">&nbsp; - $boardname</option>\n"; }
		}
	}
	$selecthtml .= qq~</select>
<noscript><input type="submit" value="$maintxt{'32'}" class="button" /></noscript>
</form>~;
}

sub dojump {
	$yySetLocation = $scripturl . $FORM{'values'};
	&redirectexit;
}

sub spam_protection {
	unless ($timeout) { return; }
	my ($time, $flood_ip, $flood_time, $flood, @floodcontrol);

	if (-e "$vardir/flood.txt") {
		fopen(FLOOD, "$vardir/flood.txt");
		push(@floodcontrol, "$user_ip|$date\n");
		while (<FLOOD>) {
			chomp($_);
			($flood_ip, $flood_time) = split(/\|/, $_);
			if ($user_ip eq $flood_ip && $date - $flood_time <= $timeout) { $flood = 1; }
			elsif ($date - $flood_time < $timeout) { push(@floodcontrol, "$_\n"); }
		}
		fclose(FLOOD);
	}
	if ($flood && !$iamadmin && $action eq 'post2') { &Preview("$maintxt{'409'} $timeout $maintxt{'410'}"); }
	if ($flood && !$iamadmin) {
		&fatal_error("post_flooding","$timeout $maintxt{'410'}");
	}
	fopen(FLOOD, ">$vardir/flood.txt", 1);
	print FLOOD @floodcontrol;
	fclose(FLOOD);
}

sub CountChars {
	$convertstr =~ s/&#32;/ /g; # why? where? (deti)

	$cliped = 0;
	my ($string,$curstring,$stinglength,$teststring);
	foreach $string (split(/\s+/, $convertstr)) {
		CHECKAGAIN:
		# jump over HTML-tags
		if ($curstring =~ /<[\/a-z][^>]*$/i) {
			if ($string =~ /^([^>]*>)(.*)/) {
				$curstring .= $1;
				$convertcut += length($1);
				if ($2) { $string = $2; goto CHECKAGAIN; }
			} else {
				$curstring .= "$string ";
				$convertcut += length($string) + 1;
			}
			next;
		}
		# jump over YaBBC-tags if YaBBC is allowed
		if ($enable_ubbc && $curstring =~ /\[[\/a-z][^\]]*$/i) {
			if ($string =~ /^([^\]]*\])(.*)/) {
				$curstring .= $1;
				$convertcut += length($1);
				if ($2) { $string = $2; goto CHECKAGAIN; }
			} else {
				$curstring .= "$string ";
				$convertcut += length($string) + 1;
			}
			next;
		}
		$stinglength = length($string);
		$teststring = $string;
		# correct length for HTML characters
		&FromHTML($teststring);
		$convertcut += $stinglength - length($teststring);

		# correct length for speciall characters, YaBBC and HTML-Tags
		$teststring = $string;
		$teststring =~ s/\[ch\d{3,}?\]/ /ig;
		$teststring =~ s/<.*?>|\[.*?\]//g;
		$convertcut += $stinglength - length($teststring);

		$curstring .= "$string ";
		$curstring =~ s/ <br $/<br /i;

		if ($curstring =~ /(<[\/a-z][^>]*)$/is) {
			$convertcut += length($1);
		}
		if ($enable_ubbc && $curstring =~ /(\[[\/a-z][^\]]*)$/is) {
			$convertcut += length($1);
		}

		if (length($curstring) > $convertcut) {
			$cliped = 1;
			last;
		}
	}
	if ($curstring =~ /( *<[\/a-z][^>]*)$/i || ($enable_ubbc && $curstring =~ /( *\[[\/a-z][^\]]*)$/i)) {
		$convertcut -= length($1);
	}
	$convertstr = substr($curstring, 0, $convertcut);
	# eliminate spaces, broken HTML-characters or special characters at the end
	$convertstr =~ s/(\[(ch\d*)?|&[a-z]*| +)$//;
}

sub WrapChars {
	my ($tmpwrapstr,$length,$char,$curword,$tmpwrapcut);
	my $wrapcut = $_[1];
	foreach $curword (split(/\s+/, $_[0])) {
		$char    = $curword;
		$length  = 0;
		$curword = '';
		while ($char ne '') {
			if   ( $char =~ s/^(&#?[a-z\d]+;)//i ) { $curword .= $1; }
			else { $char =~ s/^(.)//;                $curword .= $1; }
			$length++;
			if ($length >= $wrapcut) {
				$curword .= "<br />";
				$tmpwrapcut = $length = 0;
			}
		}
		if ($tmpwrapstr && ($tmpwrapcut + $length) >= $wrapcut) {
			$tmpwrapstr .= " $curword<br />";
			$tmpwrapcut  = 0;
		} elsif ($tmpwrapstr) {
			$tmpwrapstr .= " $curword";
			$tmpwrapcut += $length + 1;
		} else {
			$tmpwrapstr = $curword;
			$tmpwrapcut = $length;
		}
	}
	$tmpwrapstr =~ s/(<br \/>)*$/<br \/>/;
	$tmpwrapstr;
}

# Out of: Escape.pm, v 3.28 2004/11/05 13:58:31
# Original Modul at: http://search.cpan.org/~gaas/URI-1.35/URI/Escape.pm
sub uri_escape { # usage: $safe = uri_escape( $string )
	my $text = shift;
	return undef unless defined $text;
	if (!%escapes) {
		# Build a char->hex map
		for (0..255) { $escapes{chr($_)} = sprintf("%%%02X", $_) }
	}
	# Default unsafe characters. RFC 2732 ^(uric - reserved)
	$text =~ s/([^A-Za-z0-9\-_.!~*'()])/ $escapes{$1} || $1 /ge;
	$text;
}

sub enc_eMail {
	my ($title,$email,$subject,$body) = @_;
	my $charset_value = 848 if $yycharset eq "windows-1251"; # Cyrillic decoding

	my $email_length = length($email);
	my $code1 = &generate_code($email_length);
	my $code2;
	for (my $i = 0; $i < $email_length; $i++) {
		$code2 .= chr((ord(substr($code1,$i,1))^ord(substr($email,$i,1))));
	}
	$code2 = &uri_escape($code2);

	my $subbody;
	if ($subject or $body) {
		$subject = &uri_escape($subject);
		$body = &uri_escape($body);
		$subbody = "?subject=$subject&body=$body";
		$subbody =~ s/(((<.+?>)|&#\d+;)|.)/ &enc_eMail_x($1,$2,$3) /eg;
	}

	$title =~ s/(((<.+?>)|&#\d+;)|.)/ &enc_eMail_x($1,$2,$3) /eg;

	return qq*<script type='text/javascript'>\n<!--\nSpamInator("$title","$code1","$code2","&#109;&#97;&#105;&#108;&#92;&#117;&#48;&#48;&#55;&#52;&#111;&#92;&#117;&#48;&#48;&#51;&#97;","$subbody");\n// -->\n</script><noscript>$maintxt{'noscript'}</noscript>*;

	sub enc_eMail_x {
		my ($x,$y,$z) = @_;
		if (!$y) {
			$x = ord($x);
			$x += $charset_value if $charset_value && $x > 126;
			$x = "&#$x";
		} elsif ($z) {
			$x =~ s/"/\\"/g;
		}
		$x;
	}
}

sub generate_code {
	my ($arrey_pos,$code);
	my @arrey = ('a'..'q', 'C'..'O', '1'..'9', 'g'..'u', 'l'..'z', '9'..'1', 'H'..'W');

	for (my $i = 0; $i < $_[0]; $i++) {
		$arrey_pos = int(rand($#arrey));
		$code .= $arrey[$arrey_pos];
	}
	$code;
}

sub FromChars {
	$_[0] =~ s/&#(\d{3,});/ $1>127 ? "[ch$1]" : $& /egis;
}

sub ToChars {
	$_[0] =~ s/\[ch(\d{3,})\]/ $1>127 ? "\&#$1;" : '' /egis;
}

sub ToHTML {
	$_[0] =~ s/&/&amp;/g;
	$_[0] =~ s/\}/\&#125;/g;
	$_[0] =~ s/\{/\&#123;/g;
	$_[0] =~ s/\|/&#124;/g;
	$_[0] =~ s/>/&gt;/g;
	$_[0] =~ s/</&lt;/g;
	$_[0] =~ s/   /&nbsp; &nbsp;/g;
	$_[0] =~ s/  /&nbsp; /g;
	$_[0] =~ s/"/&quot;/g;
}

sub FromHTML {
	$_[0] =~ s/&quot;/"/g;
	$_[0] =~ s/&nbsp;/ /g;
	$_[0] =~ s/&lt;/</g;
	$_[0] =~ s/&gt;/>/g;
	$_[0] =~ s/&#124;/\|/g;
	$_[0] =~ s/&#123;/\{/g;
	$_[0] =~ s/&#125;/\}/g;
	$_[0] =~ s/&amp;/&/g;
}

sub dopre {
	$_ = $_[0];
	$_ =~ s~<br \/>~\n~g;
	$_ =~ s~<br>~\n~g;
	return $_;
}

sub Split_Splice_Move {
	my $s_s_m = $_[0];
	my $ssm = 0;
	if (!$_[1]) { # Just for the subject of a message
		$s_s_m =~ s/^(Re: )?\[m.*?\]/$maintxt{'758'}/;
		return $s_s_m;
	} elsif ($s_s_m =~ /\[m by=(.+?) destboard=(.+?) dest=(.+?)\]/) { # 'This Topic has been moved to' a different board
		my ($mover, $destboard, $dest) = ($1, $2, $3); # Who moved the topic; destination board; destination id number
		$mover = &decloak($mover);
		&LoadUser($mover);
		$board{$destboard} =~ /^(.+?)\|/;
		return (qq~<b>$maintxt{'160'} <a href="$scripturl?num=$dest"><b>$maintxt{'160a'}</b></a> $maintxt{'160b'}</b> <a href="$scripturl?board=$destboard"><i><b>$1</b></i></a><b> $maintxt{'525'} <i>${$uid.$mover}{'realname'}</i></b>~,$dest);

	} elsif ($s_s_m =~ /\[m by=(.+?) dest=(.+?)\]/) { # 'The contents of this Topic have been moved to''this Topic'
		my($mover, $dest) = ($1, $2); # Who moved the topic; destination id number
		$mover = &decloak($mover);
		&LoadUser($mover);
		return (qq~<b>$maintxt{'160c'}</b> <a href="$scripturl?num=$dest"><i><b>$maintxt{'160d'}</b></i></a><b> $maintxt{'525'} <i>${$uid.$mover}{'realname'}</i></b>~,$dest);

	} elsif ($s_s_m =~ /^\[m\]/) { # Old style topic that was moved/spliced before this code
		fopen(MOVEDFILE, "$datadir/$_[1].txt");
		(undef, undef, undef, undef, undef, undef, undef, undef, $s_s_m, undef) = split(/\|/, <MOVEDFILE>, 10);
		fclose(MOVEDFILE);
		&ToChars($s_s_m);
		$ssm = 1;
	}

	$ssm += $s_s_m =~ s/\[spliced\]/$maintxt{'160c'}/g; # The contents of this Topic have been moved to
	$ssm += $s_s_m =~ s/\[splicedhere\]|\[splithere\]/$maintxt{'160d'}/g; # this Topic
	$ssm += $s_s_m =~ s/\[split\]/$maintxt{'160e'}/g; # Off-Topic replies have been moved to
	$ssm += $s_s_m =~ s/\[splithere_end\]/$maintxt{'160f'}/g; # .
	$ssm += $s_s_m =~ s/\[moved\]/$maintxt{'160'}/g; # This Topic has been moved to
	$ssm += $s_s_m =~ s/\[movedhere\]/$maintxt{'161'}/g; # This Topic was moved here from
	$ssm += $s_s_m =~ s/\[postsmovedhere1\]/$maintxt{'161a'}/g; # The last
	$ssm += $s_s_m =~ s/\[postsmovedhere2\]/$maintxt{'161b'}/g; # Posts were moved here from
	$ssm += $s_s_m =~ s/\[move by\]/$maintxt{'525'}/g; # by
	if ($ssm) { # only if it was an internal s_s_m info
		$s_s_m =~ s~\[link=\s*(\S\w+\://\S+?)\s*\](.+?)\[/link\]~<a href="$1">$2</a>~g;
		$s_s_m =~ s~\[link=\s*(\S+?)\](.+?)\s*\[/link\]~<a href="http://$1">$2</a>~g;
		$s_s_m =~ s~\[b\](.*?)\[/b\]~<b>$1</b>~g;
		$s_s_m =~ s~\[i\](.*?)\[/i\]~<i>$1</i>~g;
	}
	return ($s_s_m,$ssm);
}

sub elimnests {
	$_ = $_[0];
	$_ =~ s~\[/*shadow([^\]]*)\]~~ig;
	$_ =~ s~\[/*glow([^\]]*)\]~~ig;
	return $_;
}

sub unwrap {
	$codelang = $_[0];
	$unwrapped = $_[1];
	$unwrapped =~ s~<yabbwrap>~~g;
	$unwrapped = qq~\[code$codelang\]$unwrapped\[\/code\]~;
	return $unwrapped;
}

sub wrap {
	if ($newswrap) { $linewrap = $newswrap; }
	$message =~ s~ &nbsp; &nbsp; &nbsp;~\[tab\]~ig;
	$message =~ s~<br \/>~\n~g;
	$message =~ s~<br>~\n~g;
	$message =~ s/((\[ch\d{3,}?\]){$linewrap})/$1\n/ig;

	&FromHTML($message);
	$message =~ s~[\n\r]~ <yabbbr> ~g;
	my @words = split(/\s/, $message);
	$message = "";
	foreach $cur (@words) {
		if ($cur !~ m~www\.(\S+?)\.~ && $cur !~ m~[ht|f]tp://~ && $cur !~ m~\[\S*\]~ && $cur !~ m~\[\S*\s?\S*?\]~ && $cur !~ m~\[\/\S*\]~) { $cur =~ s~(\S{$linewrap})~$1\n~gi; }
		if ($cur !~ m~\[table(\S*)\](\S*)\[\/table\]~ && $cur !~ m~\[url(\S*)\](\S*)\[\/url\]~ && $cur !~ m~\[flash(\S*)\](\S*)\[\/flash\]~ && $cur !~ m~\[img(\S*)\](\S*)\[\/img\]~) {
			$cur =~ s~(\[\S*?\])~ $1 ~g;
			@splitword = split(/\s/, $cur);
			$cur = "";
			foreach $splitcur (@splitword) {
				if ($splitcur !~ m~www\.(\S+?)\.~ && $splitcur !~ m~[ht|f]tp://~ && $splitcur !~ m~\[\S*\]~) { $splitcur =~ s~(\S{$linewrap})~$1<yabbwrap>~gi; }
				$cur .= $splitcur;
			}
		}
		$message .= "$cur ";
	}
	$message =~ s~\[code((?:\s*).*?)\](.*?)\[\/code\]~&unwrap($1,$2)~eisg;
	$message =~ s~ <yabbbr> ~\n~g;
	$message =~ s~<yabbwrap>~\n~g;

	&ToHTML($message);
	$message =~ s~\[tab\]~ &nbsp; &nbsp; &nbsp;~ig;
	$message =~ s~\n~<br />~g;
}

sub wrap2 {
	$message =~ s#<a href=(\S*?)(\s[^>]*)?>(\S*?)</a># my ($mes,$out,$i) = ($3,"",1); { while ($mes ne "") { if ($mes =~ s/^(<.+?>)//) { $out .= $1; } elsif ($mes =~ s/^(&.+?;|\[ch\d{3,}\]|.)//) { last if $i > $linewrap; $i++; $out .= $1; if ($mes eq "") { $i--; last; } } } } "<a href=$1$2>$out" . ($i > $linewrap ? "..." : "") . "</a>" #eig;
}

sub MembershipGet {
	if (fopen(FILEMEMGET, "$memberdir/members.ttl")) {
		$_ = <FILEMEMGET>;
		chomp;
		fclose(FILEMEMGET);
		return split(/\|/, $_);
	} else {
		my @ttlatest = &MembershipCountTotal;
		return @ttlatest;
	}
}

{
	my %yyOpenMode = (
		'+>>' => 5,
		'+>'  => 4,
		'+<'  => 3,
		'>>'  => 2,
		'>'   => 1,
		'<'   => 0,
		''    => 0,
	);

	# fopen: opens a file. Allows for file locking and better error-handling.
	sub fopen ($$;$) {
		my ($pack, $file, $line) = caller;
		$file_open++;
		my ($filehandle, $filename, $usetmp) = @_;
		## make life easier - spot a file that's not closed!
		if ($debug) { $openfiles .= qq~$filehandle (~ . sprintf("%.4f", (time - $START_TIME)) . qq~)     $filename~; }
		my ($flockCorrected, $cmdResult, $openMode, $openSig);

		$serveros = "$^O";
		if ($serveros =~ m/Win/ && substr($filename, 1, 1) eq ":") {
			$filename =~ s~\\~\\\\~g; # Translate windows-style \ slashes to windows-style \\ escaped slashes.
			$filename =~ s~/~\\\\~g;  # Translate unix-style / slashes to windows-style \\ escaped slashes.
		} else {
			$filename =~ tr~\\~/~;    # Translate windows-style \ slashes to unix-style / slashes.
		}
		$LOCK_EX     = 2;                 # You can probably keep this as it is set now.
		$LOCK_UN     = 8;                 # You can probably keep this as it is set now.
		$LOCK_SH     = 1;                 # You can probably keep this as it is set now.
		$usetempfile = 0;                 # Write to a temporary file when updating large files.

		# Check whether we want write, append, or read.
		$filename =~ m~\A([<>+]*)(.+)~;
		$openSig  = $1                    || '';
		$filename = $2                    || $filename;
		$openMode = $yyOpenMode{$openSig} || 0;

		$filename =~ s~[^/\\0-9A-Za-z#%+\,\-\ \.\:@^_]~~g;    # Remove all inappropriate characters.

		if ($filename =~ m~/\.\./~) { &fatal_error("cannot_open","$filename. $maintxt{'609'}"); }

		# If the file doesn't exist, but a backup does, rename the backup to the filename
		if (!-e $filename && -e "$filename.bak") { rename("$filename.bak", "$filename"); }
		if (-z $filename && -e "$filename.bak") { rename("$filename.bak", "$filename"); }

		$testfile = $filename;
		if ($use_flock == 2 && $openMode) {
			my $count;
			while ($count < 15) {
				if (-e $filehandle) { sleep 2; }
				else { last; }
				++$count;
			}
			unlink($filehandle) if ($count == 15);
			local *LFH;
			CORE::open(LFH, ">$filehandle");
			$yyLckFile{$filehandle} = *LFH;
		}

		if ($use_flock && $openMode == 1 && $usetmp && $usetempfile && -e $filename) {
			$yyTmpFile{$filehandle} = $filename;
			$filename .= '.tmp';
		}

		if ($openMode > 2) {
			if ($openMode == 5) { $cmdResult = CORE::open($filehandle, "+>>$filename"); }
			elsif ($use_flock == 1) {
				if ($openMode == 4) {
					if (-e $filename) {

						# We are opening for output and file locking is enabled...
						# read-open() the file rather than write-open()ing it.
						# This is to prevent open() from clobbering the file before
						# checking if it is locked.
						$flockCorrected = 1;
						$cmdResult = CORE::open($filehandle, "+<$filename");
					} else {
						$cmdResult = CORE::open($filehandle, "+>$filename");
					}
				} else {
					$cmdResult = CORE::open($filehandle, "+<$filename");
				}
			} elsif ($openMode == 4) {
				$cmdResult = CORE::open($filehandle, "+>$filename");
			} else {
				$cmdResult = CORE::open($filehandle, "+<$filename");
			}
		} elsif ($openMode == 1 && $use_flock == 1) {
			if (-e $filename) {

				# We are opening for output and file locking is enabled...
				# read-open() the file rather than write-open()ing it.
				# This is to prevent open() from clobbering the file before
				# checking if it is locked.
				$flockCorrected = 1;
				$cmdResult = CORE::open($filehandle, "+<$filename");
			} else {
				$cmdResult = CORE::open($filehandle, ">$filename");
			}
		} elsif ($openMode == 1) {
			$cmdResult = CORE::open($filehandle, ">$filename");    # Open the file for writing
		} elsif ($openMode == 2) {
			$cmdResult = CORE::open($filehandle, ">>$filename");    # Open the file for append
		} elsif ($openMode == 0) {
			$cmdResult = CORE::open($filehandle, $filename);        # Open the file for input
		}
		unless ($cmdResult)      { return 0; }
		if     ($flockCorrected) {

			# The file was read-open()ed earlier, and we have now verified an exclusive lock.
			# We shall now clobber it.
			flock($filehandle, $LOCK_EX);
			if ($faketruncation) {
				CORE::open(OFH, ">$filename");
				unless ($cmdResult) { return 0; }
				print OFH '';
				CORE::close(OFH);
			} else {
				truncate(*$filehandle, 0) || &fatal_error("truncation_error","$filename");
			}
			seek($filehandle, 0, 0);
		} elsif ($use_flock == 1) {
			if ($openMode) { flock($filehandle, $LOCK_EX); }
			else { flock($filehandle, $LOCK_SH); }
		}
		return 1;
	}

	# fclose: closes a file, using Windows 95/98/ME-style file locking if necessary.
	sub fclose ($) {
		my ($pack, $file, $line) = caller;
		$file_close++;
		my $filehandle = $_[0];
		if ($debug) { $openfiles .= qq~     $filehandle (~ . sprintf("%.4f", (time - $START_TIME)) . qq~)\n[$pack, $file, $line]\n\n~; }
		CORE::close($filehandle);
		if ($use_flock == 2) {
			if (exists $yyLckFile{$filehandle} && -e $filehandle) {
				CORE::close($yyLckFile{$filehandle});
				unlink($filehandle);
				delete $yyLckFile{$filehandle};
			}
		}
		if ($yyTmpFile{$filehandle}) {
			my $bakfile = $yyTmpFile{$filehandle};
			if ($use_flock == 1) {

				# Obtain an exclusive lock on the file.
				# ie: wait for other processes to finish...
				local *FH;
				CORE::open(FH, $bakfile);
				flock(FH, $LOCK_EX);
				CORE::close(FH);
			}

			# Switch the temporary file with the original.
			unlink("$bakfile.bak") if (-e "$bakfile.bak");
			rename($bakfile, "$bakfile.bak");
			rename("$bakfile.tmp", $bakfile);
			delete $yyTmpFile{$filehandle};
			if (-e $bakfile) {
				unlink("$bakfile.bak");    # Delete the original file to save space.
			}
		}
		return 1;
	}

}	# / my %yyOpenMode

sub KickGuest {
	require "$sourcedir/LogInOut.pl";
	$sharedLogin_title = "$maintxt{'633'}";
	$sharedLogin_text  = qq~<br />$maintxt{'634'}<br />$maintxt{'635'} <a href="$scripturl?action=register">$maintxt{'636'}</a> $maintxt{'637'}<br /><br />~;
	$yymain .= &sharedLogin;
	$yytitle = "$maintxt{'34'}";
	&template;
}

sub WriteLog {
	# comment out (#) the next line if you have problems with
	# 'Reverse DNS lookup timeout causes slow page loads'
	# (http://www.yabbforum.com/community/YaBB.pl?num=1199991357)
	# Search Engine identification and display will be turned off
	my $user_host = (gethostbyaddr(pack("C4", split(/\./, $user_ip)), 2))[0];

	my ($name, $logtime, @new_log);
	my $field = $username;
	if ($field eq "Guest") { if ($guestaccess) { $field = $user_ip; } else { return; } }

	my $onlinetime = $date - ($OnlineLogTime * 60);
	fopen(LOG, "+<$vardir/log.txt");
	@logentries = <LOG>; # Global variable
	foreach (@logentries) {
		($name, $logtime, undef) = split(/\|/, $_, 3);
		if ($name ne $user_ip && $name ne $field && $logtime >= $onlinetime) { push(@new_log, $_); }
	}
	seek LOG, 0, 0;
	truncate LOG, 0;
	print LOG ("$field|$date|$user_ip|$user_host#$ENV{'HTTP_USER_AGENT'}\n", @new_log);
	fclose(LOG);

	if (!$action && $enableclicklog == 1) {
		$onlinetime = $date - ($ClickLogTime * 60);
		fopen(LOG, "+<$vardir/clicklog.txt", 1);
		@new_log = <LOG>;
		seek LOG, 0, 0;
		truncate LOG, 0;
		print LOG "$field|$date|$ENV{'REQUEST_URI'}|" . ($ENV{'HTTP_REFERER'} =~ m~$boardurl~i ? '' : $ENV{'HTTP_REFERER'}) . "|$ENV{'HTTP_USER_AGENT'}\n";
		foreach (@new_log) { if ((split(/\|/, $_, 3))[1] >= $onlinetime) { print LOG $_; } }
		fclose(LOG);
	}
}

sub RemoveUserOnline {
	my $user = shift;
	fopen(LOG, "+<$vardir/log.txt", 1);
	@logentries = <LOG>; # Global variable
	seek LOG, 0, 0;
	truncate LOG, 0;
	if ($user) {
		my $x = -1;
		for (my $i = 0; $i < @logentries; $i++) {
			if ((split(/\|/, $logentries[$i], 2))[0] ne $user) { print LOG $logentries[$i]; }
			elsif ($user eq $username) { $logentries[$i] =~ s/^$user\|/$user_ip\|/; print LOG $logentries[$i]; }
			else { $x = $i; }
		}
		splice(@logentries,$x,1) if $x > -1;
	} else {
		print LOG '';
		@logentries = ();
	}
	fclose(LOG);
}

sub freespace {
	my ($FreeBytes,$hostchecked);
	if ($^O =~ /Win/) {
		if ($enable_freespace_check) { 
			my @x = qx{DIR /-C}; # Do an ordinary DOS dir command and grab the output
			my $lastline = pop(@x); # should look like: 17 Directory(s), 21305790464 Bytes free
			return -1 if $lastline !~ m/byte/i; # error trapping if output fails. The word byte should be in the line
			$lastline =~ /^\s+(\d+)\s+(.+?)\s+(\d+)\s+(.+?)\n$/;
			$FreeBytes = $3 - 100000; # 100000 bytes reserve

		} else {
			return;
		}

		$yyfreespace = "Windows";

	} else {
		if ($enable_quota) {
			my @quota = qx{quota -u $hostusername -v}; # Do an ordinary *nix quota command and grab the output
			return -1 if !$quota[2]; # error trapping if output fails.
			@quota = split(/ +/, $quota[$enable_quota], 5);
			$quota[2] =~ s/\*//;
			$FreeBytes = (($quota[3] - $quota[2]) * 1024) - 100000; # 100000 bytes reserve
			$hostchecked = 1;

		} elsif ($findfile_maxsize) {
			($FreeBytes,$hostchecked) = split(/<>/, $findfile_space);
			if ($FreeBytes < 1 || $hostchecked < $date) {
				# fork the process since the *nix find command can take a while
				$child_pid = fork();
				unless ($child_pid) { # child process runs here and exits then
					$findfile_space = 0;
					map { $findfile_space += $_ } split(/-/, qx(find $findfile_root -noleaf -type f -printf "%s-"));
					$findfile_space = (($findfile_maxsize * 1024 * 1024) - $findfile_space) . "<>" . ($date + ($findfile_time * 60)); # actual free host space <> time for next check

					require "$admindir/NewSettings.pl";
					&SaveSettingsTo('Settings.pl');
					exit(0);
				}
			}
			$hostchecked = 1;

		} elsif ($enable_freespace_check) {
			my @x = qx{df -k .}; # Do an ordinary *nix df -k . command and grab the output
			my $lastline = pop(@x); # should look like: /dev/path 151694892 5495660 134063644 4% /
			return -1 if $lastline !~ m/\%/; # error trapping if output fails. The % sign should be in the line
			$FreeBytes = ((split(/ +/, $lastline, 5))[3] * 1024) - 100000; # 100000 bytes reserve

		} else {
			return;
		}

		$yyfreespace = "Unix/Linux/BSD";
	}
	&automaintenance('on','low_disk') if $FreeBytes < 1;

	if ($FreeBytes >= 1073741824) {
		$yyfreespace = sprintf("%.2f", $FreeBytes / (1024 * 1024 * 1024)) . " GB ($yyfreespace)";
	} elsif ($FreeBytes >= 1048576) {
		$yyfreespace = sprintf("%.2f", $FreeBytes / (1024 * 1024)) . " MB ($yyfreespace)";
	} else {
		$yyfreespace = sprintf("%.2f", $FreeBytes / 1024) . " KB ($yyfreespace)";
	}
	$hostchecked;
}

sub encode_password {
	my $eol = $_[0];
	chomp $eol;
	require Digest::MD5;
	import Digest::MD5 qw(md5_base64);
	md5_base64($eol);
}

sub Censor {
	my $string = $_[0];
	foreach $censor (@censored) {
		my ($tmpa, $tmpb, $tmpc) = @{$censor};
		if ($tmpc) {
			$string =~ s~(^|\W|_)\Q$tmpa\E(?=$|\W|_)~$1$tmpb~gi;
		} else {
			$string =~ s~\Q$tmpa\E~$tmpb~gi;
		}
	}
	return $string;
}

sub CheckCensor {
	my $string = $_[0];
	foreach $censor (@censored) {
		my ($tmpa, $tmpb, $tmpc) = @{$censor};
		if ($string =~ m/(\Q$tmpa\E)/i) {
			$found_word .= "$1 ";
		}
	}
	return $found_word;
}

sub referer_check {
	return if !$action;
	my $referencedomain = substr($boardurl, 7, (index($boardurl, "/", 7)) - 7);
	my $refererdomain = substr($ENV{HTTP_REFERER}, 7, (index($ENV{HTTP_REFERER}, "/", 7)) - 7);
	if ($refererdomain !~ /$referencedomain/ && $ENV{QUERY_STRING} ne "" && length($refererdomain) > 0) {
		my $goodaction = 0;
		fopen(ALLOWED, "$vardir/allowed.txt");
		my @allowed = <ALLOWED>;
		fclose(ALLOWED);
		foreach my $allow (@allowed) {
			chomp $allow;
			if ($action eq $allow) { $goodaction = 1; last; }
		}
		if (!$goodaction) { &fatal_error("referer_violation","$action<br />$reftxt{'7'} $referencedomain<br />$reftxt{'6'} $refererdomain"); }
	}
}

sub Dereferer {
	&fatal_error('no_access') unless $stealthurl;
	print "Content-Type: text/html\n\n";
	print qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n<head>\n<meta http-equiv="Content-Type" content="text/html; charset=$yycharset" />\n<title>-----</title>\n</head>\n<body onload="window.location.href='$INFO{'url'}';">\n<font face="Arial" size="2">$dereftxt{'1'}</font>\n</body></html>\n~;
	exit;
}

sub LoadLanguage {
	my $what_to_load = $_[0];
	my $use_lang     = $language ? $language : $lang;
	if (-e "$langdir/$use_lang/$what_to_load.lng") {
		require "$langdir/$use_lang/$what_to_load.lng";
	} elsif (-e "$langdir/$lang/$what_to_load.lng") {
		require "$langdir/$lang/$what_to_load.lng";
	} elsif (-e "$langdir/English/$what_to_load.lng") {
		require "$langdir/English/$what_to_load.lng";
	} else {
		# Catches deep recursion problems
		# We can simply return to the error routine once we add the needed string
		if($what_to_load eq 'Error') {
			%error_txt = (
			'cannot_open_language' => "Can't find required language file. Please inform the administrator about this problem.",
			'error_description' => "An Error Has Occurred!",
			);
			return;
		}

		&fatal_error("cannot_open_language","$use_lang/$what_to_load.lng");
	}
}

sub Recent_Load {
	my $who_to_load = $_[0];
	undef %recent;
	if (-e "$memberdir/$who_to_load.rlog") {
		fopen(RLOG, "$memberdir/$who_to_load.rlog");
		my %r = map /(.*)\t(.*)/, <RLOG>;
		fclose(RLOG);
		map{ @{$recent{$_}} = split(/,/, $r{$_}); } keys %r;
	} elsif (-e "$memberdir/$who_to_load.wlog") {
		require "$memberdir/$who_to_load.wlog";
		fopen(RLOG, ">$memberdir/$who_to_load.rlog");
		print RLOG map "$_\t$recent{$_}\n", keys %recent;
		fclose(RLOG);
		unlink "$memberdir/$who_to_load.wlog";
		&Recent_Load($who_to_load); 
	}
}

sub Recent_Write {
	my ($todo, $recentthread, $recentuser,$recenttime) = @_;
	&Recent_Load($recentuser);
	if ($todo eq "incr") {
		${$recent{$recentthread}}[0]++;
		${$recent{$recentthread}}[1] = $recenttime;
	} elsif ($todo eq "decr") {
		${$recent{$recentthread}}[0]--;
		if (${$recent{$recentthread}}[0] < 1) { delete $recent{$recentthread}; }
		else { ${$recent{$recentthread}}[1] = $recenttime; }
	}
	&Recent_Save($recentuser);
}

sub Recent_Save {
	my $who_to_save = $_[0];
	if (!%recent) {
		unlink("$memberdir/$who_to_save.rlog");
		return;
	}
	fopen(RLOG, ">$memberdir/$who_to_save.rlog");
	print RLOG map "$_\t" . join(',', @{$recent{$_}}) . "\n", keys %recent;
	fclose(RLOG);
}

sub save_moved_file {
	# This sub saves the hash for the moved files: key == old id, value == new id
	fopen(MOVEDFILE, ">$datadir/movedthreads.cgi") || &fatal_error("cannot_open",">$datadir/movedthreads.cgi", 1);
	print MOVEDFILE "%moved_file = (" . join(',', map { qq~"$_","$moved_file{$_}"~ } grep { ($_ > 0 && $moved_file{$_} > 0 && $_ != $moved_file{$_}) } keys %moved_file) . ");\n1;";
	fclose(MOVEDFILE);
}

sub Write_ForumMaster {
	fopen(FORUMMASTER, ">$boardsdir/forum.master", 1);
	print FORUMMASTER qq~\$mloaded = 1;\n~;
	@catorder = &undupe(@categoryorder);
	print FORUMMASTER qq~\@categoryorder = qw(@catorder);\n~;
	my ($key, $value);
	while (($key, $value) = each(%cat)) {
		# Escape membergroups with a $ in them
		$value =~ s~\$~\\\$~g;
		# Strip membergroups with a ~ from them
		$value =~ s/\~//g;
		print FORUMMASTER qq~\$cat{'$key'} = qq\~$value\~;\n~;
	}
	while (($key, $value) = each(%catinfo)) {
		my ($catname, $therest) = split(/\|/, $value, 2);
		#$catname =~ s/\&(?!amp;)/\&amp;$1/g;
		# We can rely on the admin scripts to properly encode when needed.
		$value = "$catname|$therest";

		# Escape membergroups with a $ in them
		$value =~ s~\$~\\\$~g;
		# Strip membergroups with a ~ from them
		$value =~ s/\~//g;
		print FORUMMASTER qq~\$catinfo{'$key'} = qq\~$value\~;\n~;
	}
	while (($key, $value) = each(%board)) {
		my ($boardname, $therest) = split(/\|/, $value, 2);
		#$boardname =~ s/\&(?!amp;)/\&amp;$1/g;
		# We can rely on the admin scripts to properly encode when needed.
		$value = "$boardname|$therest";

		# Escape membergroups with a $ in them
		$value =~ s~\$~\\\$~g;
		# Strip membergroups with a ~ from them
		$value =~ s/\~//g;
		print FORUMMASTER qq~\$board{'$key'} = qq\~$value\~;\n~;
	}
	print FORUMMASTER qq~\n1;~;
	fclose(FORUMMASTER);
}

sub dirsize {
	my $dirsize;
	require File::Find;
	import File::Find;
	&find(sub { $dirsize += -s }, $_[0]);
	$dirsize;
}

sub MemberPageindex {
	my ($msindx, $trindx, $mbindx, $pmindx);
	($msindx, $trindx, $mbindx, $pmindx) = split(/\|/, ${$uid.$username}{'pageindex'});
	if ($INFO{'action'} eq "memberpagedrop") {
		${$uid.$username}{'pageindex'} = qq~$msindx|$trindx|0|$pmindx~;
	}
	if ($INFO{'action'} eq "memberpagetext") {
		${$uid.$username}{'pageindex'} = qq~$msindx|$trindx|1|$pmindx~;
	}
	&UserAccount($username, "update");
	my $SearchStr = $FORM{'member'} || $INFO{'member'};
	if ($SearchStr ne '') { $findmember = qq~;member=$SearchStr~; }
	if(!$INFO{'from'}) {
		$yySetLocation = qq~$scripturl?action=ml;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'}$findmember~;
	} elsif($INFO{'from'} eq "imlist") {
		$yySetLocation = qq~$scripturl?action=imlist;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'};field=$INFO{'field'}~;
	} elsif($INFO{'from'} eq 'admin') {
		$yySetLocation = qq~$adminurl?action=ml;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'}~;
	}

	&redirectexit;
}

#changed sub for improve perfomance, code from Zoo
sub check_existence {
	my ($dir, $filename) = @_;

	$filename =~ /(\S+?)(\.\S+$)/;
	my $origname = $1;
	my $filext = $2;
	my $numdelim = "_";
	my $filenumb = 0;
	while (-e "$dir/$filename") {
			$filenumb = sprintf("%03d", ++$filenumb);
			$filename = qq~$origname$numdelim$filenumb$filext~;
	}
	return ($filename);
}

sub ManageMemberlist {
	my $todo    = $_[0];
	my $user    = $_[1];
	my $userreg = $_[2];
	if ($todo eq "load" || $todo eq "update" || $todo eq "delete" || $todo eq "add") {
		fopen(MEMBLIST, "$memberdir/memberlist.txt");
		%memberlist = map /(.*)\t(.*)/, <MEMBLIST>;
		fclose(MEMBLIST);
	}
	if ($todo eq "add") {
		$memberlist{$user} = "$userreg";

	} elsif ($todo eq "update") {
		$memberlist{$user} = $userreg ? $userreg : $memberlist{$user};

	} elsif ($todo eq "delete") {
		if ($user =~ /,/) {    # been sent a list to kill, not a single
			my @oldusers = split(',', $user);
			foreach my $user (@oldusers) {
				delete($memberlist{$user});
			}
		}
		else	{delete($memberlist{$user});}
	}
	if ($todo eq "save" || $todo eq "update" || $todo eq "delete" || $todo eq "add") {
		fopen(MEMBLIST, ">$memberdir/memberlist.txt");
		print MEMBLIST map "$_\t$memberlist{$_}\n", sort { $memberlist{$a} <=> $memberlist{$b} } keys %memberlist;
		fclose(MEMBLIST);
		undef %memberlist;
	}
}

## deal with basic member data in memberinfo.txt
sub ManageMemberinfo {
	my $todo       = $_[0];
	my $user       = $_[1];
	my $userdisp   = $_[2];
	my $usermail   = $_[3];
	my $usergrp    = $_[4];
	my $usercnt    = $_[5];
	my $useraddgrp = $_[6];
	## pull hash of member name + other data
	if ($todo eq "load" || $todo eq "update" || $todo eq "delete" || $todo eq "add") {
		fopen(MEMBINFO, "$memberdir/memberinfo.txt");
		%memberinf = map /(.*)\t(.*)/, <MEMBINFO>;
		fclose(MEMBINFO);
	}
	if ($todo eq "add") {
		$memberinf{$user} = "$userdisp|$usermail|$usergrp|$usercnt|$useraddgrp";
	} elsif ($todo eq "update") {
		($memrealname, $mememail, $memposition, $memposts, $memaddgrp) = split(/\|/, $memberinf{$user});
		if ($userdisp) { $memrealname = $userdisp; }
		if ($usermail) { $mememail = $usermail; }
		if ($usergrp) { $memposition = $usergrp; }
		if ($usercnt) { $memposts = $usercnt; }
		if ($useraddgrp) {
			if ($useraddgrp =~ /###blank###/) { $useraddgrp = ''; }
			$memaddgrp = $useraddgrp;
		}
		$memberinf{$user} = "$memrealname|$mememail|$memposition|$memposts|$memaddgrp";
	} elsif ($todo eq "delete") {
		if ($user =~ /,/) {    # been sent a list to kill, not a single
			my @oldusers = split(',', $user);
			foreach my $user (@oldusers) {
				delete($memberinf{$user});
			}
		}	
		delete($memberinf{$user});
	}
	if ($todo eq "save" || $todo eq "update" || $todo eq "delete" || $todo eq "add") {
		fopen(MEMBINFO, ">$memberdir/memberinfo.txt");
		print MEMBINFO map "$_\t$memberinf{$_}\n", keys %memberinf;
		fclose(MEMBINFO);
		undef %memberinf;
	}
}

sub Collapse_Load {
	my (%userhide, $catperms, $catallowcol, $access);
	my $i = 0;
	map{ $userhide{$_} = 1; } split(/,/, ${$uid.$username}{'cathide'});
	foreach my $key (@categoryorder) {
		(undef, $catperms, $catallowcol) = split(/\|/, $catinfo{$key});
		$access = &CatAccess($catperms);
		if ($catallowcol == 1 && $access) { $i++; }
		$catcol{$key} = 1;
		if ($catallowcol == 1 && $userhide{$key}) { $catcol{$key} = 0; }
	}
	$colbutton = ($i == keys %userhide) ? 0 : 1;
	$colloaded = 1;
}

sub MailList {
	&is_admin_or_gmod;
	my $delmailline = '';
	if (!$INFO{'delmail'}) {
		$mailline = $_[0];
		$mailline =~ s~\r~~g;
		$mailline =~ s~\n~<br />~g;
	} else {
		$delmailline = $INFO{'delmail'};
	}
	if (-e ("$vardir/maillist.dat")) {
		fopen(FILE, "$vardir/maillist.dat");
		@maillist = <FILE>;
		fclose(FILE);
		fopen(FILE, ">$vardir/maillist.dat");
		if (!$INFO{'delmail'}) {
			print FILE "$mailline\n";
		}
		foreach $curmail (@maillist) {
			chomp $curmail;
			$otime = (split /\|/, $curmail)[0];
			if ($otime ne $delmailline) {
				print FILE "$curmail\n";
			}
		}
		fclose(FILE);
	} else {
		fopen(FILE, ">$vardir/maillist.dat");
		print FILE "$mailline\n";
		fclose(FILE);
	}
	if ($INFO{'delmail'}) {
		$yySetLocation = qq~$adminurl?action=mailing~;
		&redirectexit;
	}
}

sub cloak {
	my ($input) =$_[0];
	my ($user,$ascii,$key,$hex,$hexkey);
	$key = substr($date,length($date)-2,2);
	$hexkey = uc(unpack("H2", pack("V", $key)));
	for($n=0; $n < length $input ; $n++)    {
		$ascii = substr($input, $n, 1);
		$ascii = ord($ascii) ^ $key; # xor it instead of adding to prevent wide characters
		$hex = uc(unpack("H2", pack("V", $ascii)));
		$user .= $hex;
	}
	$user .= $hexkey;
	$user .= '0';
	return $user;
}

sub decloak {
	my ($input) =$_[0];
	my ($user,$ascii,$key,$dec,$hexkey);
	if (length($input) % 2 == 0) {return &old_decloak($input);} # Old style, return it
	elsif ($input !~ /\A[0-9A-F]+\Z/) {return $input; }         # probably a non cloacked ID as it contains non hex code
	else {$input =~ s~0$~~;}
	$hexkey = substr($input,length($input)-2,2);
	$key = hex($hexkey);
	for($n=0; $n < length($input)-2; $n += 2)    {
		$dec = substr($input, $n, 2);
		$ascii = hex($dec) ^ $key; # xor it to reverse it
		$ascii = chr($ascii);
		$user .= $ascii;
	}
	return $user;
}

# THIS IS BROKEN -- it fails on larger ASCII values (for example chr(255) )
# It is only here to support YaBBForum's old format.
sub old_decloak {
	my ($input) =$_[0];
	my ($user,$ascii,$key,$dec,$hexkey,$x);
	if ($input !~ /\A[0-9A-F]+\Z/) { return $input; }    ## probably a non cloacked ID as it contains non hex code
	$hexkey = substr($input,length($input)-2,2);
	$key = hex($hexkey);
	$x=0;
	for($n=0; $n < length($input)-2; $n++) {
		$dec = substr($input, $n, 2);
		$ascii = hex($dec);
		$ascii = chr($ascii-$key+$x);
		$user .= $ascii;
		$n++;
		$x++;
		if ($x > 32){$x = 0;}
	}
	return $user;
}

# run through the log.txt and return the online/offline/away string near by the username
my %users_online;
sub userOnLineStatus {
	my $userToCheck = $_[0];

	return '' if $userToCheck eq 'Guest';
	if (exists $users_online{$userToCheck}) {
		return $users_online{$userToCheck} if $users_online{$userToCheck};
	} else {
		map { $users_online{(split(/\|/, $_, 2))[0]} = 0 } @logentries;
	}

	&LoadUser($userToCheck);

	if (exists $users_online{$userToCheck} && (!${$uid.$userToCheck}{'stealth'} || $iamadmin || $iamgmod)) {
		${$uid.$userToCheck}{'offlinestatus'} = 'online';
		$users_online{$userToCheck} = qq~<span class="useronline">$maintxt{'60'}</span>~ . (${$uid.$userToCheck}{'stealth'} ? "*" : "");
	} else {
		$users_online{$userToCheck} = qq~<span class="useroffline">$maintxt{'61'}</span>~;
	}
	# enable 'away' indicator $enable_MCaway: 0=Off; 1=Staff to Staff; 2=Staff to all; 3=Members
	if (!$iamguest && $enable_MCstatusStealth &&
	    (($enable_MCaway == 1 && $staff) || $enable_MCaway > 1) &&
	    ${$uid.$userToCheck}{'offlinestatus'} eq 'away') {
		$users_online{$userToCheck} = qq~<span class="useraway">$maintxt{'away'}</span>~;
	}
	$users_online{$userToCheck};
}

## moved from Register.pl so we can use for guest browsing
sub guestLangSel {
	opendir(DIR, $langdir);
	$morelang = 0;
	my @langDir = readdir(DIR);
	close(DIR);
	foreach my $filesanddirs (sort {lc($a) cmp lc($b)} @langDir) {
		chomp $filesanddirs;
		if (($filesanddirs ne '.') && ($filesanddirs ne '..') && (-e "$langdir/$filesanddirs/Register.lng")) {
			$lngsel = "";
			if ($filesanddirs eq $language) { $lngsel = qq~ selected="selected"~; }
			$langopt .= qq~<option value="$filesanddirs"$lngsel>$filesanddirs</option>~;
			$morelang++;
		}
	}
	#close(DIR);
	return $langopt;
}

##  control geust language selection. 

sub setGuestLang {
	## if either 'no guest access' or 'no guest lan sel', throw the user back to the logn screen
	if (!$guestaccess || !$enable_guestlanguage) {
		$yySetLocation = qq~$scripturl?action=login~;
		&redirectexit;
	}
	# otherwise, grab the selected language from the form and redirect to load it.
	$guestLang = $FORM{'guestlang'};
	$language = $guestLang;
	$yySetLocation = qq~$scripturl~;
	&redirectexit;
}

##  check for locked post bypass status - user must be at least mod and bypass lock must be set right.
sub checkUserLockBypass {
	my $canbypass;
	## work down the levels
	if ($bypass_lock_perm eq "fa" && $iamadmin) { $canbypass = 1; }
	elsif ($bypass_lock_perm eq "gmod" && ($iamadmin || $iamgmod)) { $canbypass = 1; }
	elsif ($bypass_lock_perm eq "mod" && ($iamadmin || $iamgmod || $iammod)) { $canbypass = 1; } 
	$canbypass;
}

sub alertbox {
	$yymain .= qq~
<script language="JavaScript" type="text/javascript">
	<!--
		alert("$_[0]");
	// -->
</script>~;
}

## load buddy list for user, new version from sub isUserBuddy
sub loadMyBuddy {
	%mybuddie = ();
	if (${$uid.$username}{'buddylist'}) {
		my @buddies = split(/\|/, ${$uid.$username}{'buddylist'});
		chomp(@buddies);
		foreach my $buddy (@buddies) {
			$buddy =~ s/^ //;
			$mybuddie{$buddy} = 1;
		}
	}
}

## add user to buddy list
## this is only for the 
sub addBuddy {
	my $newBuddy;
	if ($INFO{'name'}) {
		if ($do_scramble_id) { $newBuddy = &decloak($INFO{'name'}); }
		else { $newBuddy = $INFO{'name'}; }
		chomp($newBuddy);
		if ($newBuddy eq $username) { &fatal_error("self_buddy"); }
		&ToHTML($newBuddy);
		if (!${$uid.$username}{'buddylist'}) {
			${$uid.$username}{'buddylist'} = "$newBuddy";
		} else {
			my @currentBuddies = split(/\|/, ${$uid.$username}{'buddylist'});
			push(@currentBuddies, $newBuddy);
			sort(@currentBuddies);
			@newBuddies = &undupe(@currentBuddies);
			$newBuddyList = join('|', @newBuddies);
			${$uid.$username}{'buddylist'} = $newBuddyList;
		}
		&UserAccount($username, "update");
	}
	$yySetLocation = qq~$scripturl?num=$INFO{'num'}/$INFO{'vpost'}#$INFO{'vpost'}~;
	if ($INFO{'vpost'} eq '') {
		$yySetLocation = qq~$scripturl?action=viewprofile;username=$INFO{'name'}~;
	}
	&redirectexit;
}

## check to see if user can view a broadcast message based on group
sub BroadMessageView {
	if ($iamadmin) { return 1; }
	if ($_[0]) {
		foreach my $checkgroup (split(/\,/, $_[0])) {
			if ($checkgroup eq 'all') { return 1; }
			if ($checkgroup eq ('gmods' || 'mods') && $iamgmod) { return 1; }
			if ($checkgroup eq 'mods' && $iammod) { return 1; }
			if ($checkgroup eq ${$uid.$username}{'position'}) { return 1; }
			foreach (split(/,/, ${$uid.$username}{'addgroups'})) {
				if ($checkgroup eq $_) { return 1; }
			}
		}
	}
	return 0;
}

sub CheckUserPM_Level {
	my $checkuser = $_[0];
	return if $PM_level <= 1 || $UserPM_Level{$checkuser};
	$UserPM_Level{$checkuser} = 1;
	if (!${$uid.$checkuser}{'password'}) { &LoadUser($checkuser); }
	if (${$uid.$checkuser}{'position'} eq 'Administrator' || ${$uid.$checkuser}{'position'} eq 'Global Moderator') { 
		$UserPM_Level{$checkuser} = 3;
	} else {
		usercheck: foreach my $catid (@categoryorder) {
			foreach my $checkboard (split(/,/, $cat{$catid})) {
				foreach my $curuser (split(/, ?/, ${$uid.$checkboard}{'mods'})) {
					if ($checkuser eq $curuser) { $UserPM_Level{$checkuser} = 2; last usercheck; }
				}
				foreach my $curgroup (split(/, /, ${$uid.$checkboard}{'modgroups'})) {
					if (${$uid.$checkuser}{'position'} eq $curgroup) { $UserPM_Level{$checkuser} = 2; last usercheck; }
					foreach (split(/,/, ${$uid.$checkuser}{'addgroups'})) {
						if ($_ eq $curgroup) { $UserPM_Level{$checkuser} = 2; last usercheck; }
					}
				}
			}
		}
	}
}

1;