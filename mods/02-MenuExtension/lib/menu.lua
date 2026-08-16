-- menu.lua

-- luacheck: globals FText

local custom_io = require("lib.custom_io")

local menu = {}

---@type fun(text: string): table
---@diagnostic disable-next-line: undefined-global
local FText = FText

function menu.renameMenuItem(widget, oldText, newText, logger, config)
    if widget == nil or not widget:IsValid() then
        return
    end

    local menuName = widget.MenuName

    if menuName == nil or not menuName:IsValid() then
        return
    end

    local text = menuName:GetText():ToString()
    local itemIndex = tostring(widget.ItemIndex)

    custom_io.printf("%s%s: ItemIndex=%s MenuName='%s'\n",
                     config.PROJECT_PREFIX,
                     config.MODULE_PREFIX,
                     itemIndex,
                     text)

    logger:log("%s%s: ItemIndex=%s MenuName='%s'\n",
               config.PROJECT_PREFIX,
               config.MODULE_PREFIX,
               itemIndex,
               text)

    if text == oldText then
        menuName:SetText(FText(newText))

        custom_io.printf("%s%s: Renamed %s -> %s\n",
                         config.PROJECT_PREFIX,
                         config.MODULE_PREFIX,
                         oldText,
                         newText)

        logger:log("%s%s: Renamed %s -> %s\n",
                   config.PROJECT_PREFIX,
                   config.MODULE_PREFIX,
                   oldText,
                   newText)
    end
end

return menu
