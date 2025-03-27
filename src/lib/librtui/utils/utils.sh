#!/usr/bin/env bash

if [[ -z ${ERROR_REQUIRE_PARAMETER+SET} ]]; then
	readonly ERROR_REQUIRE_PARAMETER=-1
fi
if [[ -z ${ERROR_TOO_FEW_PARAMETERS+SET} ]]; then
	readonly ERROR_TOO_FEW_PARAMETERS=-2
fi
if [[ -z ${ERROR_REQUIRE_FILE+SET} ]]; then
	readonly ERROR_REQUIRE_FILE=-3
fi
if [[ -z ${ERROR_ILLEGAL_PARAMETERS+SET} ]]; then
	readonly ERROR_ILLEGAL_PARAMETERS=-4
fi
if [[ -z ${ERROR_REQUIRE_TARGET+SET} ]]; then
	readonly ERROR_REQUIRE_TARGET=-5
fi

__require_parameter_check() {
	if (($# == 0)); then
		echo "Incorrect usage of ${FUNCNAME[1]} from ${FUNCNAME[2]}: ${FUNCNAME[1]} requires parameter" >&2
		return $ERROR_REQUIRE_PARAMETER
	fi
}

__parameter_count_at_least_check() {
	__require_parameter_check "$@"

	local lower=$1
	shift
	if (($# < lower)); then
		echo "'${FUNCNAME[1]}' expects at least '$lower' parameters while getting $#: '$*'" >&2
		return $ERROR_TOO_FEW_PARAMETERS
	fi
}

__parameter_count_at_most_check() {
	__require_parameter_check "$@"

	local upper=$1
	shift
	if (($# > upper)); then
		echo "'${FUNCNAME[1]}' expects at most '$upper' parameters while getting $#: '$*'" >&2
		return $ERROR_TOO_FEW_PARAMETERS
	fi
}

__parameter_count_range_check() {
	__require_parameter_check "$@"

	local lower=$1 upper=$2
	shift 2
	__parameter_count_at_least_check "$lower" "$@"
	__parameter_count_at_most_check "$upper" "$@"
}

__parameter_count_check() {
	__require_parameter_check "$@"

	local expected=$1
	shift
	__parameter_count_range_check "$expected" "$expected" "$@"
}

__assert_f() {
	__parameter_count_check 1 "$@"

	if [[ ! -e $1 ]]; then
		echo "'${FUNCNAME[1]}' requires file '$1' to work!" >&2
		return $ERROR_REQUIRE_FILE
	fi
}

__assert_t() {
	__parameter_count_check 1 "$@"

	if [[ ! -e $1 ]]; then
		echo "'${FUNCNAME[1]}' requires target '$1' to work!" >&2
		return $ERROR_REQUIRE_TARGET
	fi
}

__external_script_type_check() {
	__parameter_count_check 3 "$@"
	__assert_f "$1"

	bash -c "source /usr/lib/librtui/utils/utils.sh && source '$1' && __parameter_type_check '$2' '$3'"
}

__parameter_value_check() {
	__require_parameter_check "$@"

	local option=$1
	shift 1
	local options=("$@")
	if [[ ${options[*]} != *"$option"* ]]; then
		echo "'${FUNCNAME[1]}' expects one of '${options[*]}', got '$option'" >&2
		return $ERROR_ILLEGAL_PARAMETERS
	fi
}

__parameter_type_check() {
	__parameter_count_check 2 "$@"

	if [[ $(type -t "$1") != "$2" ]]; then
		echo "'${FUNCNAME[1]}' expects '$1' type to be '$2', but it is '$(type -t "$1")'." >&2
		return $ERROR_ILLEGAL_PARAMETERS
	fi
}

__in_array() {
	local item="$1" i=0
	shift
	while (($# > 0)); do
		if [[ $item == "$1" ]]; then
			echo "$i"
			return
		fi
		i=$((i + 1))
		shift
	done
	return 1
}

__printf_array() {
	local FORMAT="$1"
	shift
	local ARRAY=("$@")

	if [[ $FORMAT == "json" ]]; then
		jq --compact-output --null-input '$ARGS.positional' --args -- "${ARRAY[@]}"
	else
		for i in "${ARRAY[@]}"; do
			# shellcheck disable=SC2059
			printf "$FORMAT" "$i"
		done
	fi
}

__array_intersect() {
	local a=() b=()
	while [[ $1 != "--" ]]; do
		a+=("$1")
		shift
	done
	shift
	b=("$@")

	local i j
	for i in "${a[@]}"; do
		for j in "${b[@]}"; do
			if [[ $i == "$j" ]]; then
				echo "$i"
			fi
		done
	done
}

__array_remove() {
	local array_name="$1" item="$2" old_array=() new_array=()
	eval "old_array=( \"\${${array_name}[@]}\" )"
	for i in "${!old_array[@]}"; do
		if [[ $item != "${old_array[i]}" ]]; then
			new_array+=("${old_array[i]}")
		fi
	done
	eval "$array_name=( \"\${new_array[@]}\" )"
}

__request_parallel() {
	local nproc
	nproc=$(($(nproc)))

	while (($(jobs -r | wc -l) > nproc)); do
		sleep 0.1
	done
}

__wait_parallel() {
	# An error aware wait
	# Based on example of https://stackoverflow.com/a/43776775
	local ret
	while ret=0; do
		wait -n || ret=$?
		case "$ret" in
		0)
			continue
			;;
		127)
			break
			;;
		*)
			wait
			return "$ret"
			;;
		esac
	done;
}

__check_terminal() {
	local devices=("/dev/stdin" "/dev/stdout" "/dev/stderr") output disable_stderr
	for i in "${devices[@]}"; do
		disable_stderr="2>&-"
		if [[ $i == "/dev/stderr" ]]; then
			disable_stderr=
		fi

		if output="$(eval "stty size -F '$i' $disable_stderr")"; then
			echo "$output"
			return
		fi
	done
	echo "Unable to get terminal size!" >&2
}

__lock_fd() {
	local file="$1" fd
	exec {fd}>>"$file"
	flock "$fd"
	LIBRTUI_LOCK_FD="$fd"
}

__try_lock_fd() {
	local file="$1" fd
	exec {fd}>>"$file"
	if ! flock -n "$fd"; then
		exec {fd}>&-
		return 1
	fi
	LIBRTUI_LOCK_FD="$fd"
}

__unlock_fd() {
	local fd="${1:-$LIBRTUI_LOCK_FD}"
	flock -u "$fd"
	exec {fd}>&-
}
