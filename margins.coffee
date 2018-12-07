################################################################################
# An Übersicht widget that dynamically sets margins around the overall Übersicht
# container in order to prevent the rest of your widgets from colliding with the
# Dock or your desktop icons.
#
# The margin sizes are set dynamically based on your Dock and desktop icon
# preferences. If you change your Dock's position, size, etc., just refresh this
# widget and the new margins will be calculated automatically. For desktop
# icons, you must manually specify how many columns of icons you want to leave
# space for, and then the widget will determine the exact size to use based on
# the icon size, grid spacing, etc. specified in your desktop view options.
#
# You may also set a default margin to use on the remaining sides of the
# display. This default margin will be combined with the dynamic margins where
# appropriate.
################################################################################

# User settings
avoid_dock = true	# Whether to keep widgets out from under the Dock
icon_columns = 0	# Number of icon columns on the right to leave space for
static_margin = 0	# Default margin, measured in px

# The custom CSS stylesheet
css: (dock_side, dock_margin, w_subtract, h_subtract) ->
	return """

/* The main Übersicht container */
#__uebersicht {

	/* Nudge all widgets away from the edges of the display */
	margin: #{static_margin}px;

	/* Keep widgets out from under the Dock */
	margin-#{dock_side}: #{dock_margin}px;

	/* Set width and height based on above margins */
	width: calc(100% - #{w_subtract}px);
	height: calc(100% - #{h_subtract}px);

	/* If a widget really wants to push outside the margins, allow that */
	overflow: visible;
}

"""

# This command determines the correct margin, width, and height values
command: """
if #{avoid_dock}; then
	declare -i dock_shown
	dock_shown=!$(defaults read com.apple.dock autohide)
	dock_side="$(defaults read com.apple.dock orientation)"
	dock_margin="$(echo "scale=0; $dock_shown * ($(defaults read com.apple.dock tilesize) + 14 + ($(defaults read com.apple.dock tilesize)/20))/1 + #{static_margin}" | bc)"
else
	dock_side=bottom
	dock_margin=#{static_margin}
fi

if [[ #{icon_columns} -gt 0 ]]; then
	grid_spacing=$(defaults read com.apple.finder DesktopViewSettings | grep -Eo 'gridSpacing = [[:digit:]]+' | grep -Eo '[[:digit:]]+')
	icon_size=$(defaults read com.apple.finder DesktopViewSettings | grep -Eo 'iconSize = [[:digit:]]+' | grep -Eo '[[:digit:]]+')
	label_on_bottom=$(defaults read com.apple.finder DesktopViewSettings | grep -Eo 'labelOnBottom = [[:digit:]]+' | grep -Eo '[[:digit:]]+')

	if [[ $label_on_bottom == 1 ]]; then
		min_width=$(echo "scale=0; ($icon_size * 1.2 + 8)/1" | bc)
		col_width=$(echo "scale=0; ((150 * ($grid_spacing * 0.01)) + 46)/1" | bc)
		[[ $col_width -lt $min_width ]] && col_width=$min_width
	else
		col_width=$(echo "scale=0; ((150 * ($grid_spacing * 0.01)) + 46 + ($icon_size * 1.2))/1" | bc)
	fi

	col_width=$((#{icon_columns} * $col_width - #{static_margin}))
else
	col_width=0
fi

if [[ "$dock_side" == 'left' || "$dock_side" == 'right' ]]; then
	w_subtract=$((#{static_margin} + $dock_margin + $col_width))
	h_subtract=$((#{static_margin} * 2))
else
	w_subtract=$((#{static_margin} * 2 + $col_width))
	h_subtract=$((#{static_margin} + $dock_margin))
fi

echo "$dock_side"
echo "$dock_margin"
echo "$w_subtract"
echo "$h_subtract"
"""

render: (output) ->
	args = output.split("\n");
	return '<style>' + @css(args...) + '</style>'

refreshFrequency: false
