local keyPressCount = 0

local keyTables = {}
local winTables = {}

local keyCodeWithTables = {}

function execute(target)
  if target.duplicate == false then
    target.isKeyAlreadyPressed = true
  end
  -- hs.window.animationDuration = 0.2

  if target.command == "app" then
    toggleAppByBundleID(target.bundleID)
  elseif target.command == "minimize" then
    minimizeAndFocusNext(false)
  elseif target.command == "hide" then
    minimizeAndFocusNext(true)
  elseif target.command == "moveLeft" then
    moveWinTo(hs.window.focusedWindow(), "left")
  elseif target.command == "moveRight" then
    moveWinTo(hs.window.focusedWindow(), "right")
  elseif target.command == "moveUp" then
    moveWinTo(hs.window.focusedWindow(), "up")
  elseif target.command == "moveDown" then
    moveWinTo(hs.window.focusedWindow(), "down")
  elseif target.command == "moveLeftPair" then
    moveWinTo(hs.window.focusedWindow(), "left")
    moveWinTo(getNextWindowOnCurrentScreen(), "right")
  elseif target.command == "moveRightPair" then
    moveWinTo(hs.window.focusedWindow(), "right")
    moveWinTo(getNextWindowOnCurrentScreen(), "left")
  elseif target.command == "moveUpPair" then
    moveWinTo(hs.window.focusedWindow(), "up")
    moveWinTo(getNextWindowOnCurrentScreen(), "down")
  elseif target.command == "moveDownPair" then
    moveWinTo(hs.window.focusedWindow(), "down")
    moveWinTo(getNextWindowOnCurrentScreen(), "up")
  elseif target.command == "moveUpPairHalf" then
    moveWinTo(hs.window.focusedWindow(), "uphalf")
    moveWinTo(getNextWindowOnCurrentScreen(), "downhalf")
  elseif target.command == "moveDownPairHalf" then
    moveWinTo(hs.window.focusedWindow(), "downhalf")
    moveWinTo(getNextWindowOnCurrentScreen(), "uphalf")
  elseif target.command == "screenLeft" then
    moveWinToNextScreen("left")
  elseif target.command == "screenRight" then
    moveWinToNextScreen("right")
  elseif target.command == "expandWindow" then
    resizeWin(hs.window.focusedWindow(), "expand", 50)
  elseif target.command == "reduceWindow" then
    resizeWin(hs.window.focusedWindow(), "reduce", 50)
  elseif target.command == "expandHorizontal" then
    resizeWin(hs.window.focusedWindow(), "right", 50)
  elseif target.command == "reduceHorizontal" then
    resizeWin(hs.window.focusedWindow(), "left", 50)
  elseif target.command == "expandVertical" then
    resizeWin(hs.window.focusedWindow(), "up", 50)
  elseif target.command == "reduceVertical" then
    resizeWin(hs.window.focusedWindow(), "down", 50)
  elseif target.command == "toggleMissionControl" then
    hs.spaces.toggleMissionControl()
  elseif target.command == "toggleAppExpose" then
    hs.spaces.toggleAppExpose()
  elseif target.command == "toggleLaunchPad" then
    hs.spaces.toggleLaunchPad()
  elseif target.command == "volumeUp" then
    volume(1)
  elseif target.command == "volumeDown" then
    volume(-1)
  elseif target.command == "volumeMute" then
    volume(0)
  end

  return true
end

function volume(direction)
  if direction == 1 then
    hs.eventtap.event.newSystemKeyEvent("SOUND_UP", true):post()
    hs.eventtap.event.newSystemKeyEvent("SOUND_UP", false):post()
  elseif direction == -1 then
    hs.eventtap.event.newSystemKeyEvent("SOUND_DOWN", true):post()
    hs.eventtap.event.newSystemKeyEvent("SOUND_DOWN", false):post()
  elseif direction == 0 then
    hs.eventtap.event.newSystemKeyEvent("MUTE", true):post()
    hs.eventtap.event.newSystemKeyEvent("MUTE", false):post()
  end
end

