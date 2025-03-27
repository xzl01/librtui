#!/usr/bin/env bash

readonly RTUI_PALETTE_ERROR="error"

RTUI_DIALOG=${RTUI_DIALOG:-"whiptail"}
RTUI_DIALOG_TITLE=${RTUI_DIALOG_TITLE:-"RTUI"}

__dialog() {
	local box="$1" text="$2" height width listheight
	shift 2
	height="$(__check_terminal | cut -d ' ' -f 1)"
	width="$(__check_terminal | cut -d ' ' -f 2)"
	case $box in
	--menu)
		listheight=0
		;;
	--checklist | --radiolist)
		listheight=$((height - 8))
		;;
	--infobox)
		height=$((height - 1))
		;;
	esac

	if ((height < 8)); then
		echo "TTY height needs to be at least 8 for TUI mode to work, currently is '$height'." >&2
		return 1
	fi

	if $DEBUG; then
		local backtitle=("--backtitle" "${RTUI_SCREEN[*]}")
	else
		local backtitle=()
	fi

	$RTUI_DIALOG --title "$RTUI_DIALOG_TITLE" ${backtitle:+"${backtitle[@]}"} --notags \
		"$box" "$text" "$height" "$width" ${listheight:+"$listheight"} \
		"$@" 3>&1 1>&2 2>&3 3>&-
}

librtui_set_palette() {
	local palette="$RTUI_DIR/../../share/librtui/"${1:-}".palette"

	if [[ -z ${1:-} ]]; then
		unset NEWT_COLORS_FILE
	elif [[ -e "$palette" ]]; then
		export NEWT_COLORS_FILE="$palette"
	else
		echo "Palette file '$1' does not exist." >&2
		return 1
	fi
}

show_once() {
	__parameter_count_at_least_check 2 "$@"
	__parameter_type_check "$2" "function"

	local first_run="$1"
	shift

	eval "$first_run=\"\${$first_run:-true}\""

	if eval "[[ \"\$$first_run\" == \"true\" ]]" && ! "$@"; then
		return 1
	else
		eval "$first_run=\"false\""
		return 0
	fi
}

yesno() {
	__parameter_count_check 1 "$@"

	__dialog --yesno "$1"
}

msgbox() {
	__parameter_count_range_check 1 2 "$@"

	librtui_set_palette "${2:-}"
	__dialog --msgbox "$1"
	librtui_set_palette
}

inputbox() {
	__parameter_count_check 2 "$@"

	__dialog --inputbox "$1" "$2"
}

passwordbox() {
	__parameter_count_check 1 "$@"

	__dialog --passwordbox "$1"
}

gauge() {
	__parameter_count_check 2 "$@"

	__dialog --gauge "$1" "$2"
}

infobox() {
	__parameter_count_check 1 "$@"

	# TERM cannot be xterm as described in https://stackoverflow.com/a/15192893
	TERM=linux __dialog --infobox "$1"
}
