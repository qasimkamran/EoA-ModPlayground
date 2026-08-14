-- main.lua

-- luacheck: globals NotifyOnNewObject

local path = require("lib.path")
local Logger = require("lib.logger")
local custom_io = require("lib.custom_io")

local now = os.date("%Y-%m-%d")
local absolutePath = path.absolute()
local modPath = path.assert_mod_path(absolutePath)

local config = {
    LOG_FILE = modPath .. "\\logs\\" .. now .. ".log",
    PROJECT_PREFIX = "[EoA-ModPlayground]",
    MODULE_PREFIX = "[02-MenuExtensions]",
}

custom_io.printf("%s%s: Mod Loaded.\n", config.PROJECT_PREFIX, config.MODULE_PREFIX)

local logger = Logger.new(config.LOG_FILE)

logger:log("%s%s: Mod Loaded.\n", config.PROJECT_PREFIX, config.MODULE_PREFIX)

local function callback(widget)
    if widget == nil or not widget:IsValid() then
        return
    end

    custom_io.printf("%s%s: Widget constructed: %s\n",
                     config.PROJECT_PREFIX,
                     config.MODULE_PREFIX,
                     widget:GetFullName())

    logger:log("%s%s: Widget constructed: %s\n",
               config.PROJECT_PREFIX,
               config.MODULE_PREFIX,
               widget:GetFullName())
end

-- Unlike a hook on UserWidget:Construct, this also observes instances of
-- Blueprint-derived widget classes that override the Construct event.
NotifyOnNewObject("/Script/UMG.UserWidget", callback)