function getNextWindowOnCurrentScreen()
    local currentWindow = hs.window.focusedWindow()

    if not currentWindow then
        return nil -- 포커스된 창이 없을 경우 nil 반환
    end

    -- 현재 윈도우의 스크린 정보 가져오기
    local currentScreen = currentWindow:screen()

    -- 현재 모니터에서 모든 윈도우 가져오기
    local windowsOnScreen = hs.window.orderedWindows()

    -- 현재 스크린의 윈도우만 필터링
    local windowsOnCurrentScreen = {}
    local c = 0
    for _, window in ipairs(windowsOnScreen) do
        if window:screen() == currentScreen then
          if window:title() ~= "" then
            c = c + 1
          end
        end

        if c == 2 then
          return window
        end
    end

    return nil -- 창을 찾을 수 없을 경우 nil 반환
end


function moveWinToNextScreen(direction)
  local win = hs.window.focusedWindow()   -- 현재 활성화된 앱의 윈도우
  -- 현재 활성화된 윈도우가 없으면 종료
  if not win then
    return
  end

  local currentScreen = win:screen()       -- 현재 윈도우의 화면
  local screens = hs.screen.allScreens()   -- 모든 스크린 정보를 가져옴
  local currentIndex = hs.fnutils.indexOf(screens, currentScreen) -- 현재 스크린의 인덱스를 찾음

  -- currentIndex가 nil에 대해 예외 처리
  if not currentIndex then
    return
  end

  local targetIndex
  if direction == "left" then
    targetIndex = (currentIndex % #screens) + 1  -- 이전 스크린 인덱스
  elseif direction == "right" then
    targetIndex = ((currentIndex - 2) % #screens) + 1  -- 다음 스크린 인덱스
  end

  local targetScreen = screens[targetIndex]
  local frame = win:frame()
  local targetFrame = targetScreen:frame()

  -- 체크: 현재 윈도우가 현재 스크린에 맞춰져 있는지 확인
  local isMaximized = (frame.x == currentScreen:frame().x) and 
                      (frame.y == currentScreen:frame().y) and 
                      (frame.w == currentScreen:frame().w) and 
                      (frame.h == currentScreen:frame().h)

  if isMaximized then
    -- 현재 창이 최대화 되어 있을 경우, 타겟 스크린에 맞춰 프레임 설정
    frame.x = targetFrame.x
    frame.y = targetFrame.y
    frame.w = targetFrame.w
    frame.h = targetFrame.h
  else
    -- 현재 화면의 크기를 기준으로 비율 계산
    local scaleX = targetFrame.w / currentScreen:frame().w
    local scaleY = targetFrame.h / currentScreen:frame().h

    -- 비율에 맞춰 새 위치 계산
    frame.x = targetFrame.x + (frame.x - currentScreen:frame().x) * scaleX
    frame.y = targetFrame.y + (frame.y - currentScreen:frame().y) * scaleY

    -- 윈도우 크기 비율 계산
    frame.w = math.min(frame.w * scaleX, targetFrame.w)  -- 새로운 너비는 타겟 화면의 너비를 넘지 않도록
    frame.h = math.min(frame.h * scaleY, targetFrame.h)  -- 새로운 높이는 타겟 화면의 높이를 넘지 않도록

    -- 경계 내에 위치하도록 조정 (정수로 반올림)
    frame.x = math.ceil(frame.x)
    frame.y = math.ceil(frame.y)
    frame.w = math.ceil(frame.w)
    frame.h = math.ceil(frame.h)
  end

  -- 윈도우가 타겟 스크린의 경계를 넘지 않도록 보정
  if frame.x < targetFrame.x then
    frame.x = targetFrame.x
  elseif frame.x + frame.w > targetFrame.x + targetFrame.w then
    frame.x = targetFrame.x + targetFrame.w - frame.w
  end

  if frame.y < targetFrame.y then
    frame.y = targetFrame.y
  elseif frame.y + frame.h > targetFrame.y + targetFrame.h then
    frame.y = targetFrame.y + targetFrame.h - frame.h
  end

  win:setFrame(frame)  -- 프레임을 설정
end

function resizeWin(win, direction, adjustment)
  if win == nil then
    return
  end
  
  local frame = win:frame()
  local screen = win:screen():frame() -- 현재 화면의 크기

  -- 현재 창의 중심 좌표 계산
  local centerX = frame.x + (frame.w / 2)
  local centerY = frame.y + (frame.h / 2)

  -- 창 크기 조정
  if direction == "left" then
    frame.w = math.max(frame.w - adjustment, 0)  -- 최소 크기를 0으로 제한
    frame.x = centerX - (frame.w / 2)  -- 중심 유지
  elseif direction == "right" then
    frame.w = math.max(frame.w + adjustment, 0)  -- 최소 크기를 0으로 제한
    frame.x = centerX - (frame.w / 2)  -- 중심 유지
  elseif direction == "up" then
    frame.h = math.max(frame.h + adjustment, 0)  -- 최소 크기를 0으로 제한 (↑ 방향으로 증가)
    frame.y = centerY - (frame.h / 2)  -- 중심 유지
  elseif direction == "down" then
    frame.h = math.max(frame.h - adjustment, 0)  -- 최소 크기를 0으로 제한 (↓ 방향으로 감소)
    frame.y = centerY - (frame.h / 2)  -- 중심 유지
  elseif direction == "expand" then
    frame.w = math.max(frame.w + adjustment, 0)  -- 최소 크기를 0으로 제한
    frame.x = centerX - (frame.w / 2)  -- 중심 유지
    frame.h = math.max(frame.h + adjustment, 0)  -- 최소 크기를 0으로 제한 (↑ 방향으로 증가)
    frame.y = centerY - (frame.h / 2)  -- 중심 유지
  elseif direction == "reduce" then
    frame.h = math.max(frame.h - adjustment, 0)  -- 최소 크기를 0으로 제한 (↓ 방향으로 감소)
    frame.y = centerY - (frame.h / 2)  -- 중심 유지
    frame.w = math.max(frame.w - adjustment, 0)  -- 최소 크기를 0으로 제한
    frame.x = centerX - (frame.w / 2)  -- 중심 유지
  end

  -- 스크린 범위를 넘지 않도록 조정
  if frame.x < screen.x then
    frame.x = screen.x
  elseif frame.x + frame.w > screen.x + screen.w then
    frame.x = screen.x + screen.w - frame.w
  end
  
  if frame.y < screen.y then
    frame.y = screen.y
  elseif frame.y + frame.h > screen.y + screen.h then
    frame.y = screen.y + screen.h - frame.h
  end

  win:setFrame(frame)
end

function moveWinTo(win, where)
  if win == nil then
    return
  end
  -- local win = hs.window.focusedWindow()   -- 현재 활성화된 앱의 윈도우
  local frame = win:frame()
  local screen = win:screen():frame()     -- 현재 화면

  frame.x = screen.x
  frame.y = screen.y
  frame.w = screen.w
  frame.h = screen.h

  if where == "left" then
    frame.w = screen.w / 2      -- width를 화면의 1/2 로 조정
  elseif where == "right" then
    frame.w = screen.w / 2      -- width를 화면의 1/2 로 조정
    frame.x = screen.x + frame.w -- 윈도우의 x 좌표를 화면 width의 1/2 로 조정
  elseif where == "down" then
    frame.w = screen.w * 1 / 2  -- width를 화면의 2/3로 조정
    frame.h = screen.h * 2 / 3  -- height를 화면의 2/3로 조정
    frame.x = screen.x + (screen.w - frame.w) / 2 -- x 좌표를 중앙으로 설정
    frame.y = screen.y + (screen.h - frame.h) / 2 -- y 좌표를 중앙으로 설정
  elseif where == "up" then
  elseif where == "uphalf" then
    frame.h = screen.h / 2
  elseif where == "downhalf" then
    frame.h = screen.h / 2
    frame.y = screen.y + frame.h
  end

  win:setFrame(frame)
end

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

keyDownTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  keyPressCount = keyPressCount + 1
  local target = keyTables[makeHashKey(event)]
  -- print(makeHashKey(event), event:getKeyCode())
  if not target then
    return false
  end

  local skipSet = {}
  for _, bundleID in ipairs(target.skipBundleIDs or {}) do
    skipSet[bundleID] = true
  end

  if target.isKeyAlreadyPressed then
    return true
  end

  -- local flags = event:getFlags()
  -- if not exactModifiersMatch(target.modifiers, flags) then return false end

  local frontApp = hs.application.frontmostApplication()
  local frontBundleID = frontApp and frontApp:bundleID()

  if skipSet[frontBundleID] then return false end

  return execute(target)
end):start()

keyUpTap = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
  if keyPressCount > 500 then
    keyDownTap:stop(); keyDownTap:start()
    keyUpTap:stop(); keyUpTap:start()
    keyPressCount = 0
    return true
  end

  if keyCodeWithTables[event:getKeyCode()] ~= nil then
    for _, val in pairs(keyCodeWithTables[event:getKeyCode()]) do
      keyTables[val].isKeyAlreadyPressed = false
    end
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

function bindToggleAppWithEventtap(command, modifiers, keyChar, targetBundleID, skipIfFrontBundleIDs, duplicate, fn)
  local keyCode = hs.keycodes.map[keyChar]
  local hashKey = makeHashKey(modifiers, keyCode)
  keyTables[hashKey] = {
    command = command,
    modifiers = modifiers,
    keyChar = keyChar,
    keyCode = keyCode,
    bundleID = targetBundleID,
    skipBundleIDs = skipIfFrontBundleIDs,
    isKeyAlreadyPressed = false,
    duplicate = duplicate,
    fn = fn
  }

  if keyCodeWithTables[keyCode] == nil then
    keyCodeWithTables[keyCode] = {}
  end

  table.insert(keyCodeWithTables[keyCode], hashKey)

  if targetBundleID ~= nil then
    winTables[targetBundleID] = {
      lastWindow = nil,
      timer = hs.timer.doEvery(0.4, function()
        watchFocusedWindow(targetBundleID)
      end)
    }
  end
end

-- 바인딩 설정
bindToggleAppWithEventtap("app", {"ctrl"}, "1", "com.googlecode.iterm2", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "2", "com.naver.Whale", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "3", "com.jetbrains.intellij", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "4", "com.jetbrains.datagrip", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "5", "com.apple.finder", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "e", "com.microsoft.VSCode", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "w", "com.kakao.KakaoTalkMac", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "q", "kr.thingsflow.BetweenMac", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "m", "m", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("app", {"ctrl"}, "x", "x", {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)

bindToggleAppWithEventtap("minimize", {"ctrl"}, "m", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("hide", {"ctrl"}, "x", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)

bindToggleAppWithEventtap("moveLeft", {"ctrl", "fn"}, "left", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveRight", {"ctrl", "fn"}, "right", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveUp", {"ctrl", "fn"}, "up", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveDown", {"ctrl", "fn"}, "down", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveLeft", {"ctrl", "shift"}, "a", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveRight", {"ctrl", "shift"}, "d", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveUp", {"ctrl", "shift"}, "w", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveDown", {"ctrl", "shift"}, "s", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)

bindToggleAppWithEventtap("moveLeftPair", {"ctrl", "cmd", "alt", "fn"}, "left", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveRightPair", {"ctrl", "cmd", "alt", "fn"}, "right", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveUpPair", {"ctrl", "cmd", "alt", "fn"}, "up", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveDownPair", {"ctrl", "cmd", "alt", "fn"}, "down", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveLeftPair", {"ctrl", "cmd", "shift", "fn"}, "left", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveRightPair", {"ctrl", "cmd", "shift", "fn"}, "right", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveUpPairHalf", {"ctrl", "cmd", "shift", "fn"}, "up", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("moveDownPairHalf", {"ctrl", "cmd", "shift", "fn"}, "down", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)

bindToggleAppWithEventtap("expandWindow", {"ctrl", "shift"}, "=", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)
bindToggleAppWithEventtap("reduceWindow", {"ctrl", "shift"}, "-", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)
bindToggleAppWithEventtap("expandHorizontal", {"ctrl", "shift"}, "l", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)
bindToggleAppWithEventtap("reduceHorizontal", {"ctrl", "shift"}, "j", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)
bindToggleAppWithEventtap("expandVertical", {"ctrl", "shift"}, "i", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)
bindToggleAppWithEventtap("reduceVertical", {"ctrl", "shift"}, "k", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)

bindToggleAppWithEventtap("screenLeft", {"ctrl", "shift", "fn"}, "left", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("screenRight", {"ctrl", "shift", "fn"}, "right", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("screenLeft", {"ctrl", "shift"}, "z", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("screenRight", {"ctrl", "shift"}, "c", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)

bindToggleAppWithEventtap("toggleMissionControl", {"ctrl"}, "tab", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("toggleAppExpose", {"ctrl"}, "`", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
bindToggleAppWithEventtap("toggleLaunchPad", {"ctrl", "cmd"}, "a", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)

bindToggleAppWithEventtap("volumeUp", {"ctrl", "cmd"}, "e", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)
bindToggleAppWithEventtap("volumeDown", {"ctrl", "cmd"}, "w", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, true)
bindToggleAppWithEventtap("volumeMute", {"ctrl", "cmd"}, "q", nil, {"com.omnissa.horizon.client.mac", "com.vmware.fusion"}, false)
