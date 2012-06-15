###############################################################################
# RemoveTopic.pl                                                              #
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

$removetopicplver = 'YaBB 2.5 AE $Revision: 1.13 $';
if ($action eq 'detailedversion') { return 1; }

sub RemoveThread {
	my ($threadline, $a, @message);

	$thread = $INFO{'thread'};
	&fatal_error ('only_numbers_allowed') if ($thread =~ /\D/);

	if (!$iammod && !$iamadmin && !$iamgmod && !$iamposter) {
		&fatal_error("delete_not_allowed");
	}
	if (!$currentboard) {
		&MessageTotals("load", $thread);
		$currentboard = ${$thread}{'board'};
	}
	$threadline = '';
	fopen(BOARDFILE, "+<$boardsdir/$currentboard.txt", 1) || &fatal_error("cannot_open","$boardsdir/$currentboard.txt", 1);
	my @buffer = <BOARDFILE>;
	for ($a = 0; $a < @buffer; $a++) {
		if ($buffer[$a] =~ m~\A$thread\|~) {
			$threadline = $buffer[$a];
			$buffer[$a] = "";
			last;
		}
	}
	truncate BOARDFILE, 0;
	seek BOARDFILE, 0, 0;
	print BOARDFILE @buffer;
	fclose(BOARDFILE);

	if ($threadline) {
		unless (ref($thread_arrayref{$thread})) {
			fopen(FILE, "$datadir/$thread.txt") || &fatal_error("cannot_open","$datadir/$thread.txt", 1);
			@{$thread_arrayref{$thread}} = <FILE>;
			fclose(FILE);
		}

		&BoardTotals("load", $currentboard);
		unless ((split(/\|/, $threadline))[8] =~ /m/) {
			${$uid.$currentboard}{'threadcount'}--;
			${$uid.$currentboard}{'messagecount'} -= @{$thread_arrayref{$thread}};
			 # &BoardTotals("update", ...) is done in &BoardSetLastInfo
		}
		&BoardSetLastInfo($currentboard,\@buffer);
		# remove thread files
		unlink("$datadir/$thread.txt");
		unlink("$datadir/$thread.ctb");
		unlink("$datadir/$thread.mail");
		unlink("$datadir/$thread.poll");
		unlink("$datadir/$thread.polled");
		# remove attachments
		require "$admindir/Attachments.pl";
		my %remattach;
		$remattach{$thread} = undef;
		&RemoveAttachments(\%remattach);
	}

	# remove from movedthreads.cgi only if it's the final thread
	# then look backwards to delete the other entries in
	# the Moved-Info-row if their files were deleted
	eval { require "$datadir/movedthreads.cgi" };
	unless ($moved_file{$thread}) {
		my $save_moved;
		&moved_loop($thread);
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
	}

	if ($INFO{'moveit'} != 1) {
		$yySetLocation = qq~$scripturl?board=$currentboard~;
		&redirectexit;
	}
}

sub DeleteThread {
	$delete = $FORM{'thread'} || $INFO{'thread'} || $_[0];

	if (!$currentboard) {
		&MessageTotals("load", $delete);
		$currentboard = ${$delete}{'board'};
	}
	if ($FORM{'ref'} eq "favorites") {
		$INFO{'ref'} = "delete";
		require "$sourcedir/Favorites.pl";
		&RemFav($delete);
	}
	if ((!$adminbin || (!$iamadmin && !$iamgmod)) && $binboard ne "" && $currentboard ne $binboard) {
		require "$sourcedir/MoveSplitSplice.pl";
		$INFO{'moveit'} = 1;
		$INFO{'board'} = $currentboard;
		$INFO{'thread'} = $delete;
		$INFO{'oldposts'} = 'all';
		$INFO{'leave'} = 2;
		$INFO{'newinfo'} = 1;
		$INFO{'newboard'} = $binboard;
		$INFO{'newthread'} = 'new';
		&Split_Splice_2;
	} elsif ($iamadmin || $iamgmod || $binboard eq "") {
		$INFO{'moveit'} = 1;
		$INFO{'thread'} = $delete;
		&RemoveThread;
	}
	$yySetLocation = qq~$scripturl?board=$currentboard~;
	&redirectexit;
}

