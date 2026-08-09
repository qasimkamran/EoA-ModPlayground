-- main.lua

local Logger = require("lib.logger")
local path = require("lib.path")

local now = os.date("%Y-%m-%d")
local absolutePath = path.absolute()
local modPath = path.assert_mod_path(absolutePath)

local config = {
    LOG_FILE = modPath .. "\\logs\\" .. now .. ".log",
    PROJECT_PREFIX = "[EoA-ModPlayground]",
    MODULE_PREFIX = "[01-HelloWorld]"
}

local logger = Logger.new(config.LOG_FILE)

logger:log("%s%s: Hello, World!", config.PROJECT_PREFIX, config.MODULE_PREFIX)

logger:close()

