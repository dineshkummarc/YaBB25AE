###############################################################################
# Settings_Security.pl                                                        #
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

$settings_securityplver = 'YaBB 2.5 AE $Revision: 1.16 $';
if ($action eq 'detailedversion') { return 1; }

&LoadLanguage('Sessions');

if ($regcheck) {
	require "$sourcedir/Decoder.pl";
	&validation_code;
}

# List of settings
@settings = (
{
	name  => $settings_txt{'generalsec'},
	id    => 'flood',
	items => [
		{
			description => qq~<label for="stealthurl">$dereftxt{'2'}<br /><span class="small">$dereftxt{'4'}</span></label>~,
			input_html => qq~<input type="checkbox" name="stealthurl" id="stealthurl" value="1"${ischecked($stealthurl)} />~,
			name => 'stealthurl',
			validate => 'boolean',
		},
		{
			description => qq~<label for="sessions">$session_txt{'1'}<br /><span class="small">$session_txt{'2'}</span></label>~,
			input_html => qq~<input type="checkbox" name="sessions" id="sessions" value="1"${ischecked($sessions)} />~,
			name => 'sessions',
			validate => 'boolean',
		},
		{
			description => qq~<label for="do_scramble_id">$admin_txt{'110'}<br /><span class="small">$admin_txt{'111'}</span></label>~,
			input_html => qq~<input type="checkbox" name="do_scramble_id" id="do_scramble_id" value="1"${ischecked($do_scramble_id)} />~,
			name => 'do_scramble_id',
			validate => 'boolean',
		},
		{
			description => qq~<label for="referersecurity">$reftxt{'8'}</label>~,
			input_html => qq~<input type="checkbox" name="referersecurity" id="referersecurity" value="1"${ischecked($referersecurity)} />~,
			name => 'referersecurity',
			validate => 'boolean',
		},
		{
			description => qq~<label for="show_online_ip_admin">$admin_txt{'show_ip_admin'}</label>~,
			input_html => qq~<input type="checkbox" name="show_online_ip_admin" id="show_online_ip_admin" value="1"${ischecked($show_online_ip_admin)} />~,
			name => 'show_online_ip_admin',
			validate => 'boolean',
		},
		{
			description => qq~<label for="show_online_ip_gmod">$admin_txt{'show_ip_gmod'}</label>~,
			input_html => qq~<input type="checkbox" name="show_online_ip_gmod" id="show_online_ip_gmod" value="1"${ischecked($show_online_ip_gmod)} />~,
			name => 'show_online_ip_gmod',
			validate => 'boolean',
		},
	],
},
{
	name  => $settings_txt{'validimage'},
	id    => 'validimage',
	items => [
		{
			description => qq~<label for="regcheck">$floodtxt{'2'}</label>~,
			input_html => qq~<input type="checkbox" name="regcheck" id="regcheck" value="1"${ischecked($regcheck)} />~,
			name => 'regcheck',
			validate => 'boolean',
		},
		{
			description => qq~<label for="gpvalid_en">$floodtxt{'3'}</label>~,
			input_html => qq~<input type="checkbox" name="gpvalid_en" id="gpvalid_en" value="1"${ischecked($gpvalid_en)} />~,
			name => 'gpvalid_en',
			validate => 'boolean',
		},
		{
			description => qq~<label for="translayer">$floodtxt{'9'}</label>~,
			input_html => qq~<input type="checkbox" name="translayer" id="translayer" value="1"${ischecked($translayer)} />~,
			name => 'translayer',
			validate => 'boolean',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="codemaxchars">$floodtxt{'7'}</label>~,
			input_html => qq~<input type="text" name="codemaxchars" id="codemaxchars" size="5" value="$codemaxchars" />~,
			name => 'codemaxchars',
			validate => 'number',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="captchastyle">$floodtxt{'style'}</label>~,
			input_html => qq~<select name="captchastyle" id="captchastyle" size="1"> 
			<option value="L"${isselected($captchastyle eq "L")}>$floodtxt{'lower'}</option> 
			<option value="U"${isselected($captchastyle eq "U")}>$floodtxt{'upper'}</option> 
			<option value="A"${isselected($captchastyle eq "A")}>$floodtxt{'all'}</option> 
			</select>~,
			name => 'captchastyle',
			validate => 'text',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="masterkey">$floodtxt{'masterkey'}</label>~,
			input_html => qq~<input type="text" name="masterkey" id="masterkey" maxlength="24" size="50" value="$masterkey" />~,
			name => 'masterkey',
			validate => 'text',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="rgb_foreground">$floodtxt{'f'}</label>~,
			input_html => qq~<input type="text" name="rgb_foreground" id="rgb_foreground" maxlength="7" size="7" value="$rgb_foreground" onkeyup="previewColor(this.value);" /> <span id="rgb_foreground2" style="background-color:$rgb_foreground">&nbsp; &nbsp; &nbsp;</span> <img align="top" src="$defaultimagesdir/palette1.gif" style="cursor: pointer" onclick="window.open('$scripturl?action=palette;task=templ', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" border="0" />
			<script language="JavaScript1.2" type="text/javascript">
			<!--
			function previewColor(color) {
				document.getElementById('rgb_foreground2').style.background = color;
				document.getElementsByName("rgb_foreground")[0].value = color;
			}
			//-->
			</script>~,
			name => 'rgb_foreground',
			validate => 'text',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="rgb_shade">$floodtxt{'s'}</label>~,
			input_html => qq~<input type="text" name="rgb_shade" id="rgb_shade" maxlength="7" size="7" value="$rgb_shade" onkeyup="previewColor_0(this.value);" /> <span id="rgb_shade2" style="background-color:$rgb_shade">&nbsp; &nbsp; &nbsp;</span> <img align="top" src="$defaultimagesdir/palette1.gif" style="cursor: pointer" onclick="window.open('$scripturl?action=palette;task=templ_0', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" border="0" />
			<script language="JavaScript1.2" type="text/javascript">
			<!--
			function previewColor_0(color0) {
				document.getElementById('rgb_shade2').style.background = color0;
				document.getElementsByName("rgb_shade")[0].value = color0;
			}
			//-->
			</script>~,
			name => 'rgb_shade',
			validate => 'text',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="rgb_background">$floodtxt{'b'}</label>~,
			input_html => qq~<input type="text" name="rgb_background" id="rgb_background" maxlength="7" size="7" value="$rgb_background" onkeyup="previewColor_1(this.value);" /> <span id="rgb_background2" style="background-color:$rgb_background">&nbsp; &nbsp; &nbsp;</span> <img align="top" src="$defaultimagesdir/palette1.gif" style="cursor: pointer" onclick="window.open('$scripturl?action=palette;task=templ_1', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" border="0" />
			<script language="JavaScript1.2" type="text/javascript">
			<!--
			function previewColor_1(color1) {
				document.getElementById('rgb_background2').style.background = color1;
				document.getElementsByName("rgb_background")[0].value = color1;
			}
			//-->
			</script>~,
			name => 'rgb_background',
			validate => 'text',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="randomizer">$floodtxt{'rnd'}</label>~,
			input_html => qq~<select name="randomizer" id="randomizer" size="1"> <option value="0"${isselected($randomizer == 0)}>$floodtxt{'rm0'}</option> <option value="1"${isselected($randomizer == 1)}>$floodtxt{'rm1'}</option> <option value="2"${isselected($randomizer == 2)}>$floodtxt{'rm2'}</option> <option value="3"${isselected($randomizer == 3)}>$floodtxt{'rm3'}</option> </select>~,
			name => 'randomizer',
			validate => 'number',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => qq~<label for="distortion">$floodtxt{'dis'}</label>~,
			input_html => qq~<select name="distortion" id="distortion" size="1"> 
			<option value="0"${isselected($distortion == 0)}>0</option> 
			<option value="1"${isselected($distortion == 1)}>1</option> 
			<option value="2"${isselected($distortion == 2)}>2</option> 
			<option value="3"${isselected($distortion == 3)}>3</option> 
			<option value="4"${isselected($distortion == 4)}>4</option> 
			<option value="5"${isselected($distortion == 5)}>5</option> 
			<option value="6"${isselected($distortion == 6)}>6</option> 
			<option value="7"${isselected($distortion == 7)}>7</option> 
			<option value="8"${isselected($distortion == 8)}>8</option> 
			<option value="9"${isselected($distortion == 9)}>9</option> 
			</select>~,
			name => 'distortion',
			validate => 'number',
			depends_on => ['regcheck||', 'gpvalid_en||'],
		},
		{
			description => $floodtxt{'vpreview'},
			input_html => qq~<div class="windowbg" style="padding: 5px;">$showcheck</div>~,
		},
	],
},
);

# Routine to save them
sub SaveSettings {
	my %settings = @_;

	if (length $settings{'masterkey'} < 8 || length $settings{'masterkey'} > 24) {
		&LoadLanguage('Error');
		&admin_fatal_error("invalid_key");
	}

	&SaveSettingsTo('Settings.pl', %settings);
}

1;