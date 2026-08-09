-- logger.lua

local custom_io = require("lib.custom_io")

local Logger = {}
Logger.__index = Logger;

function Logger.new(path)
    local file, err = io.open(path, "a")
    assert(file, "Could not open log file: " .. tostring(err))

    return setmetatable({
        file = file
    }, Logger)
end

function Logger:log(format, ...)
    assert(self.file, "Cannot write to a closed log file")

    local message = custom_io.sprintf(format, ...)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")

    self.file:write(custom_io.sprintf("[%s] %s\n", timestamp, message))
    self.file:flush()
end

function Logger:close()
    if self.file then
        self.file:close()
        self.file = nil
    end
end

return Logger

