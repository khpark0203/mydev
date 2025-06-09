local keyPressCount = 0

local keyTables = {}
local winTables = {}

function focusWindowDelay(win, delay)
  hs.timer.delayed.new(delay, function()
    win:focus()
  end):start()
end

function minimizeAndFocusNext(hide)
    local win = hs.window.frontmostWindow()
    if not win then return end

    local app = win:application()

    if hide == true then
      app:hide()
      return
    end

    win:minimize()

    -- 같은 앱의 나머지 윈도우들 중 포커스 가능한 것 찾기
    local windows = app:allWindows()
    for _, w in ipairs(windows) do
        if not w:isMinimized() and w:isStandard() then
            w:focus()
            return
        end
    end

    -- 같은 앱 내에 다른 포커스 가능한 창이 없으면, 다음으로 최근에 사용한 윈도우로 전환
    hs.timer.doAfter(0.1, function()
        local orderedWindows = hs.window.orderedWindows()
        for _, w in ipairs(orderedWindows) do
            if w ~= win and not w:isMinimized() then
                w:focus()
                return
            end
        end
    end)
end

function minimizeFocusedWindow()
  local win = hs.window.frontmostWindow()
  if win then
    win:minimize()
  end
end

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
    local allMinimized = 0
    local focused = false
    for _, win in ipairs(windows) do
      if win:isMinimized() then
        if #windows == 1 then
          focusWindowDelay(win:unminimize(), 0.1)
          focused = true
          break
        end
        
        allMinimized = allMinimized + 1
        
        if allMinimized == #windows then
          local lwin = winTables[bundleID].lastWindow
          if lwin == nil then
            lwin = win
          end
          focusWindowDelay(lwin:unminimize(), 0.1)
          focused = true
        end
      end
    end

    if allMinimized ~= #windows and focused == false then
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
      focused = true
      winTables[bundleID].lastWindow:focus()
    end
    
    if not focused then
      winTables[bundleID].lastWindow:focus()
    end
  end
end

function makeHashKey(modifiersOrEvent, keycode)
    local modifiers = {}

    if type(modifiersOrEvent) == "userdata" and modifiersOrEvent.getFlags then
        -- modifiersOrEvent는 hs.eventtap.event 객체임
        local flags = modifiersOrEvent:getFlags()
        keycode = modifiersOrEvent:getKeyCode()
        for _, mod in ipairs({ "ctrl", "alt", "shift", "cmd", "fn" }) do
            if flags[mod] then
                table.insert(modifiers, mod)
            end
        end
    elseif type(modifiersOrEvent) == "table" and type(keycode) == "number" then
        -- modifiers는 {"ctrl", "cmd"} 형태의 테이블임
        local modifierSet = {}
        for _, mod in ipairs(modifiersOrEvent) do
            modifierSet[mod] = true
        end
        for _, mod in ipairs({ "ctrl", "alt", "shift", "cmd", "fn" }) do
            if modifierSet[mod] then
                table.insert(modifiers, mod)
            end
        end
    else
        error("Invalid arguments: expected (event) or (modifiers, keycode)")
    end

    -- keycode는 항상 문자열로 추가
    table.insert(modifiers, tostring(keycode))
    return table.concat(modifiers, "+")
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

function execute(keyTable)
  if keyTable.command == "minimize" then
    minimizeAndFocusNext(false)
  elseif keyTable.command == "hide" then
    minimizeAndFocusNext(true)
  else
    toggleAppByBundleID(keyTable.bundleID)
  end

  return true
end

keyDownTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  keyPressCount = keyPressCount + 1
  local target = keyTables[makeHashKey(event)]
  if not target then return false end

  local skipSet = {}
  for _, bundleID in ipairs(target.skipBundleIDs or {}) do
    skipSet[bundleID] = true
  end

  if target.isKeyAlreadyPressed then return true end

  -- local flags = event:getFlags()
  -- if not exactModifiersMatch(target.modifiers, flags) then return false end

  local frontApp = hs.application.frontmostApplication()
  local frontBundleID = frontApp and frontApp:bundleID()

  if skipSet[frontBundleID] then return false end

  target.isKeyAlreadyPressed = true
  return execute(target)
end):start()

keyUpTap = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
  if keyPressCount > 500 then
    keyDownTap:stop(); keyDownTap:start()
    keyUpTap:stop(); keyUpTap:start()
    keyPressCount = 0
    return true
  end

  local target = keyTables[makeHashKey(event)]
  if target then
    target.isKeyAlreadyPressed = false
  end
end):start()

local function watchFocusedWindow(bundleID)
  local app = hs.application.get(bundleID)
  if app then
    local focusedWindow = app:focusedWindow()
    if focusedWindow ~= nil then
      winTables[bundleID].lastWindow = focusedWindow
    end
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

function bindToggleAppWithEventtap(command, modifiers, keyChar, targetBundleID, skipIfFrontBundleIDs)
  local keyCode = hs.keycodes.map[keyChar]
  keyTables[makeHashKey(modifiers, keyCode)] = {
    command = command,
    modifiers = modifiers,
    keyChar = keyChar,
    bundleID = targetBundleID,
    skipBundleIDs = skipIfFrontBundleIDs,
    isKeyAlreadyPressed = false
  }

  winTables[targetBundleID] = {
    lastWindow = nil,
    timer = hs.timer.doEvery(0.4, function()
      watchFocusedWindow(targetBundleID)
    end)
  }
end

-- 바인딩 설정
bindToggleAppWithEventtap("", {"ctrl"}, "1", "com.googlecode.iterm2", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "2", "com.naver.Whale", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "3", "com.jetbrains.intellij", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "4", "com.jetbrains.datagrip", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "5", "com.apple.finder", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "e", "com.microsoft.VSCode", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "w", "com.kakao.KakaoTalkMac", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "q", "kr.thingsflow.BetweenMac", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "m", "m", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
bindToggleAppWithEventtap("", {"ctrl"}, "x", "x", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"})