sub Multi {
	if (!$iammod && !$iamadmin && !$iamgmod) { &fatal_error("not_allowed"); }

	require "$sourcedir/SetStatus.pl";
	require "$sourcedir/MoveSplitSplice.pl";

	my $mess_loop;
	if ($FORM{'allpost'} =~ m/all/i) {
		&BoardTotals("load", $currentboard);
		$mess_loop = ${$uid.$currentboard}{'threadcount'};
	} else {
		$mess_loop = $maxdisplay;
	}

	my $count = 1;
	while ($mess_loop >= $count) {
		my ($lock, $stick, $move, $delete, $ref, $hide);

		if ($FORM{'multiaction'} eq '') {
			$lock   = $FORM{"lockadmin$count"};
			$stick  = $FORM{"stickadmin$count"};
			$move   = $FORM{"moveadmin$count"};
			$delete = $FORM{"deleteadmin$count"};
			$hide   = $FORM{"hideadmin$count"};
		} elsif ($FORM{'multiaction'} eq 'lock') {
			$lock = $FORM{"admin$count"};
		} elsif ($FORM{'multiaction'} eq 'stick') {
			$stick = $FORM{"admin$count"};
		} elsif ($FORM{'multiaction'} eq 'move') {
			$move = $FORM{"admin$count"};
		} elsif ($FORM{'multiaction'} eq 'delete') {
			$delete = $FORM{"admin$count"};
		} elsif ($FORM{'multiaction'} eq 'hide') {
			$hide = $FORM{"admin$count"};
		}

		if ($FORM{'ref'} eq "favorites") {
			$ref = qq~$scripturl?action=favorites~;
		} else {
			$ref = qq~$scripturl?board=$currentboard~;
		}

		if ($lock) {
			$INFO{'moveit'} = 1;
			$INFO{'thread'} = $lock;
			$INFO{'action'} = "lock";
			$INFO{'ref'}    = $ref;
			&SetStatus;
		}
		if ($stick) {
			$INFO{'moveit'} = 1;
			$INFO{'thread'} = $stick;
			$INFO{'action'} = "sticky";
			$INFO{'ref'}    = $ref;
			&SetStatus;
		}
		if ($move) {
			$INFO{'moveit'} = 1;
			$INFO{'board'} = $currentboard;
			$INFO{'thread'} = $move;
			$INFO{'oldposts'} = 'all';
			$INFO{'leave'} = 0;
			$INFO{'newinfo'} ||= $FORM{"newinfo"};
			$INFO{'newboard'} = $FORM{"toboard"};
			$INFO{'newthread'} = 'new';
			&Split_Splice_2;
		}
		if ($hide) {
			$INFO{'moveit'} = 1;
			$INFO{'action'} = 'hide';
			$INFO{'thread'} = $hide;
			&SetStatus;
		}
		if ($delete) {
			if (!$currentboard) {
				&MessageTotals("load", $delete);
				$currentboard = ${$delete}{'board'};
			}
			if ($FORM{'ref'} eq "favorites") {
				$INFO{'ref'} = "delete";
				require "$sourcedir/Favorites.pl";
				&RemFav($delete);
			}
			if ((!$adminbin || (!$iamadmin && !$iamgmod)) && $binboard ne "" && $currentboard ne $binboard) {
				$INFO{'moveit'} = 1;
				$INFO{'board'} = $currentboard;
				$INFO{'thread'} = $delete;
				$INFO{'oldposts'} = 'all';
				$INFO{'leave'} = 2;
				$INFO{'newinfo'} = 1;
				$INFO{'newboard'} = $binboard;
				$INFO{'newthread'} = 'new';
				&Split_Splice_2;
			} elsif ($iamadmin || $iamgmod || $binboard eq "") {
				$INFO{'moveit'} = 1;
				$INFO{'thread'} = $delete;
				&RemoveThread;
			}
		}
		$count++;
	}
	$yySetLocation = qq~$scripturl?board=$currentboard~;
	&redirectexit;
}

1;