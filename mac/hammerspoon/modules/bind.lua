local winTables = {}
local hotkeyDefinitions = {}
local activeHotkeys = {}
local ignoredBundleIds = {
  "com.omnissa.horizon.client.mac",
  "com.vmware.fusion",
}

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
  local targetScreen = currentScreen:next()
  
  if not targetScreen or currentScreen == targetScreen then
    return
  end
  
  if direction == "left" then
    targetScreen = currentScreen:next()
  elseif direction == "right" then
    targetScreen = currentScreen:previous()
  end

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

local function watchFocusedWindow(bundleID)
  local app = hs.application.get(bundleID)
  if app then
    local focusedWindow = app:focusedWindow()
    if focusedWindow ~= nil then
      winTables[bundleID].lastWindow = focusedWindow
    end
  end
end

function toggleApp(bundleId)
  if not winTables[bundleId] then
    local app = hs.application.get(bundleId)
    local win = nil
    if app then
        win = app:focusedWindow()
    end

    winTables[bundleId] = {
      lastWindow = win,
      timer = hs.timer.doEvery(0.4, function()
        watchFocusedWindow(bundleId)
      end)
    }
  end
  toggleAppByBundleID(bundleId)
end

-- 현재 앱의 bundle ID 확인 함수
local function getFocusedBundleId()
  local app = hs.application.frontmostApplication()
  return app and app:bundleID() or ""
end

local function addHotKeyDefinition(modifiers, key, command, repeatCommand, targetAppId)
  table.insert(hotkeyDefinitions, {
    modifiers = modifiers,
    key = key,
    command = command,
    repeatCommand = repeatCommand,
    targetAppId = targetAppId,
  })
end

-- 모든 hotkey를 등록
local function enableAllHotkeys()
  if #activeHotkeys > 0 then return end -- 이미 등록된 경우 중복 방지

  for _, def in ipairs(hotkeyDefinitions) do
    if def.command == "app" then
      def.pressAction = function()
        toggleApp(def.targetAppId)
      end
    elseif def.command == "minimize" then
      def.pressAction = function()
        minimizeAndFocusNext(false)
      end
    elseif def.command == "hide" then
      def.pressAction = function()
        minimizeAndFocusNext(true)
      end
    elseif def.command == "moveLeft" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "left")
      end
    elseif def.command == "moveRight" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "right")
      end
    elseif def.command == "moveUp" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "up")
      end
    elseif def.command == "moveDown" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "down")
      end
    elseif def.command == "moveLeftPair" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "left")
        moveWinTo(getNextWindowOnCurrentScreen(), "right")
      end
    elseif def.command == "moveRightPair" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "right")
        moveWinTo(getNextWindowOnCurrentScreen(), "left")
      end
    elseif def.command == "moveUpPair" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "up")
        moveWinTo(getNextWindowOnCurrentScreen(), "down")
      end
    elseif def.command == "moveDownPair" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "down")
        moveWinTo(getNextWindowOnCurrentScreen(), "up")
      end
    elseif def.command == "moveUpPairHalf" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "uphalf")
        moveWinTo(getNextWindowOnCurrentScreen(), "downhalf")
      end
    elseif def.command == "moveDownPairHalf" then
      def.pressAction = function()
        moveWinTo(hs.window.focusedWindow(), "downhalf")
        moveWinTo(getNextWindowOnCurrentScreen(), "uphalf")
      end
    elseif def.command == "screenLeft" then
      def.pressAction = function()
        moveWinToNextScreen("left")
      end
    elseif def.command == "screenRight" then
      def.pressAction = function()
        moveWinToNextScreen("right")
      end
    elseif def.command == "expandWindow" then
      def.pressAction = function()
        resizeWin(hs.window.focusedWindow(), "expand", 50)
      end
    elseif def.command == "reduceWindow" then
      def.pressAction = function()
        resizeWin(hs.window.focusedWindow(), "reduce", 50)
      end
    elseif def.command == "expandHorizontal" then
      def.pressAction = function()
        resizeWin(hs.window.focusedWindow(), "right", 50)
      end
    elseif def.command == "reduceHorizontal" then
      def.pressAction = function()
        resizeWin(hs.window.focusedWindow(), "left", 50)
      end
    elseif def.command == "expandVertical" then
      def.pressAction = function()
        resizeWin(hs.window.focusedWindow(), "up", 50)
      end
    elseif def.command == "reduceVertical" then
      def.pressAction = function()
        resizeWin(hs.window.focusedWindow(), "down", 50)
      end
    elseif def.command == "toggleMissionControl" then
      def.pressAction = function()
        hs.spaces.toggleMissionControl()
      end
    elseif def.command == "toggleAppExpose" then
      def.pressAction = function()
        hs.spaces.toggleAppExpose()
      end
    elseif def.command == "toggleLaunchPad" then
      def.pressAction = function()
        hs.spaces.toggleLaunchPad()
      end
    elseif def.command == "volumeUp" then
      def.pressAction = function()
        volume(1)
      end
    elseif def.command == "volumeDown" then
      def.pressAction = function()
        volume(-1)
      end
    elseif def.command == "volumeMute" then
      def.pressAction = function()
        volume(0)
      end
    end
    if def.repeatCommand and def.repeatCommand == true then
      def.repeatAction = def.pressAction
    end
    local hk = hs.hotkey.bind(def.modifiers, def.key, def.pressAction, nil, def.repeatAction)
    table.insert(activeHotkeys, hk)
  end
