-- Create the main frame
local QuestCompletedFrame = CreateFrame("Frame", "QuestCompletedFrame", UIParent, "BasicFrameTemplateWithInset")
_G["QuestCompletedFrame"] = QuestCompletedFrame -- Make frame globally accessible
table.insert(UISpecialFrames, "QuestCompletedFrame") -- Register for Escape key closure
QuestCompletedFrame:SetSize(220, 110)
QuestCompletedFrame:SetPoint("CENTER")
QuestCompletedFrame:Hide()
QuestCompletedFrame:SetMovable(true)
QuestCompletedFrame:EnableMouse(true)
QuestCompletedFrame:RegisterForDrag("LeftButton")
QuestCompletedFrame:SetScript("OnDragStart", QuestCompletedFrame.StartMoving)
QuestCompletedFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    QuestCompletedDB = QuestCompletedDB or {}
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    QuestCompletedDB.point = point
    QuestCompletedDB.relativePoint = relativePoint
    QuestCompletedDB.xOfs = xOfs
    QuestCompletedDB.yOfs = yOfs
end)

-- Restore saved position on load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "QuestCompleted" then
        if QuestCompletedDB and QuestCompletedDB.point and QuestCompletedDB.xOfs and QuestCompletedDB.yOfs then
            QuestCompletedFrame:ClearAllPoints()
            QuestCompletedFrame:SetPoint(QuestCompletedDB.point, UIParent, QuestCompletedDB.relativePoint or "CENTER", QuestCompletedDB.xOfs, QuestCompletedDB.yOfs)
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Title
QuestCompletedFrame.Title = QuestCompletedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
QuestCompletedFrame.Title:SetPoint("TOP", 0, -5)
QuestCompletedFrame.Title:SetText("Is Quest Completed?")

-- Status message (above EditBox) with icon to the left
QuestCompletedFrame.StatusText = QuestCompletedFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
QuestCompletedFrame.StatusText:SetPoint("CENTER", 0, 19)
QuestCompletedFrame.StatusText:Hide()

QuestCompletedFrame.StatusIcon = QuestCompletedFrame:CreateTexture(nil, "OVERLAY")
QuestCompletedFrame.StatusIcon:SetSize(20, 20)
QuestCompletedFrame.StatusIcon:SetPoint("LEFT", 12, -2)
QuestCompletedFrame.StatusIcon:Hide()

-- EditBox for quest ID
QuestCompletedFrame.EditBox = CreateFrame("EditBox", nil, QuestCompletedFrame, "InputBoxTemplate")
QuestCompletedFrame.EditBox:SetSize(140, 20)
QuestCompletedFrame.EditBox:SetPoint("CENTER", 0, -2)
QuestCompletedFrame.EditBox:SetJustifyH("LEFT")
QuestCompletedFrame.EditBox:SetFontObject("ChatFontNormal")
QuestCompletedFrame.EditBox:SetAutoFocus(false)
-- Restrict to numbers only
QuestCompletedFrame.EditBox:SetScript("OnChar", function(self, char)
    if not char:match("%d") then
        return -- Allow only digits
    end
end)

-- Placeholder text
QuestCompletedFrame.Placeholder = QuestCompletedFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
QuestCompletedFrame.Placeholder:SetPoint("LEFT", QuestCompletedFrame.EditBox, "LEFT", 5, 0)
QuestCompletedFrame.Placeholder:SetText("Enter Quest ID")
QuestCompletedFrame.Placeholder:SetTextColor(0.5, 0.5, 0.5, 1)
QuestCompletedFrame.Placeholder:Show()

