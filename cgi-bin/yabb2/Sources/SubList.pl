###############################################################################
# SubList.pl                                                                  #
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

$sublistplver = 'YaBB 2.5 AE $Revision: 1.28 $';
if ($action eq 'detailedversion') { return 1; }

%director=( # in alphabetical Order!
'activate',"Register.pl&user_activation",
'addbuddy',"Subs.pl&addBuddy",
'addfav',"Favorites.pl&AddFav",
'addtab2',"AdvancedTabs.pl&AddNewTab2",
'boardnotify',"Notify.pl&BoardNotify",
'boardnotify2',"MyCenter.pl&mycenter",
'boardnotify3',"Notify.pl&BoardNotify2",
'checkavail',"UserSelect.pl&checkUserAvail",
'collapse_all',"BoardIndex.pl&Collapse_All",
'collapse_cat',"BoardIndex.pl&Collapse_Cat",
'deletemultimessages',"MyCenter.pl&Del_Some_IM",
'deletetab',"AdvancedTabs.pl&DeleteTab",
'delpmfolder',"MyCenter.pl&AddFolder",
'dereferer',"Subs.pl&Dereferer",
'display',"Display.pl&Display",
'downloadfile',"Downloads.pl&DownloadFileCouter",
'edittab2',"AdvancedTabs.pl&EditTab2",
'favorites',"MyCenter.pl&mycenter",
'findmember',"UserSelect.pl&FindMem",
'guestlang',"Subs.pl&setGuestLang",
'guestpm',"Post.pl&sendGuestPM",
'guestpm2',"Post.pl&sendGuestPM2",
'help',"HelpCentre.pl&GetHelpFiles",
'hide',"SetStatus.pl&SetStatus",
'im',"MyCenter.pl&mycenter",
'imcb',"MyCenter.pl&CallBack",
'imdraft',"MyCenter.pl&mycenter",
'imgroups',"MyCenter.pl&IMGroups",
'imlist',"UserSelect.pl&MemberList",
'imoutbox',"MyCenter.pl&mycenter",
'imprint',"Printpage.pl&Print_IM",
'imsend',"MyCenter.pl&mycenter",
'imsend2',"MyCenter.pl&mycenter",
'imshow',"MyCenter.pl&mycenter",
'imstorage',"MyCenter.pl&mycenter",
'imtostore',"MyCenter.pl&IMToStore",
'jump',"Subs.pl&dojump",
'lock',"SetStatus.pl&SetStatus",
'lockpoll',"Poll.pl&LockPoll",
'login',"LogInOut.pl&Login",
'login2',"LogInOut.pl&Login2",
'logout',"LogInOut.pl&Logout",
'markallasread',"BoardIndex.pl&MarkAllRead",
'markasread',"MessageIndex.pl&MarkRead",
'markims',"MyCenter.pl&MarkAll",
'markunread',"Display.pl&undumplog",
'memberpagedrop',"Subs.pl&MemberPageindex",
'memberpagetext',"Subs.pl&MemberPageindex",
'messageindex',"MessageIndex.pl&MessageIndex",
'messagepagedrop',"MessageIndex.pl&MessagePageindex",
'messagepagetext',"MessageIndex.pl&MessagePageindex",
'ml',"Memberlist.pl&Ml",
'modalert',"Post.pl&modAlert",
'modalert2',"Post.pl&modAlert2",
'modify',"ModifyMessage.pl&ModifyMessage",
'modify2',"ModifyMessage.pl&ModifyMessage2",
'multiadmin',"RemoveTopic.pl&Multi",
'multidel',"ModifyMessage.pl&MultiDel",
'multiremfav',"Favorites.pl&MultiRemFav",
'mycenter',"MyCenter.pl&mycenter",
'myprofile',"MyCenter.pl&mycenter",
'myprofile2',"MyCenter.pl&mycenter",
'myprofileAdmin',"MyCenter.pl&mycenter",
'myprofileAdmin2',"MyCenter.pl&mycenter",
'myprofileBuddy',"MyCenter.pl&mycenter",
'myprofileBuddy2',"MyCenter.pl&mycenter",
'myprofileContacts',"MyCenter.pl&mycenter",
'myprofileContacts2',"MyCenter.pl&mycenter",
'myprofileIM',"MyCenter.pl&mycenter",
'myprofileIM2',"MyCenter.pl&mycenter",
'myprofileOptions',"MyCenter.pl&mycenter",
'myprofileOptions2',"MyCenter.pl&mycenter",
'myusersrecentposts',"MyCenter.pl&mycenter",
'myviewprofile',"MyCenter.pl&mycenter",
'newpmfolder',"MyCenter.pl&AddFolder",
'next',"Display.pl&NextPrev",
'notify2',"Notify.pl&Notify2",
'notify3',"Notify.pl&Notify3",
'notify4',"MyCenter.pl&mycenter",
'pages',"MessageIndex.pl&ListPages",
'palette',"Palette.pl&ColorPicker",
'pmpagedrop',"MyCenter.pl&PmPageindex",
'pmpagetext',"MyCenter.pl&PmPageindex",
'pmsearch',"MyCenter.pl&mycenter",
'post',"Post.pl&Post",
'post2',"Post.pl&Post2",
'prev',"Display.pl&NextPrev",
'print',"Printpage.pl&Print",
'profile',"Profile.pl&ModifyProfile",
'profile2',"Profile.pl&ModifyProfile2",
'profileAdmin',"Profile.pl&ModifyProfileAdmin",
'profileAdmin2',"Profile.pl&ModifyProfileAdmin2",
'profileBuddy',"Profile.pl&ModifyProfileBuddy",
'profileBuddy2',"Profile.pl&ModifyProfileBuddy2",
'profileCheck',"Profile.pl&ProfileCheck",
'profileCheck2',"Profile.pl&ProfileCheck2",
'profileContacts',"Profile.pl&ModifyProfileContacts",
'profileContacts2',"Profile.pl&ModifyProfileContacts2",
'profileIM',"Profile.pl&ModifyProfileIM",
'profileIM2',"Profile.pl&ModifyProfileIM2",
'profileOptions',"Profile.pl&ModifyProfileOptions",
'profileOptions2',"Profile.pl&ModifyProfileOptions2",
'qsearch',"UserSelect.pl&quickSearch",
'qsearch2',"UserSelect.pl&doquicksearch",
'recent',"Recent.pl&RecentPosts",
'recenttopics',"Recent.pl&RecentTopics",
'register',"Register.pl&Register",
'register2',"Register.pl&Register2",
'remfav',"Favorites.pl&RemFav",
'reminder',"LogInOut.pl&Reminder",
'reminder2',"LogInOut.pl&Reminder2",
'removethread',"RemoveTopic.pl&DeleteThread",
'reordertab',"AdvancedTabs.pl&ReorderTab",
'resetpass',"LogInOut.pl&Reminder3",
'revalidatesession',"Sessions.pl&SessionReval",
'revalidatesession2',"Sessions.pl&SessionReval2",
'RSSboard',"RSS.pl&RSS_board",
'RSSrecent',"RSS.pl&RSS_recent",
'scpoll',"Poll.pl&ShowcasePoll",
'scpolldel',"Poll.pl&DelShowcasePoll",
'search',"Search.pl&plushSearch1",
'search2',"Search.pl&plushSearch2",
'sendtopic',"SendTopic.pl&SendTopic",
'sendtopic2',"SendTopic.pl&SendTopic2",
'setgtalk',"Display.pl&SetGtalk",
'setmsn',"Display.pl&SetMsn",
'shownotify',"MyCenter.pl&mycenter",
'showvoters',"Poll.pl&votedetails",
'smilieindex',"DoSmilies.pl&SmilieIndex",
'smilieput',"DoSmilies.pl&SmiliePut",
'split_splice',"MoveSplitSplice.pl&Split_Splice",
'sticky',"SetStatus.pl&SetStatus",
'threadpagedrop',"Display.pl&ThreadPageindex",
'threadpagetext',"Display.pl&ThreadPageindex",
'undovote',"Poll.pl&UndoVote",
'usersrecentposts',"Profile.pl&usersrecentposts",
'viewdownloads',"Downloads.pl&DownloadView",
'viewprofile',"Profile.pl&ViewProfile",
'vote',"Poll.pl&DoVote",
);

1;