end

-- 모든 hotkey를 제거
local function disableAllHotkeys()
  for _, hk in ipairs(activeHotkeys) do
    hk:delete()
  end
  activeHotkeys = {}
end

-- 앱이 바뀔 때 hotkey를 업데이트
local function updateHotkeysForApp(bundleId)
  local enable = true
  for _, id in ipairs(ignoredBundleIds) do
    if bundleId == id then
      disableAllHotkeys()
      enable = false
      break
    end
  end
  if enable then
    enableAllHotkeys()
  end
end

local appWatcherCount = 0

-- 앱 전환 감지
appWatcher = hs.application.watcher.new(function(appName, eventType, app)
  local bundleId = app:bundleID()
  appWatcherCount = appWatcherCount + 1
  
  if eventType == hs.application.watcher.activated then
    updateHotkeysForApp(bundleId)
  end

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
end)

appWatcher:start()

addHotKeyDefinition({"ctrl"}, "1", "app", false, "com.googlecode.iterm2")
addHotKeyDefinition({"ctrl"}, "2", "app", false, "com.naver.Whale")
addHotKeyDefinition({"ctrl"}, "3", "app", false, "com.jetbrains.intellij")
addHotKeyDefinition({"ctrl"}, "4", "app", false, "com.jetbrains.datagrip")
addHotKeyDefinition({"ctrl"}, "5", "app", false, "com.apple.finder")
addHotKeyDefinition({"ctrl"}, "e", "app", false, "com.microsoft.VSCode")
addHotKeyDefinition({"ctrl"}, "w", "app", false, "com.kakao.KakaoTalkMac")
addHotKeyDefinition({"ctrl"}, "q", "app", false, "kr.thingsflow.BetweenMac")
addHotKeyDefinition({"ctrl"}, "f", "app", false, "com.apidog.app")
addHotKeyDefinition({"ctrl"}, "left", "moveLeft")
addHotKeyDefinition({"ctrl"}, "right", "moveRight")
addHotKeyDefinition({"ctrl"}, "up", "moveUp")
addHotKeyDefinition({"ctrl"}, "down", "moveDown")
addHotKeyDefinition({"ctrl", "shift"}, "a", "moveLeft")
addHotKeyDefinition({"ctrl", "shift"}, "d", "moveRight")
addHotKeyDefinition({"ctrl", "shift"}, "w", "moveUp")
addHotKeyDefinition({"ctrl", "shift"}, "s", "moveDown")
addHotKeyDefinition({"ctrl"}, "m", "minimize")
addHotKeyDefinition({"ctrl", "shift"}, "x", "minimize")
addHotKeyDefinition({"ctrl"}, "x", "hide")
addHotKeyDefinition({"ctrl", "cmd", "alt"}, "right", "moveRightPair")
addHotKeyDefinition({"ctrl", "cmd", "alt"}, "left", "moveLeftPair")
addHotKeyDefinition({"ctrl", "cmd", "alt"}, "down", "moveDownPair")
addHotKeyDefinition({"ctrl", "cmd", "alt"}, "up", "moveUpPair")
addHotKeyDefinition({"ctrl", "cmd", "shift"}, "up", "moveUpPairHalf")
addHotKeyDefinition({"ctrl", "cmd", "shift"}, "down", "moveDownPairHalf")
addHotKeyDefinition({"ctrl", "cmd", "shift"}, "left", "moveLeftPair")
addHotKeyDefinition({"ctrl", "cmd", "shift"}, "right", "moveRightPair")
addHotKeyDefinition({"ctrl", "shift"}, "=", "expandWindow", true)
addHotKeyDefinition({"ctrl", "shift"}, "-", "reduceWindow", true)
addHotKeyDefinition({"ctrl", "shift"}, "l", "expandHorizontal", true)
addHotKeyDefinition({"ctrl", "shift"}, "j", "reduceHorizontal", true)
addHotKeyDefinition({"ctrl", "shift"}, "i", "expandVertical", true)
addHotKeyDefinition({"ctrl", "shift"}, "k", "reduceVertical", true)
addHotKeyDefinition({"ctrl", "shift"}, "left", "screenLeft")
addHotKeyDefinition({"ctrl", "shift"}, "right", "screenRight")
addHotKeyDefinition({"ctrl", "shift"}, "z", "screenLeft")
addHotKeyDefinition({"ctrl", "shift"}, "c", "screenRight")
addHotKeyDefinition({"ctrl"}, "tab", "toggleMissionControl")
addHotKeyDefinition({"ctrl"}, "`", "toggleAppExpose")
addHotKeyDefinition({"ctrl", "cmd"}, "a", "toggleLaunchPad")
addHotKeyDefinition({"ctrl", "cmd"}, "e", "volumeUp", true)
addHotKeyDefinition({"ctrl", "cmd"}, "w", "volumeDown", true)
addHotKeyDefinition({"ctrl", "cmd"}, "q", "volumeMute")

-- 스크립트 시작 시 현재 앱 상태 반영
updateHotkeysForApp(getFocusedBundleId())