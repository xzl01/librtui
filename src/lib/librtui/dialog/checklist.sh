#!/usr/bin/env bash

# shellcheck disable=SC2120
checklist_init() {
	__parameter_count_check 0 "$@"

	export RTUI_CHECKLIST=()
	export RTUI_CHECKLIST_VALUE=()
	export RTUI_CHECKLIST_STATE_OLD=()
	export RTUI_CHECKLIST_STATE_NEW=()
}

checklist_add() {
	local title="$1"
	local status="$2"
	local tag="$((${#RTUI_CHECKLIST[@]} / 3))"
	local value="${3:-$title}"

	__parameter_value_check "$status" "ON" "OFF"

	RTUI_CHECKLIST+=("$tag" "$title" "$status")
	RTUI_CHECKLIST_VALUE+=("$value")

	if [[ $status == "ON" ]]; then
		RTUI_CHECKLIST_STATE_OLD+=("$tag")
	fi
}

checklist_show() {
	__parameter_count_check 1 "$@"

	if ((${#RTUI_CHECKLIST[@]} == 0)); then
		return 2
	fi

	local output i
	if output="$(__dialog --checklist "$1" "${RTUI_CHECKLIST[@]}")"; then
		read -r -a RTUI_CHECKLIST_STATE_NEW <<<"$output"
		for i in $(seq 2 3 ${#RTUI_CHECKLIST[@]}); do
			RTUI_CHECKLIST[i]="OFF"
		done
		for i in "${RTUI_CHECKLIST_STATE_NEW[@]}"; do
			i="${i//\"/}"
			RTUI_CHECKLIST[i * 3 + 2]="ON"
		done
	else
		return 1
	fi
}

checklist_getitem() {
	__parameter_count_check 1 "$@"

	echo "${RTUI_CHECKLIST_VALUE[${1//\"/}]}"
}

checklist_gettitle() {
	__parameter_count_check 1 "$@"

	echo "${RTUI_CHECKLIST[${i//\"/}*3+1]}"
}

checklist_emptymsg() {
	__parameter_count_check 1 "$@"

	if ((${#RTUI_CHECKLIST[@]} == 0)); then
		msgbox "$1"
	fi
}

checklist_is_selection_empty() {
	((${#RTUI_CHECKLIST_STATE_NEW[@]} == 0))
}
