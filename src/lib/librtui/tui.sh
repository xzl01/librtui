#!/usr/bin/env bash

RTUI_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=src/dialog/basic.sh
source "$RTUI_DIR/dialog/basic.sh"
# shellcheck source=src/dialog/menu.sh
source "$RTUI_DIR/dialog/menu.sh"
# shellcheck source=src/dialog/checklist.sh
source "$RTUI_DIR/dialog/checklist.sh"
# shellcheck source=src/dialog/radiolist.sh
source "$RTUI_DIR/dialog/radiolist.sh"
# shellcheck source=src/dialog/select.sh
source "$RTUI_DIR/dialog/select.sh"
# shellcheck source=src/dialog/modal_dialog.sh
source "$RTUI_DIR/dialog/modal_dialog.sh"

# shellcheck source=src/utils/utils.sh
source "$RTUI_DIR/utils/utils.sh"

RTUI_SCREEN=()

register_screen() {
	__parameter_count_check 1 "$@"
	if [[ $1 != ":" ]]; then
		__parameter_type_check "$1" "function"
	fi

	RTUI_SCREEN+=("$1")
}

# shellcheck disable=SC2120
unregister_screen() {
	__parameter_count_check 0 "$@"

	RTUI_SCREEN=("${RTUI_SCREEN[@]:0:$((${#RTUI_SCREEN[@]} - 1))}")
}

push_screen() {
	__parameter_count_check 1 "$@"

	register_screen "$1"
	register_screen ":"
}

switch_screen() {
	__parameter_count_check 1 "$@"

	unregister_screen
	push_screen "$1"
}

tui_start() {
	__parameter_count_range_check 1 2 "$@"
	__parameter_type_check "$1" "function"

	if ! infocmp "$TERM" &>/dev/null; then
		echo "Could not find terminfo for $TERM." >&2
		return 1
	fi

	if [[ -n "${2:-}" ]]; then
		RTUI_DIALOG_TITLE="$2"
	fi

	register_screen "$1"
	while ((${#RTUI_SCREEN[@]} != 0)); do
		${RTUI_SCREEN[-1]}
		unregister_screen
	done
}
