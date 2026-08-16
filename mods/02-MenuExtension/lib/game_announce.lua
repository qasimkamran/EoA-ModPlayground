-- game_announce.lua

-- luacheck: globals FText

local custom_io = require("lib.custom_io")

local game_announce = {}

---@type fun(text: string): table
---@diagnostic disable-next-line: undefined-global
local FText = FText

function game_announce.updateMessageText(widget, newText, logger, config)
    if widget == nil or not widget:IsValid() then
        return
    end

    if widget.MessageText == nil or not widget.MessageText:IsValid() then
        custom_io.printf("%s%s: MessageText not found\n",
                         config.PROJECT_PREFIX,
                         config.MODULE_PREFIX)

        logger:log("%s%s: MessageText not found\n",
                   config.PROJECT_PREFIX,
                   config.MODULE_PREFIX)
        return
    end

    local before = widget.MessageText:GetText():ToString()

    custom_io.printf("%s%s: BEFORE: %s\n",
                     config.PROJECT_PREFIX,
                     config.MODULE_PREFIX,
                     tostring(before))

    logger:log("%s%s: BEFORE: %s\n",
               config.PROJECT_PREFIX,
               config.MODULE_PREFIX,
               tostring(before))

    widget.MessageText:SetText(FText(newText))

    local after = widget.MessageText:GetText():ToString()

    custom_io.printf("%s%s: AFTER: %s\n",
                     config.PROJECT_PREFIX,
                     config.MODULE_PREFIX,
                     tostring(after))

    logger:log("%s%s: AFTER: %s\n",
               config.PROJECT_PREFIX,
               config.MODULE_PREFIX,
               tostring(after))
end

return game_announce
