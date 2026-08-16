-- main.lua

-- luacheck: globals NotifyOnNewObject ExecuteInGameThreadWithDelay

local path = require("lib.path")
local Logger = require("lib.logger")
local custom_io = require("lib.custom_io")
local renameMenuItem = require("lib.menu").renameMenuItem
local logConstructedWidget = require("lib.widget").logConstructedWidget
local updateMessageText = require("lib.game_announce").updateMessageText

---@type fun(className: string, callback: fun(object: table))
---@diagnostic disable-next-line: undefined-global
local NotifyOnNewObject = NotifyOnNewObject

---@type fun(delayMilliseconds: integer, callback: function)
---@diagnostic disable-next-line: undefined-global
local ExecuteInGameThreadWithDelay = ExecuteInGameThreadWithDelay

local now = os.date("%Y-%m-%d")
local absolutePath = path.absolute()
local modPath = path.assert_mod_path(absolutePath)

local config = {
    LOG_FILE = modPath .. "\\logs\\" .. now .. ".log",
    PROJECT_PREFIX = "[EoA-ModPlayground]",
    MODULE_PREFIX = "[02-MenuExtensions]",
}

custom_io.printf(
    "%s%s: Mod Loaded.\n",
    config.PROJECT_PREFIX,
    config.MODULE_PREFIX
)

local logger = Logger.new(config.LOG_FILE)

logger:log(
    "%s%s: Mod Loaded.\n",
    config.PROJECT_PREFIX,
    config.MODULE_PREFIX
)

NotifyOnNewObject("/Script/UMG.UserWidget", function(widget)
    logConstructedWidget(widget, logger, config)
end)

NotifyOnNewObject( -- See FINDINGS.md for the explanation of the class path
    "/Game/ROD/Widget/Console/MainMenu/" ..
    "WBP_Console_MainMenu_MenuIcon." ..
    "WBP_Console_MainMenu_MenuIcon_C",
    function(widget)
        ExecuteInGameThreadWithDelay(100, function()
            renameMenuItem(widget, "Logout", "MOD", logger, config)
        end)
    end
)

NotifyOnNewObject(
    "/Game/ROD/Widget/Cockpit/Information/" ..
    "WBP_GameAnnounce_B.WBP_GameAnnounce_B_C",
    function(widget)
        ExecuteInGameThreadWithDelay(100, function()
            updateMessageText(widget,
                              "Hello from EoA-ModPlayground!",
                              logger,
                              config)
        end)
    end
)
