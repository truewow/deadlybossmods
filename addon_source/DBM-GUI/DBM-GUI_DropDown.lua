-- *********************************************************
-- **               Deadly Boss Mods - GUI                **
-- **            http://www.deadlybossmods.com            **
-- *********************************************************
--
-- This addon is written and copyrighted by:
--    * Paul Emmerich (Tandanu @ EU-Aegwynn) (DBM-Core)
--    * Martin Verges (Nitram @ EU-Azshara) (DBM-GUI)
--
-- The localizations are written by:
--    * enGB/enUS: Tandanu                http://www.deadlybossmods.com
--    * deDE: Tandanu                    http://www.deadlybossmods.com
--    * zhCN: Diablohu                    http://wow.gamespot.com.cn
--    * ruRU: BootWin                    bootwin@gmail.com
--    * zhTW: Hman                        herman_c1@hotmail.com
--    * zhTW: Azael/kc10577                kc10577@hotmail.com
--    * koKR: BlueNyx                    bluenyx@gmail.com
--    * esES: Interplay/1nn7erpLaY      http://www.1nn7erpLaY.com
--
-- Special thanks to:
--    * Arta (DBM-Party)
--    * Omegal @ US-Whisperwind (some patches, and DBM-Party updates)
--    * Tennberg (a lot of fixes in the enGB/enUS localization)
--
--
-- The code of this addon is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 3.0 License. (see license.txt)
-- All included textures and sounds are copyrighted by their respective owners, license information for these media files can be found in the modules that make use of them.
--
--
--  You are free:
--    * to Share - to copy, distribute, display, and perform the work
--    * to Remix - to make derivative works
--  Under the following conditions:
--    * Attribution. You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work). (A link to http://www.deadlybossmods.com is sufficient)
--    * Noncommercial. You may not use this work for commercial purposes.
--    * Share Alike. If you alter, transform, or build upon this work, you may distribute the resulting work only under the same or similar license to this one.
--

do 
    local MAX_BUTTONS = 10
    local TabFrame1 = CreateFrame("Frame", "DBM_GUI_DropDown", UIParent)
    TabFrame1:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile=1, tileSize=32, edgeSize=32, 
        insets={left=11, right=12, top=12, bottom=11}
    });
    TabFrame1:EnableMouseWheel(1)
    TabFrame1:SetScript("OnMouseWheel", function(self, arg1) 
        if arg1 > 0 then  -- scroll up
            self.offset = self.offset - 1
            if self.offset < 0 then
                self.offset = 0
            end
        else          -- scroll down
            self.offset = self.offset + 1
        end    
        self:Refresh()
    end)
    TabFrame1:Hide()
    TabFrame1:SetParent( DBM_GUI_OptionsFrame )
    TabFrame1:SetFrameStrata("TOOLTIP")

    TabFrame1.offset = 0

    local function ButtonDefaultFunction(self)
        self:GetParent():HideMenu()

        self:GetParent().dropdown.value = self.entry.value
        self:GetParent().dropdown.text = self.entry.text

        if self.entry.sound then
            PlaySoundFile(self.entry.value)
        end
        
        if self.entry.func then
            self.entry.func(self.entry.value)
        end
        if self:GetParent().dropdown.callfunc then
            self:GetParent().dropdown.callfunc(self.entry.value)
        end
        getglobal(self:GetParent().dropdown:GetName().."Text"):SetText(self.entry.text)
    end

    TabFrame1.buttons = {}
    for i=1, MAX_BUTTONS, 1 do
        TabFrame1.buttons[i] = CreateFrame("Button", TabFrame1:GetName().."Button"..i, TabFrame1, "DBM_GUI_DropDownMenuButtonTemplate")
        TabFrame1.buttons[i]:SetScript("OnClick", ButtonDefaultFunction)
        if i == 1 then
            TabFrame1.buttons[i]:SetPoint("TOPLEFT", TabFrame1, "TOPLEFT", 11, -13)
        else
            TabFrame1.buttons[i]:SetPoint("TOPLEFT", TabFrame1.buttons[i-1], "BOTTOMLEFT", 0,0)
        end
    end
    local default_button_width = TabFrame1.buttons[1]:GetWidth()
    TabFrame1:SetWidth(default_button_width+22)
    TabFrame1:SetHeight(MAX_BUTTONS*TabFrame1.buttons[1]:GetHeight()+24)

    TabFrame1.text = TabFrame1:CreateFontString(TabFrame1:GetName().."Text", 'BACKGROUND')
    TabFrame1.text:SetPoint('CENTER', TabFrame1, 'BOTTOM', 0, 0)
    TabFrame1.text:SetFontObject('GameFontNormalSmall')
    TabFrame1.text:SetText("scroll with mouse")
    TabFrame1.text:Hide()

    local BackDropTable = { bgFile = "" }
    function TabFrame1:ShowMenu(values)
        self:Show()
        if self.offset > #values-MAX_BUTTONS then self.offset = #values-MAX_BUTTONS end
        if self.offset < 0 then self.offset = 0 end

        if #values > MAX_BUTTONS then
            self:SetHeight(MAX_BUTTONS*TabFrame1.buttons[1]:GetHeight()+24)
            self.text:Show()
        elseif #values == MAX_BUTTONS then
            self:SetHeight(MAX_BUTTONS*TabFrame1.buttons[1]:GetHeight()+24)
            self.text:Hide()
        elseif #values < MAX_BUTTONS then
            self:SetHeight( #values * self.buttons[1]:GetHeight() + 24)
            self.text:Hide()
        end

        for i=1, MAX_BUTTONS, 1 do
            if i + self.offset <= #values then
                self.buttons[i]:SetText(values[i+self.offset].text)
                self.buttons[i].entry = values[i+self.offset]
                if values[i+self.offset].texture then
                    BackDropTable.bgFile = values[i+self.offset].texture
                    self.buttons[i]:SetBackdrop(BackDropTable)
                end
                if values[i+self.offset].font then
                    _G[self.buttons[i]:GetName().."NormalText"]:SetFont(values[i+self.offset].font, values[i+self.offset].fontsize or 14)
                else
                    _G[self.buttons[i]:GetName().."NormalText"]:SetFont(STANDARD_TEXT_FONT, 10)
                end
                self.buttons[i]:Show()
            else
                self.buttons[i]:Hide()
            end
        end

        local width = self.buttons[1]:GetWidth()
        local bwidth = 0
        for k, button in pairs(self.buttons) do
            bwidth = button:GetTextWidth()
            if bwidth > width then
                TabFrame1:SetWidth(bwidth+32)
                width = bwidth
            end
        end
        for k, button in pairs(self.buttons) do
            button:SetWidth(width)
        end

    end

    function TabFrame1:HideMenu()
        for i=1, MAX_BUTTONS, 1 do
            self.buttons[i]:Hide()
            self.buttons[i]:SetBackdrop(nil)
            self.buttons[i]:SetWidth(default_button_width)
            _G[self.buttons[i]:GetName().."NormalText"]:SetFontObject(GameFontHighlightSmall)
        end
        self:SetWidth(default_button_width+22)
        self:Hide()
        self.text:Hide()
    end

    function TabFrame1:Refresh()
        self:ShowMenu(self.dropdown.values)
    end

    local FrameTitle = "DBM_GUI_DropDown"

    function DBM_GUI:CreateDropdown(title, values, selected, callfunc, width)
        -- Check Values
        self:CheckValues(values)
    
        -- Create the Dropdown Frame
        local dropdown = CreateFrame("Frame", FrameTitle..self:GetNewID(), self.frame, "DBM_GUI_DropDownMenuTemplate")
        dropdown.creator = self
        dropdown.values = values
        dropdown.callfunc = callfunc
        dropdown:SetWidth((width or 120)+30)    -- required to fix some setpoint problems
        getglobal(dropdown:GetName().."Middle"):SetWidth(width or 120)
        getglobal(dropdown:GetName().."Button"):SetScript("OnClick", function(self)
            PlaySound("igMainMenuOptionCheckBoxOn")
            if TabFrame1:IsShown() then
                TabFrame1:HideMenu()
                TabFrame1.dropdown = nil
            else    
                TabFrame1:ClearAllPoints()
                TabFrame1:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -3)
                TabFrame1.dropdown = self:GetParent()
                TabFrame1:ShowMenu(self:GetParent().values)
            end
        end)

        for k,v in next, dropdown.values do
            if v.value ~= nil and v.value == selected or v.text == selected then
                getglobal(dropdown:GetName().."Text"):SetText(v.text)
                dropdown.value = v.value
                dropdown.text = v.text
            end
        end

        if not (not title or title == "") then
            dropdown.titletext = dropdown:CreateFontString(FrameTitle..self:GetCurrentID().."Text", 'BACKGROUND')
            dropdown.titletext:SetPoint('BOTTOMLEFT', dropdown, 'TOPLEFT', 21, 0)
            dropdown.titletext:SetFontObject('GameFontNormalSmall')
            dropdown.titletext:SetText(title)
        end

        return dropdown
    end
end

function DBM_GUI:CheckValues(values)
    if type(values) == "table" then
        for _,entry in next,values do
            entry.text = entry.text or "Missing entry.text"
            entry.value = entry.value or entry.text
        end
    end
    return false
end




