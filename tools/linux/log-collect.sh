#!/usr/bin/env bash
# AI-GENERATED #

set -Eeuo pipefail

usage() {
    echo "Usage: $0 [--ue4ss-mods-path PATH] [--game-process-name NAME] [--central-logs-path PATH] [--no-wait]" >&2
}

die() {
    echo "Error: $*" >&2
    exit 1
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd -- "$script_dir/../.." && pwd -P)
ue4ss_mods_path=
game_process_name=EchoesofAincrad
central_logs_path="$repo_root/logs"
no_wait=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ue4ss-mods-path)
            [[ $# -ge 2 && -n $2 ]] || die "--ue4ss-mods-path requires a value."
            ue4ss_mods_path=$2; shift 2 ;;
        --game-process-name)
            [[ $# -ge 2 && -n $2 ]] || die "--game-process-name requires a value."
            game_process_name=$2; shift 2 ;;
        --central-logs-path)
            [[ $# -ge 2 && -n $2 ]] || die "--central-logs-path requires a value."
            central_logs_path=$2; shift 2 ;;
        --no-wait)
            no_wait=true; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            die "Unknown argument: $1" ;;
    esac
done

if [[ -z $ue4ss_mods_path ]]; then
    env_file="$repo_root/.env"
    if [[ -z ${EOA_GAME_PATH:-} ]]; then
        [[ -f $env_file ]] || die "EOA_GAME_PATH is not set. Export it or copy .env.example to .env and configure it."
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
    fi
    [[ -n ${EOA_GAME_PATH:-} ]] || die "EOA_GAME_PATH is not set in $env_file."
    ue4ss_mods_path="$EOA_GAME_PATH/EchoesofAincrad/Binaries/Win64/ue4ss/Mods"
fi

[[ -d $ue4ss_mods_path ]] || die "UE4SS Mods directory does not exist: $ue4ss_mods_path"

if [[ $no_wait == false ]] && pgrep -x -- "$game_process_name" >/dev/null 2>&1; then
    echo "Waiting for $game_process_name to exit..."
    while pgrep -x -- "$game_process_name" >/dev/null 2>&1; do
        sleep 1
    done
fi

mkdir -p -- "$central_logs_path"
ue4ss_root_path=$(dirname -- "$ue4ss_mods_path")
ue4ss_log_path="$ue4ss_root_path/UE4SS.log"

if [[ -f $ue4ss_log_path ]]; then
    runtime_log_timestamp=$(date -r "$ue4ss_log_path" '+%Y-%m-%d_%H-%M-%S')
    runtime_log_destination="$central_logs_path/UE4SS-$runtime_log_timestamp.log"
    cp -f -- "$ue4ss_log_path" "$runtime_log_destination"
    echo "Collected UE4SS runtime log -> $runtime_log_destination"
else
    echo "Warning: UE4SS runtime log was not found: $ue4ss_log_path" >&2
fi

incoming_path="$central_logs_path/.incoming"
mkdir -p -- "$incoming_path"
moved_count=0
collected_count=0

while IFS= read -r -d '' mod_directory; do
    mod_logs_path="$mod_directory/logs"
    [[ -d $mod_logs_path ]] || continue
    mod_name=$(basename -- "$mod_directory")
    safe_mod_name=${mod_name//[^A-Za-z0-9._-]/_}

    while IFS= read -r -d '' log_file; do
        log_name=$(basename -- "$log_file")
        log_base=${log_name%.log}
        unique_id=$(tr -d '-' < /proc/sys/kernel/random/uuid)
        staged_path="$incoming_path/$safe_mod_name--$log_base--$unique_id.log"

        mv -- "$log_file" "$staged_path"
        ((moved_count += 1))
        central_log_path="$central_logs_path/$log_name"

        if ! command cat -- "$staged_path" >> "$central_log_path"; then
            die "Failed to aggregate staged log; it remains recoverable at: $staged_path"
        fi
        rm -f -- "$staged_path"
        ((collected_count += 1))
        echo "Collected $mod_name/logs/$log_name -> $central_log_path"
    done < <(find "$mod_logs_path" -maxdepth 1 -type f -name '*.log' -print0 | sort -z)
done < <(find "$ue4ss_mods_path" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

echo "Moved $moved_count log file(s) out of the game directories."
echo "Aggregated $collected_count log file(s) into:"
echo "  $central_logs_path"
