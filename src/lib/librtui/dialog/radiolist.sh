#!/usr/bin/env bash

# shellcheck disable=SC2120
radiolist_init() {
	__parameter_count_check 0 "$@"

	export RTUI_RADIOLIST=()
	export RTUI_RADIOLIST_STATE_OLD=()
	export RTUI_RADIOLIST_STATE_NEW=()
}

radiolist_add() {
	__parameter_count_check 2 "$@"

	local item=$1
	local status=$2
	local tag="$((${#RTUI_RADIOLIST[@]} / 3))"

	__parameter_value_check "$status" "ON" "OFF"

	RTUI_RADIOLIST+=("$tag" "$item" "$status")

	if [[ $status == "ON" ]]; then
		RTUI_RADIOLIST_STATE_OLD+=("$tag")
	fi
}

radiolist_show() {
	__parameter_count_check 1 "$@"

	if ((${#RTUI_RADIOLIST[@]} == 0)); then
		return 2
	fi

	local output i
	if output="$(__dialog --radiolist "$1" "${RTUI_RADIOLIST[@]}")"; then
		read -r -a RTUI_RADIOLIST_STATE_NEW <<<"$output"
		for i in $(seq 2 3 ${#RTUI_RADIOLIST[@]}); do
			RTUI_RADIOLIST[i]="OFF"
		done
		for i in "${RTUI_CHECKLIST_STATE_NEW[@]}"; do
			i="${i//\"/}"
			RTUI_RADIOLIST[i * 3 + 2]="ON"
		done
	else
		return 1
	fi
}

radiolist_getitem() {
	__parameter_count_check 1 "$@"

	echo "${RTUI_RADIOLIST[$((${1//\"/} * 3 + 1))]}"
}

radiolist_emptymsg() {
	__parameter_count_check 1 "$@"

	if ((${#RTUI_RADIOLIST[@]} == 0)); then
		msgbox "$1"
	fi
}

radiolist_is_selection_empty() {
	((${#RTUI_RADIOLIST_STATE_NEW[@]} == 0))
}
