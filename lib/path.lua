-- path.lua

local path = {}

function path.absolute()
    local sourcePath = debug.getinfo(1, "S").source:match("^@(.+)$")

    local isAbsolute = sourcePath and (
        sourcePath:match("^%a:[/\\]") or
        sourcePath:match("^[/\\]")
    )

    assert(isAbsolute, "Could not determine the absolute path to path.lua")

    return sourcePath
end

function path.assert_mod_path(sourcePath)
    assert(sourcePath, "An absolute source path is required")

    local libPath = sourcePath:match("^(.*)[/\\][^/\\]+$")
    local scriptsPath, libDirectory
    if libPath then
        scriptsPath, libDirectory = libPath:match("^(.*)[/\\]([^/\\]+)$")
    end

    local modPath, scriptsDirectory
    if scriptsPath then
        modPath, scriptsDirectory = scriptsPath:match("^(.*)[/\\]([^/\\]+)$")
    end

    local isModPath = modPath
        and libDirectory:lower() == "lib"
        and scriptsDirectory:lower() == "scripts"

    assert(isModPath, "path.lua must be located inside the mod's Scripts/lib directory")

    return modPath
end

function path.root()
    return path.assert_mod_path(path.absolute())
end

return path
