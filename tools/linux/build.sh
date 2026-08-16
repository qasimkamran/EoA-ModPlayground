#!/usr/bin/env bash
# AI-GENERATED #

set -Eeuo pipefail

usage() {
    echo "Usage: $0 MOD_NAME [--lua-compiler COMMAND] [--lua-linter COMMAND]" >&2
}

die() {
    echo "Error: $*" >&2
    exit 1
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

while [[ $# -gt 0 ]]; do
    case $1 in
        --lua-compiler)
            [[ $# -ge 2 && -n $2 ]] || die "--lua-compiler requires a value."
            lua_compiler=$2
            shift 2
            ;;
        --lua-linter)
            [[ $# -ge 2 && -n $2 ]] || die "--lua-linter requires a value."
            lua_linter=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd -- "$script_dir/../.." && pwd -P)
mods_root="$repo_root/mods"
source_mod_path="$mods_root/$mod_name"
source_scripts_path="$source_mod_path/Scripts"
shared_lib_path="$repo_root/lib"
local_lib_path="$source_mod_path/lib"
dist_root="$repo_root/dist"
packaged_mod_path="$dist_root/$mod_name"
packaged_scripts_path="$packaged_mod_path/Scripts"
packaged_lib_path="$packaged_scripts_path/lib"

[[ -n $mod_name && $mod_name != . && $mod_name != .. && $mod_name != */* ]] ||
    die "MOD_NAME must be a directory name, not a path: $mod_name"
[[ -d $source_mod_path ]] || die "Mod does not exist: $source_mod_path"
[[ -d $source_scripts_path ]] || die "Mod is missing its Scripts directory: $source_scripts_path"
[[ -f $source_scripts_path/main.lua ]] || die "Mod is missing Scripts/main.lua: $source_mod_path"

lua_compiler_path=$(command -v -- "$lua_compiler") ||
    die "Lua compiler was not found: '$lua_compiler'. Install it or pass its path with --lua-compiler."
lua_linter_path=$(command -v -- "$lua_linter") ||
    die "Lua linter was not found: '$lua_linter'. Install it or pass its path with --lua-linter."

echo "Building $mod_name..."
mkdir -p -- "$dist_root"
rm -rf -- "$packaged_mod_path"
mkdir -p -- "$packaged_mod_path"
cp -a -- "$source_mod_path/." "$packaged_mod_path/"

if [[ -d $shared_lib_path ]]; then
    mkdir -p -- "$packaged_lib_path"
    cp -a -- "$shared_lib_path/." "$packaged_lib_path/"
fi

if [[ -d $local_lib_path ]]; then
    mkdir -p -- "$packaged_lib_path"
    cp -a -- "$local_lib_path/." "$packaged_lib_path/"
    rm -rf -- "$packaged_mod_path/lib"
fi

mapfile -d '' lua_files < <(find "$packaged_scripts_path" -type f -name '*.lua' -print0 | sort -z)
[[ ${#lua_files[@]} -gt 0 ]] || die "Package contains no Lua source files: $packaged_scripts_path"

echo "Linting ${#lua_files[@]} Lua file(s)..."
"$lua_linter_path" --codes --no-color "$packaged_scripts_path" ||
    die "Lua linting failed with exit code $?."

echo "Compile-checking ${#lua_files[@]} Lua file(s)..."
for lua_file in "${lua_files[@]}"; do
    "$lua_compiler_path" -p "$lua_file" ||
        die "Lua compilation failed for '$lua_file' with exit code $?."
done

echo "Build complete:"
echo "  $packaged_mod_path"
