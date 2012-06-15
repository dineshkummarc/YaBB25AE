###############################################################################
# Settings_Maintenance.pl                                                     #
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

$settings_maintenanceplver = 'YaBB 2.5 AE $Revision: 1.5 $';
if ($action eq 'detailedversion') { return 1; }

# List of settings
@settings = (
# Begin tab
{
	name  => $admin_txt{'67'}, # Tab name
	id    => 'settings', # Javascript ID
	items => [
		{
			description => qq~<label for="maintenance">$admin_txt{'348'}</label>~,
			input_html => qq~<input type="checkbox" name="maintenance" id="maintenance" value="1" ${ischecked($maintenance)}/>~,
			name => 'maintenance',
			validate => 'boolean',
		},
		{
			description => qq~<label for="maintenancetext">$admin_txt{'348Text'}</label>~,
			input_html => qq~<textarea cols="30" rows="5" name="maintenancetext" id="maintenancetext" style="width: 98%">$maintenancetext</textarea>~,
			name => 'maintenancetext',
			validate => 'fulltext,null',
		},
	],
});

# Routine to save them
sub SaveSettings {
	my %settings = @_;

	if ($settings{'maintenance'} != 1) {
		unlink "$vardir/maintenance.lock" || &admin_fatal_error('cannot_open_dir', "$vardir/maintenance.lock");
	}

	SaveSettingsTo('Settings.pl', %settings);
}

1;