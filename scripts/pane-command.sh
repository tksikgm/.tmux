#!/usr/bin/env bash
# Read Linux /proc directly; avoid starting Python on every status update.
name=${2:-?}
pane_pid=${1:-}
if [[ $pane_pid =~ ^[0-9]+$ ]] && IFS= read -r stat_line 2>/dev/null < "/proc/$pane_pid/stat"; then
  # Fields after the final ')' start at state (field 3); tpgid is field 8.
  read -r -a fields <<< "${stat_line##*) }"
  process_pid=${fields[5]}
  [[ $process_pid =~ ^[1-9][0-9]*$ ]] || process_pid=$pane_pid
  args=()
  if [[ -r /proc/$process_pid/cmdline ]]; then
    mapfile -d '' -t args < "/proc/$process_pid/cmdline"
  fi
  if [[ ${args[0]:-} ]]; then
    name=${args[0]##*/}
    if [[ $name =~ ^python([0-9]+(\.[0-9]+)*)?$ ]]; then
      for ((index=1; index<${#args[@]}; index++)); do
        arg=${args[index]}
        case $arg in
          -m) name=${args[index+1]:-$name}; break ;;
          -c|-) break ;;
          -W|-X) ((index++)) ;;
          --) name=${args[index+1]:-$name}; name=${name##*/}; break ;;
          -*) ;;
          *) name=${arg##*/}; break ;;
        esac
      done
    fi
  fi
fi
# Avoid injecting tmux format/style sequences or control characters.
name=${name//#/}
name=${name//[[:cntrl:]]/}
printf '%s\n' "$name"
