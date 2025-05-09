function toggleAppByBundleID(bundleID)
    local app = hs.application.get(bundleID)

    if not app then
        hs.application.launchOrFocusByBundleID(bundleID)
        return
    end

    local windows = app:allWindows()

    -- 창이 하나도 없을 경우 실행 또는 포커스 시도
    if #windows == 0 then
        hs.application.launchOrFocusByBundleID(bundleID)
        return
    end

    if app:isHidden() or hs.fnutils.every(windows, function(win) return win:isMinimized() end) then
        hs.application.launchOrFocusByBundleID(bundleID)
        for _, win in ipairs(windows) do
            win:unminimize()
        end
        windows[1]:focus()
    elseif app:isFrontmost() then
        app:hide()
    else
        -- 최상단
        hs.application.launchOrFocusByBundleID(bundleID)
        local focused = false
        for _, win in ipairs(windows) do
            if win:isStandard() and win:isVisible() and not win:isMinimized() then
                win:focus()
                focused = true
                break
            end
        end
        if not focused then
            windows[1]:focus()
        end
    end
end

-- 단축키 바인딩 (eventtap 사용, bundleID 기준, skip 기능 포함)
-- modifiers가 정확히 일치하는지 확인하는 함수
function exactModifiersMatch(expected, actual)
    local mods = { "cmd", "ctrl", "alt", "shift", "fn" }
    for _, mod in ipairs(mods) do
        if (actual[mod] or false) ~= (hs.fnutils.contains(expected, mod)) then
            return false
        end
    end
    return true
end

local isKeyAlreadyPressed = false  -- 키가 이미 눌린 상태인지 확인하는 변수
local keyPressCount = 0
local keyTables = {}

keyDownTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    keyPressCount = keyPressCount + 1

    local target = nil
    for _, entry in ipairs(keyTables) do
        local keyCode = hs.keycodes.map[entry.keyChar]
        if event:getKeyCode() == keyCode then
            target = entry
            break
        end
    end

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

    isKeyAlreadyPressed = true  -- 현재 키가 눌린 상태로 설정
    toggleAppByBundleID(target.bundleID)
    return true
end):start()

keyUpTap = hs.eventtap.new({hs.eventtap.event.types.keyUp}, function(event)
    if keyPressCount > 500 then
        keyDownTap:stop(); keyDownTap:start()
        keyUpTap:stop(); keyUpTap:start()
        keyPressCount = 0
        return true
    end

    local target = nil
    for _, entry in ipairs(keyTables) do
        local keyCode = hs.keycodes.map[entry.keyChar]
        if event:getKeyCode() == keyCode then
            target = entry
            break
        end
    end

    if target then
        isKeyAlreadyPressed = false  -- 키가 떼어지면 상태 초기화
    end
end):start()

function bindToggleAppWithEventtap(modifiers, keyChar, targetBundleID, skipIfFrontBundleIDs)
    table.insert(keyTables, {
        modifiers = modifiers,
        keyChar = keyChar,
        bundleID = targetBundleID,
        skipBundleIDs = skipIfFrontBundleIDs
    })
end

-- 바인딩 설정
bindToggleAppWithEventtap({"ctrl"}, "1", "com.googlecode.iterm2", {"com.omnissa.horizon.client.mac"})
bindToggleAppWithEventtap({"ctrl"}, "2", "com.naver.Whale", {"com.omnissa.horizon.client.mac"})
bindToggleAppWithEventtap({"ctrl"}, "3", "com.jetbrains.intellij", {"com.omnissa.horizon.client.mac"})
bindToggleAppWithEventtap({"ctrl"}, "4", "com.jetbrains.datagrip", {"com.omnissa.horizon.client.mac"})
bindToggleAppWithEventtap({"ctrl"}, "5", "com.apple.finder", {"com.omnissa.horizon.client.mac"})
bindToggleAppWithEventtap({"ctrl"}, "e", "com.microsoft.VSCode", {"com.omnissa.horizon.client.mac"})
bindToggleAppWithEventtap({"ctrl"}, "w", "com.kakao.KakaoTalkMac", {"com.omnissa.horizon.client.mac"})
bindToggleAppWithEventtap({"ctrl"}, "q", "kr.thingsflow.BetweenMac", {"com.omnissa.horizon.client.mac"})