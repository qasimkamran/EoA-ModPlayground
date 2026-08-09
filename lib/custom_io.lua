-- custom_io.lua

local custom_io = {}

function custom_io.printf(format, ...)
    print(string.format(format, ...))
end

function custom_io.sprintf(format, ...)
    return string.format(format, ...)
end

return custom_io

