#!/usr/bin/env bash
# AI-GENERATED #

set -Eeuo pipefail

usage() {
    echo "Usage: $0 MOD_NAME [--lua-compiler COMMAND] [--lua-linter COMMAND] [--ue4ss-mods-path PATH]" >&2
}

die() {
    echo "Error: $*" >&2
    exit 1
}

load_game_path() {
    local env_file="$repo_root/.env"
    if [[ -z ${EOA_GAME_PATH:-} ]]; then
        [[ -f $env_file ]] || die "EOA_GAME_PATH is not set. Export it or copy .env.example to .env and configure it."
        # The local file is trusted project configuration and uses shell assignment syntax.
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
    fi
    [[ -n ${EOA_GAME_PATH:-} ]] || die "EOA_GAME_PATH is not set in $env_file."
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi
[[ $# -ge 1 ]] || { usage; exit 2; }

mod_name=$1
shift
lua_compiler=luac
lua_linter=luacheck
ue4ss_mods_path=

while [[ $# -gt 0 ]]; do
    case $1 in
        --lua-compiler)
            [[ $# -ge 2 && -n $2 ]] || die "--lua-compiler requires a value."
            lua_compiler=$2; shift 2 ;;
        --lua-linter)
            [[ $# -ge 2 && -n $2 ]] || die "--lua-linter requires a value."
            lua_linter=$2; shift 2 ;;
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
    die "MOD_NAME must be a directory name, not a path: $mod_name"

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd -- "$script_dir/../.." && pwd -P)

if [[ -z $ue4ss_mods_path ]]; then
    load_game_path
    ue4ss_mods_path="$EOA_GAME_PATH/EchoesofAincrad/Binaries/Win64/ue4ss/Mods"
fi

build_script_path="$script_dir/build.sh"
packaged_mod_path="$repo_root/dist/$mod_name"
installed_mod_path="$ue4ss_mods_path/$mod_name"
mods_txt_path="$ue4ss_mods_path/mods.txt"

[[ -x $build_script_path ]] || die "Build script is missing or not executable: $build_script_path"
[[ -d $ue4ss_mods_path ]] || die "UE4SS Mods directory does not exist: $ue4ss_mods_path"
[[ -f $mods_txt_path ]] || die "mods.txt does not exist: $mods_txt_path"

"$build_script_path" "$mod_name" --lua-compiler "$lua_compiler" --lua-linter "$lua_linter"
[[ -f $packaged_mod_path/Scripts/main.lua ]] || die "Build did not produce a valid mod package: $packaged_mod_path"

if [[ -e $installed_mod_path ]]; then
    echo "Removing the existing $mod_name installation..."
    rm -rf -- "$installed_mod_path"
fi

echo "Installing $mod_name from dist..."
cp -a -- "$packaged_mod_path" "$ue4ss_mods_path/"
echo "Installed package:"
echo "  $packaged_mod_path"
echo "    -> $installed_mod_path"

tmp_file=$(mktemp --tmpdir="$ue4ss_mods_path" '.mods.txt.XXXXXX')
cleanup() { rm -f -- "$tmp_file"; }
trap cleanup EXIT

awk -v mod="$mod_name" '
    BEGIN { found = 0 }
    {
        line = $0
        sub(/\r$/, "", line)
        split(line, fields, ":")
        name = fields[1]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
        if (!found && name == mod) {
            print mod " : 1"
            found = 1
        } else {
            print line
        }
    }
    END { if (!found) print mod " : 1" }
' "$mods_txt_path" > "$tmp_file"

if cmp -s -- "$mods_txt_path" "$tmp_file"; then
    echo "$mod_name is already enabled in mods.txt."
else
    chmod --reference="$mods_txt_path" "$tmp_file"
    mv -f -- "$tmp_file" "$mods_txt_path"
    trap - EXIT
    echo "Enabled $mod_name in mods.txt."
fi

echo
echo "Done."