-- Function to update status (icon, text, and quest title with cases)
local function UpdateStatus(questId)
    local questTitle = C_QuestLog.GetTitleForQuestID(questId)
    if not questTitle or questTitle == "" then
        -- Case 1: Not Found
        QuestCompletedFrame.StatusIcon:Hide()
        QuestCompletedFrame.StatusText:SetText("Quest Not Found")
        QuestCompletedFrame.StatusText:SetTextColor(1, 0, 0) -- Red
    else
        QuestCompletedFrame.StatusIcon:Show()
        if #questTitle > 33 then
            local startLen = 15 -- Characters from the start
            local endLen = 15 -- Characters from the end
            questTitle = string.sub(questTitle, 1, startLen) .. "…" .. string.sub(questTitle, -endLen)
        end
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId)
        if not isCompleted then
            -- Case 2: Found, Not Complete
            QuestCompletedFrame.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
            QuestCompletedFrame.StatusIcon:SetVertexColor(1, 1, 0) -- Yellow
            QuestCompletedFrame.StatusText:SetText(questTitle)
            QuestCompletedFrame.StatusText:SetTextColor(1, 1, 0) -- Yellow
        else
            -- Case 3: Found, Complete
            QuestCompletedFrame.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
            QuestCompletedFrame.StatusIcon:SetVertexColor(0, 1, 0) -- Green
            QuestCompletedFrame.StatusText:SetText(questTitle)
            QuestCompletedFrame.StatusText:SetTextColor(0, 1, 0) -- Green
        end
    end
    
    QuestCompletedFrame.StatusText:Show()
    QuestCompletedFrame.Placeholder:Hide()
end

-- EditBox scripts
QuestCompletedFrame.EditBox:SetScript("OnEnterPressed", function(self)
    local cleaned_string = string.gsub(self:GetText(), "%D", "")
    QuestCompletedFrame.EditBox:SetText(cleaned_string)    
    local questId = tonumber(cleaned_string)
    if questId then
        UpdateStatus(questId)
    else
        QuestCompletedFrame.StatusIcon:Hide()
        QuestCompletedFrame.StatusText:Hide()
        if self:GetText() == "" then
            QuestCompletedFrame.Placeholder:Show()
        end
    end
end)
QuestCompletedFrame.EditBox:SetScript("OnEscapePressed", function(self)
    if self:HasFocus() then
        -- If EditBox has focus, lose focus but keep popup open
        self:ClearFocus()
    end
end)
QuestCompletedFrame.EditBox:SetScript("OnTextChanged", function(self)
    QuestCompletedFrame.StatusIcon:Hide()
    QuestCompletedFrame.StatusText:Hide()
    if self:GetText() == "" then
        QuestCompletedFrame.Placeholder:Show()
    else
        QuestCompletedFrame.Placeholder:Hide()
    end
end)

-- Clear button (bottom left)
QuestCompletedFrame.ClearButton = CreateFrame("Button", nil, QuestCompletedFrame, "UIPanelButtonTemplate")
QuestCompletedFrame.ClearButton:SetSize(70, 20)
QuestCompletedFrame.ClearButton:SetPoint("BOTTOMLEFT", 15, 15)
QuestCompletedFrame.ClearButton:SetText("Clear")
QuestCompletedFrame.ClearButton:SetScript("OnClick", function()
    QuestCompletedFrame.EditBox:SetText("")
    QuestCompletedFrame.StatusIcon:Hide()
    QuestCompletedFrame.StatusText:Hide()
    QuestCompletedFrame.Placeholder:Show()
    QuestCompletedFrame.EditBox:SetFocus() -- Focus on Clear
end)

-- Enter button (bottom right)
QuestCompletedFrame.EnterButton = CreateFrame("Button", nil, QuestCompletedFrame, "UIPanelButtonTemplate")
QuestCompletedFrame.EnterButton:SetSize(70, 20)
QuestCompletedFrame.EnterButton:SetPoint("BOTTOMRIGHT", -15, 15)
QuestCompletedFrame.EnterButton:SetText("Enter")
QuestCompletedFrame.EnterButton:SetScript("OnClick", function()
    local questId = tonumber(QuestCompletedFrame.EditBox:GetText())
    if questId then
        UpdateStatus(questId)
    else
        QuestCompletedFrame.StatusIcon:Hide()
        QuestCompletedFrame.StatusText:Hide()
        if QuestCompletedFrame.EditBox:GetText() == "" then
            QuestCompletedFrame.Placeholder:Show()
        end
    end
end)

-- Slash command
SLASH_QUESTCOMPLETED1 = "/iqc"
SlashCmdList["QUESTCOMPLETED"] = function()
    QuestCompletedFrame:Show()
    QuestCompletedFrame.EditBox:SetText("")
    QuestCompletedFrame.StatusIcon:Hide()
    QuestCompletedFrame.StatusText:Hide()
    QuestCompletedFrame.Placeholder:Show()
    QuestCompletedFrame.EditBox:SetFocus() -- Mimic Clear behavior
end
