# shellcheck shell=bash
function jobs() {
  # Find the PID of a process by name
  find_pid() {
    local pid
    pid=$(pgrep -x "$1")
    if [[ -n "$pid" ]]; then
      echo "$pid"
    else
      echo "Process not found: $1"
      exit 1
    fi
  }
  # Find a process by name and display its details
  # shellcheck disable=2317
  find_process() {
    local pid
    pid=$(find_pid "$1")
    echo "Process details for $1 (PID $pid):"
    ps -p "$pid" -o pid,ppid,cmd,state
  }

  # Suspend a process by name
  suspend_process() {
    local pid
    pid=$(find_pid "$1")
    echo "Suspending process $1 (PID $pid)"
    kill -STOP "$pid"
  }
  # Resume a suspended process by name
  resume_process() {
    local pid
    pid=$(find_pid "$1")
    echo "Resuming process $1 (PID $pid)"
    kill -CONT "$pid"
  }
  # Terminate a process by name
  terminate_process() {
    local pid
    pid=$(find_pid "$1")
    echo "Terminating process $1 (PID $pid)"
    kill "$pid"
  }
  # Prompt the user to enter a process name and operation to perform
  local option="$1"
  local process_name="$2"

  # Call the appropriate function based on the user's input
  case "$option" in
  suspend)
    suspend_process "$process_name"
    ;;
  resume)
    resume_process "$process_name"
    ;;
  terminate)
    terminate_process "$process_name"
    ;;
  *)
    print "jobs <suspend | resume | terminate> <name>"
    ;;
  esac
}
