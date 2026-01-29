-- Kryos Dungeon Tool
-- UI/Minimap.lua - Minimap button (v1.4 Style)

local addonName, KDT = ...

-- ==================== MINIMAP BUTTON ====================
function KDT:CreateMinimapButton()
    local btn = CreateFrame("Button", "KryosDTMinimap", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)
    
    -- Icon - Same as addon list icon (inv_relics_hourglass)
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\inv_relics_hourglass")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    self.minimapButton = btn
    return btn
end

function KDT:UpdateMinimapPosition()
    if not self.minimapButton then return end
    local angle = math.rad(self.DB and self.DB.minimapPos or 220)
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end

function KDT:SetupMinimapButton()
    local btn = self.minimapButton
    if not btn then return end
    
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            local a = math.deg(math.atan2(py / s - my, px / s - mx))
            if a < 0 then a = a + 360 end
            if KDT.DB then KDT.DB.minimapPos = a end
            KDT:UpdateMinimapPosition()
        end)
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    
    btn:SetScript("OnClick", function(_, button)
        if KDT.MainFrame then
            if KDT.MainFrame:IsShown() then
                KDT.MainFrame:Hide()
            else
                KDT.MainFrame:Show()
                KDT.MainFrame:SwitchTab(button == "RightButton" and "blacklist" or "group")
            end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFF0000Kryos|r Dungeon Tool")
        GameTooltip:AddLine("Left-Click: Open Group Check", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-Click: Open Blacklist", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
