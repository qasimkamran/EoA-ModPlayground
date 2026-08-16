-- widget.lua

-- luacheck: globals FindAllOf

local custom_io = require("lib.custom_io")

local widget = {}

---@type fun(className: string): table[]?
---@diagnostic disable-next-line: undefined-global
local FindAllOf = FindAllOf

function widget.logConstructedWidget(value, logger, config)
    if value == nil or not value:IsValid() then
        return
    end

    custom_io.printf("%s%s: Widget constructed: %s\n",
                     config.PROJECT_PREFIX,
                     config.MODULE_PREFIX,
                     value:GetFullName())

    logger:log("%s%s: Widget constructed: %s\n",
               config.PROJECT_PREFIX,
               config.MODULE_PREFIX,
               value:GetFullName())
end

---@param needle string
function widget.findTextBlocksContaining(needle, logger, config)
    assert(type(needle) == "string" and needle ~= "",
           "needle must be a non-empty string")

    local textBlocks = FindAllOf("TextBlock")

    if not textBlocks then
        custom_io.printf("%s%s: No TextBlocks found\n",
                         config.PROJECT_PREFIX,
                         config.MODULE_PREFIX)

        logger:log("%s%s: No TextBlocks found\n",
                   config.PROJECT_PREFIX,
                   config.MODULE_PREFIX)
        return
    end

    for _, textBlock in ipairs(textBlocks) do
        if textBlock:IsValid() then
            local ok, text = pcall(function()
                return textBlock:GetText():ToString()
            end)

            if ok and text and string.find(string.lower(text),
                                           string.lower(needle),
                                           1, true) then
                custom_io.printf("%s%s: MATCH: %s => \"%s\"\n",
                                 config.PROJECT_PREFIX,
                                 config.MODULE_PREFIX,
                                 textBlock:GetFullName(),
                                 text)

                logger:log("%s%s: MATCH: %s => \"%s\"\n",
                           config.PROJECT_PREFIX,
                           config.MODULE_PREFIX,
                           textBlock:GetFullName(),
                           text)
            end
        end
    end
end

return widget
