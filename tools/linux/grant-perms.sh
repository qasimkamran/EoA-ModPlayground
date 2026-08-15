#!/usr/bin/env bash
# AI-GENERATED #

set -Eeuo pipefail

usage() {
    echo "Usage: $0 [--mod-name NAME] [--user USER] [--ue4ss-mods-path PATH]" >&2
}

die() {
    echo "Error: $*" >&2
    exit 1
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd -- "$script_dir/../.." && pwd -P)
mod_name=02-MenuExtension
target_user=$(id -un)
ue4ss_mods_path=

while [[ $# -gt 0 ]]; do
    case $1 in
        --mod-name)
            [[ $# -ge 2 && -n $2 ]] || die "--mod-name requires a value."
            mod_name=$2; shift 2 ;;
        --user)
            [[ $# -ge 2 && -n $2 ]] || die "--user requires a value."
            target_user=$2; shift 2 ;;
        --ue4ss-mods-path)
            [[ $# -ge 2 && -n $2 ]] || die "--ue4ss-mods-path requires a value."
            ue4ss_mods_path=$2; shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            die "Unknown argument: $1" ;;
    esac
done

[[ -n $mod_name && $mod_name != . && $mod_name != .. && $mod_name != */* ]] ||
    die "Mod name must be a directory name, not a path: $mod_name"
id "$target_user" >/dev/null 2>&1 || die "User does not exist: $target_user"

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

logs_path="$ue4ss_mods_path/$mod_name/logs"
mkdir -p -- "$logs_path"

echo "Granting read/write permission to '$target_user' on:"
echo "  $logs_path"

if command -v setfacl >/dev/null 2>&1; then
    setfacl -R -m "u:$target_user:rwX" -- "$logs_path"
    while IFS= read -r -d '' directory; do
        setfacl -m "d:u:$target_user:rwX" -- "$directory"
    done < <(find "$logs_path" -type d -print0)
elif [[ $target_user == "$(id -un)" ]]; then
    chmod -R u+rwX -- "$logs_path"
else
    die "setfacl is required to grant permissions to another user. Install the Linux 'acl' package."
fi

echo "Permissions granted successfully."
