-- User patch: wrap HttpInspector:init to add custom startup behavior
-- Place in koreader/patches and run with userpatch.applyPatches()

local userpatch = require("userpatch")
local logger = require("logger")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

-- Also register dispatcher actions immediately so they are available
-- even if the httpinspector plugin instance is created before this
-- patch's per-instance hook runs.
do
    local ok, Dispatcher = pcall(require, "dispatcher")
    if ok and Dispatcher then
        Dispatcher:registerAction("httpinspector_start", { category="none", event="StartHttpInspector", title=_("Start HTTP inspector"), general=true, })
        Dispatcher:registerAction("httpinspector_stop", { category="none", event="StopHttpInspector", title=_("Stop HTTP inspector"), general=true, })
        Dispatcher:registerAction("httpinspector_toggle", { category="none", event="ToggleHttpInspector", title=_("Toggle HTTP inspector"), general=true, separator=true, })
        logger.dbg("userpatch/httpinspector: registered global dispatcher actions")
    end
end

local function patchHTTPInspector(plugin)
if type(plugin.init) ~= "function" then
        logger.warn("userpatch/httpinspector:init: plugin has no init() to wrap")
        return
    end

    local orig_init = plugin.init

    plugin.onStartHttpInspector = function(self)
        if type(self.start) == "function" and not self:isRunning() then
            self:start()
            UIManager:show(InfoMessage:new{text = _("HTTP Server Started"), timeout = 2 })
        else
            UIManager:show(InfoMessage:new{text = _("HTTP Server already running"), timeout = 2 })
        end
        return true
    end

    plugin.onStopHttpInspector = function(self)
        if type(self.stop) == "function" and self:isRunning() then
            self:stop()
            UIManager:show(InfoMessage:new{text = _("HTTP Server stopped"), timeout = 2 })
        else
            UIManager:show(InfoMessage:new{text = _("HTTP Server is off"), timeout = 2 })
        end
        return true
    end

    plugin.onToggleHttpInspector = function(self)
        if type(self.isRunning) == "function" and type(self.start) == "function" and type(self.stop) == "function" then
            if self:isRunning() then
                self:stop()
                UIManager:show(InfoMessage:new{text = _("HTTP Server stopped"), timeout = 2 })
            else
                self:start()
                UIManager:show(InfoMessage:new{text = _("HTTP Server Started"), timeout = 2 })
            end
        end
        return true
    end

    logger.dbg("userpatch/httpinspector: actions registered")
end

-- Register a patch that will be applied when the httpinspector plugin is created
userpatch.registerPatchPluginFunc("httpinspector", patchHTTPInspector)
