local isKeyAlreadyPressed = false
local keyPressCount = 0

local keyTables = {}
local winTables = {}

function toggleAppByBundleID(bundleID)
  local app = hs.application.get(bundleID)

  if not app then
    hs.application.launchOrFocusByBundleID(bundleID)
    return
  end

  local windows = app:allWindows()

  if #windows == 0 then
    hs.application.launchOrFocusByBundleID(bundleID)
    return
  end

  if app:isHidden() or hs.fnutils.every(windows, function(win) return win:isMinimized() end) then
    for _, win in ipairs(windows) do
      if win:isMinimized() then
        win:unminimize()
      end
      winTables[bundleID].lastWindow:focus()
    end
  elseif app:isFrontmost() then
    app:hide()
  else
    local focused = false
    for _, win in ipairs(windows) do
      if win:isStandard() and win:isVisible() and not win:isMinimized() then
        win:focus()
      end
      winTables[bundleID].lastWindow:focus()
    end
    
    if not focused then
      winTables[bundleID].lastWindow:focus()
    end
  end
end

-- modifiers가 정확히 일치하는지 확인하는 함수
function exactModifiersMatch(expected, actual)
  local mods = { "cmd", "ctrl", "alt", "shift", "fn" }
  for _, mod in ipairs(mods) do
    if (actual[mod] or false) ~= hs.fnutils.contains(expected, mod) then
      return false
    end
  end
  return true
end

keyDownTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  keyPressCount = keyPressCount + 1
  local target = keyTables[event:getKeyCode()]
  if not target then return false end

  local skipSet = {}
  for _, bundleID in ipairs(target.skipBundleIDs or {}) do
    skipSet[bundleID] = true
  end

  if isKeyAlreadyPressed then return true end

  local flags = event:getFlags()
  if not exactModifiersMatch(target.modifiers, flags) then return false end

  local frontApp = hs.application.frontmostApplication()
  local frontBundleID = frontApp and frontApp:bundleID()

  if skipSet[frontBundleID] then return false end

  isKeyAlreadyPressed = true
  toggleAppByBundleID(target.bundleID)

  return true
end):start()

keyUpTap = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
  if keyPressCount > 500 then
    keyDownTap:stop(); keyDownTap:start()
    keyUpTap:stop(); keyUpTap:start()
    keyPressCount = 0
    return true
  end

  local target = keyTables[event:getKeyCode()]
  if target then
    isKeyAlreadyPressed = false
  end
end):start()

local function watchFocusedWindow(bundleID)
  local app = hs.application.get(bundleID)
  if app then
    winTables[bundleID].lastWindow = app:focusedWindow()
  end
end

local appWatcherCount = 0

function applicationWatcher(appName, eventType, app)
  appWatcherCount = appWatcherCount + 1
  local bundleID = app:bundleID()

  if winTables[bundleID] ~= nil then
    if eventType == hs.application.watcher.activated then
      winTables[bundleID].timer:start()
    elseif eventType == hs.application.watcher.deactivated then
      winTables[bundleID].timer:stop()
    end
  end

  if appWatcherCount > 20 then
    appWatcher:stop()
    appWatcher:start()
    applicationWatcher = 0
  end
end

appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

function bindToggleAppWithEventtap(modifiers, keyChar, targetBundleID, skipIfFrontBundleIDs)
  keyTables[hs.keycodes.map[keyChar]] = {
    modifiers = modifiers,
    keyChar = keyChar,
    bundleID = targetBundleID,
    skipBundleIDs = skipIfFrontBundleIDs
  }

  winTables[targetBundleID] = {
    lastWindow = nil,
    timer = hs.timer.doEvery(0.4, function()
      watchFocusedWindow(targetBundleID)
    end)
  }
end

-- 바인딩 설정
bindToggleAppWithEventtap({"ctrl"}, "1", "com.googlecode.iterm2", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap({"ctrl"}, "2", "com.naver.Whale", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap({"ctrl"}, "3", "com.jetbrains.intellij", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap({"ctrl"}, "4", "com.jetbrains.datagrip", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap({"ctrl"}, "5", "com.apple.finder", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap({"ctrl"}, "e", "com.microsoft.VSCode", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap({"ctrl"}, "w", "com.kakao.KakaoTalkMac", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap({"ctrl"}, "q", "kr.thingsflow.BetweenMac", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})