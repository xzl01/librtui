#!/usr/bin/env bash

# shellcheck disable=SC2120
menu_init() {
	__parameter_count_check 0 "$@"

	export RTUI_MENU=()
	export RTUI_MENU_CALLBACK=()
	export RTUI_MENU_SELECTED=
	export RTUI_MENU_SELECTED_INDEX=
}

menu_add() {
	__parameter_count_check 2 "$@"
	if [[ $1 != ":" ]]; then
		__parameter_type_check "$1" "function"
	fi

	local callback=$1
	local item=$2

	RTUI_MENU+=("$((${#RTUI_MENU[@]} / 2))" "$item")
	RTUI_MENU_CALLBACK+=("$callback")
}

# shellcheck disable=SC2120
menu_add_separator() {
	__parameter_count_check 0 "$@"

	menu_add : "========="
}

menu_emptymsg() {
	__parameter_count_check 1 "$@"

	if ((${#RTUI_MENU_CALLBACK[@]} == 0)); then
		msgbox "$1"
	fi
}

menu_getitem() {
	__parameter_count_check 1 "$@"

	echo "${RTUI_MENU[$((${1//\"/} * 2 + 1))]}"
}

menu_show() {
	__parameter_count_check 1 "$@"

	local item="0"
	if ((${#RTUI_MENU_CALLBACK[@]} == 1)); then
		RTUI_MENU_SELECTED="$(menu_getitem "$item")"
		RTUI_MENU_SELECTED_INDEX="$item"
		switch_screen "${RTUI_MENU_CALLBACK[$item]}"
	elif item="$(__dialog --menu "$1" "${RTUI_MENU[@]}")"; then
		RTUI_MENU_SELECTED="$(menu_getitem "$item")"
		RTUI_MENU_SELECTED_INDEX="$item"
		push_screen "${RTUI_MENU_CALLBACK[$item]}"
	fi
}

menu_call() {
	__parameter_count_check 1 "$@"

	local item
	if item="$(__dialog --menu "$1" "${RTUI_MENU[@]}")"; then
		RTUI_MENU_SELECTED="$(menu_getitem "$item")"
		RTUI_MENU_SELECTED_INDEX="$item"
		${RTUI_MENU_CALLBACK[$item]}
	else
		return 1
	fi
}
