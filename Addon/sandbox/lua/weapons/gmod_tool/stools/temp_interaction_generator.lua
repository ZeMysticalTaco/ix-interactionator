--WOO shitty code!
--todo, not shitty.
TOOL.Category = 'Examples'
TOOL.Name = 'Your Tools name'
TOOL.Command = nil
TOOL.ConfigName = ''

if CLIENT then
    language.Add('tool.interaction_generator.desc', 'Configure the event in the spawnmenu')
    language.Add('tool.interaction_generator.0', 'Props with interactions are only highlighted for those in observer.')
    language.Add('tool.interaction_generator.attack', 'Create markers with /marker [name] [bSendToClients]')
    language.Add('tool.interaction_generator.name', 'Taco\'s Entity Interaction Generator')
end

function TOOL:LeftClick(trace)
    --@todo privilege check
    local ent = trace.Entity

    if SERVER then
        if ent:GetClass() == 'prop_physics' then
            net.Start('InteractionGenerator_RequestCurrentEvent')
            net.WriteEntity(ent)
            net.Send(self:GetOwner())
        end

        return true
    end

    if CLIENT then
        ent:EmitSound('buttons/button1.wav', 100)

        return true
    end
end

function TOOL:RightClick(trace)
end

local function AddEvent(eventTab)
    local tab = LocalPlayer().eventData or { } --This table is not instantiated anywhere, @todo, fix that.
    tab[#tab + 1] = eventTab
    eventTab.eventIndex = #tab
    tab.triggerTypes = tab.triggerTypes or { } --ensure triggerType table exists.
    tab.triggerTypes[eventTab.trigger.triggerType] = true
    LocalPlayer().eventData = tab

    return tab
end

local function RemoveEvent(eventID)
    local tab = LocalPlayer().eventData or { }
    tab[eventID] = nil
    LocalPlayer().eventData = tab

    return tab
end

TRACKED_ENTS = TRACKED_ENTS or { } --@todo fix global

if SERVER then
    net.Receive('InteractionGenerator_SendCurrentEvent', function(m_len, ply)
        --decompression
        local len = net.ReadUInt(16)
        local dat = net.ReadData(len)
        local str = util.Decompress(dat)
        local eData = util.JSONToTable(str)
        --
        print('pulled: ', eData)
        local ent = net.ReadEntity()
        eData.ent = ent
        ent.eventData = eData
        ent:SetNetVar('eventEntity', true)
        TRACKED_ENTS[ent] = eData
        print('wack', ent, ent.eventData)
        PrintTable(ent.eventData)
    end)

    local function DoInteractionGeneratorRadiusThink(ent, eData)
        for k, v in pairs(eData) do
            --@todo fix weird indexing
            if isnumber(k) then
                if v.trigger.triggerType == 'enterEvent' then
                    --@todo figure out how to loop based on the max radius and then compare dist.
                    for k2, v2 in pairs(player.GetAll()) do
                        if v2:GetPos():Distance(ent:GetPos()) > v.trigger.triggerData.distance then continue end

                        --@todo extract execution to functions embedded in objects.
                        if v.eventType == 'entityEvent' then
                            local markerID = v.eventData.marker
                            local marker = ix.plugin.list.interaction_generator.markers[markerID]
                            local pos = marker.pos
                            local ang = marker.ang
                            local tNPC = v.eventData.npc
                            local ent = ents.Create(v.eventData.class)
                            ent:SetPos(pos)
                            ent:SetAngles(ang)
                            ent:Spawn()
                            v2:ChatPrint('You triggered something, wow!')
                            eData[k] = nil
                            continue
                        end

                        if v2.eventType == 'textEvent' then end
                    end
                end

                if true then end
            end
        end
    end

    --@todo what the fuck?
    hook.Add('Think', 'InteractionGenerator_BadThink', function()
        for k, v in pairs(TRACKED_ENTS) do
            if v.triggerTypes['enterEvent'] then
                DoInteractionGeneratorRadiusThink(k, v)
            end
        end
    end)
end

if CLIENT then
    --@todo write a net protocol that splits this into individual events, or even keys. these tables are going to get massive
    net.Receive('InteractionGenerator_RequestCurrentEvent', function(len, ply)
        local ent = net.ReadEntity()
        local dat = util.Compress(util.TableToJSON(LocalPlayer().eventData))
        local byteLen = #dat
        print('sending: ', LocalPlayer().eventData)
        PrintTable(LocalPlayer().eventData)
        net.Start('InteractionGenerator_SendCurrentEvent')
        net.WriteUInt(byteLen, 16)
        net.WriteData(dat)
        net.WriteEntity(ent)
        net.SendToServer()
    end)

    hook.Add('PreDrawHalos', 'InteractionGenerator_DrawHalos', function()
        local tab = { }

        for k, v in pairs(ents.GetAll()) do
            if v:GetNetVar('eventEntity') then
                table.insert(tab, ent)
            end
        end

        halo.Add(tab, color_white, 1, 1, 2, 1, 0)
    end)
end

local triggerTypes = {
    ['useEvent'] = {
        holdTime = 0
    },
    ['enterEvent'] = {
        distance = 0
    },
    ['exitEvent'] = {
        distance = 0
    },
    ['phraseEvent'] = {
        triggerPhrase = '',
        distance = 0
    },
    ['triggerEvent'] = {
        triggerName = ''
    },
    ['lookEvent'] = {
        lookTime = 0,
        distance = 0
    }
}

local eventTypes = {
    itemEvent = {
        itemID = 32, --Strings are considered uniqueIDs, so this accepts both types.
        itemSpawnType = '',
        itemSpawnData = { }
    },
    soundEvent = {
        soundFile = '',
        soundPitch = 100,
        soundVolume = 1,
        soundDistance = 1000
    },
    entityEvent = {
        class = '',
        marker = '',
        npc = false or {
            weapon = 'weapon_smg1'
        }
    },
    textEvent = {
        text = '' --todo: {} JankText Data
    },
    commandEvent = {
        command = '',
        playerFilter = false --@p targets triggering player, @s targets self, @n targets nearest player @number targets area
    },
    cameraEvent = {
        markers = { }, --order of string markers to go to.
        speed = 0
    }
}

--Here's an easy to visualize template table.
--@todo Make this an actual meta table.
local meta = {
    eventType = '',
    eventID = 0,
    eventData = { }, --Event type structs are above.
    trigger = {
        triggerType = '',
        triggerData = {
            delay = 0
        }
    }
}

--@todo please... don't.... please fix this... no... dude...
local function PopulateEventData(self, eventType)
    table.Merge(self.eventData, table.Copy(eventTypes[eventType]))
    self.eventType = eventType
end

local function PopulateTriggerData(self, triggerID)
    self.trigger.triggerType = triggerID
    table.Merge(self.trigger.triggerData, table.Copy(triggerTypes[triggerID]))
end

local eventStructure = {
    ['itemEvent'] = {
        eventType = 'itemEvent',
        eventID = 32,
        eventData = {
            item = 32, --Item ID,
            spawnType = 'spawn', --give, spawn
            spawnData = { },
            trigger = {
                triggerType = 'useEvent',
                triggerData = {
                    time = 3,
                    delay = 0
                }
            }
        }
    }
}

function TOOL:AddEvent(eventType, eventData)
end

local function AddEventOption(dmenu, optionText, optionIcon, optionFunc)
    local opt = dmenu:AddOption(optionText, optionFunc)

    if optionIcon then
        opt:SetIcon(optionIcon)
    end

    return opt
end

local function TitleLabel(pn, text)
    if IsValid(pn.Title) then
        pn.Title:Remove()
    end

    pn.Title = pn:Add('DLabel')
    pn.Title:Dock(TOP)
    pn.Title:SetContentAlignment(5)
    pn.Title:SetFont('ixMenuButtonFont')
    pn.Title:SetText(text)
    pn.Title:SizeToContents()
end

local function MarkerPrompt(triggerType, delay, triggerData)
    if IsValid(ix.gui.markerPrompt) then
        ix.gui.markerPrompt:Remove()
    end

    local ui = vgui.Create('DFrame')
    ui:SetSize(800, 720)
    ui:Center()
    ui:MakePopup()
    ui:SetY(8)
    ix.gui.markerPrompt = ui
    local eventPanel = ui:Add('DPanel')
    eventPanel:Dock(LEFT)
    eventPanel:SetWide(ui:GetWide() / 2.1)
    TitleLabel(eventPanel, 'Event')
    ui.eventPanel = eventPanel
    local markerPanel = ui:Add('DPanel')
    markerPanel:Dock(RIGHT)
    markerPanel:SetWide(ui:GetWide() / 2.1)
    local listView = markerPanel:Add('DListView')
    listView:Dock(FILL)
    listView:AddColumn('Marker Name').Header:SetTextColor(color_black)
    listView:AddColumn('Marker ID').Header:SetTextColor(color_black)

    for k, v in pairs(ix.plugin.list.interaction_generator.markers) do
        listView:AddLine(v.name, v.index)
    end

    TitleLabel(markerPanel, 'Select a Marker')
    local optionsContainer = eventPanel:Add('DScrollPanel')
    optionsContainer:Dock(BOTTOM)
    optionsContainer:SetTall(64 * 3) --Helix panels typically dock at about 64px, this accounts for that.
    ui.optionsContainer = optionsContainer
    local bConfirm = optionsContainer:Add('ixMenuButton')
    bConfirm:Dock(TOP)
    bConfirm:SetText('CONFIRM')
    bConfirm:SetContentAlignment(5)
    bConfirm:SizeToContents()
    ui.confirmButton = bConfirm

    function bConfirm:DoClick()
        local _, entLine = ui.list:GetSelectedLine()
        local _, markerLine = listView:GetSelectedLine()
        local bIsNPC = ui.npcButton:GetValue()
        local tab = table.Copy(meta)
        PopulateEventData(tab, 'entityEvent')
        PopulateTriggerData(tab, triggerType.id)
        local eventData = tab.eventData
        eventData.class = entLine:GetColumnText(3)
        local _, class = ui.weapons.setting:GetSelected()

        --@todo increment index of main event ID by grabbing the length of the event storage... whenever you make the event storage.
        eventData.npc = bIsNPC and {
            weapon = class
        }

        eventData.marker = markerLine:GetColumnText(1)
        tab.trigger.triggerData = triggerData
        AddEvent(tab)
        ix.gui.jankylistview:AddLine(tab.eventType, tab.trigger.triggerData.delay, tab.trigger.triggerType)
    end

    return ui
end

local spawnFuncs = {
    textEvent = function() end,
    entityEvent = function(triggeringPlayer) end
}

--MarkerPrompt()
local options = {
    {
        name = 'Text Event',
        icon = 'materials/icon16/page_white_wrench.png',
        prompt = function() end,
        id = 'textEvent'
    },
    --Prompt with text generator.
    -- Derma_StringRequest('Input Text', 'What do you want to output in chat?', table.Random(funnyHaha), function(text) end)
    {
        name = 'Item Event',
        icon = 'materials/icon16/box.png',
        prompt = function() end,
        id = 'itemEvent'
    },
    {
        name = 'Play Sound At',
        icon = 'materials/icon16/sound.png',
        prompt = function() end,
        id = 'soundEvent'
    },
    --Selection UI that you can use to select any item in your inventory.
    --This is going to allow people to give others "custom" items, to enhance story.
    {
        name = 'Spawn Entity At',
        icon = 'materials/icon16/brick.png',
        id = 'entityEvent',
        prompt = function(triggerType, delay, triggerData)
            local markerUI = MarkerPrompt(triggerType, delay, triggerData)
            local canvas = markerUI.eventPanel
            local container = canvas:Add('DPanel')

            local function Populate(bNPCs)
                markerUI.list:Clear()

                for k, v in pairs(bNPCs and list.Get('NPC') or scripted_ents.GetList()) do
                    if bNPCs then
                        markerUI.list:AddLine(v.Name ~= '' and v.Name or v.ClassName, v.Category ~= '' and v.Category or 'None', v.Class)
                        continue
                    end

                    markerUI.list:AddLine(v.t.PrintName ~= '' and v.t.PrintName or v.t.ClassName, v.t.Category ~= '' and v.t.Category or 'None', v.t.ClassName)
                end

                markerUI.list:SortByColumn(1)
            end

            container:Dock(FILL)
            local bIsNPC = markerUI.optionsContainer:Add('ixSettingsRowBool')
            bIsNPC:SetText('NPC')
            bIsNPC:Dock(TOP)

            bIsNPC.OnValueChanged = function()
                markerUI.list:Clear()
                Populate(bIsNPC:GetValue())
            end

            markerUI.npcButton = bIsNPC
            local sWeapon = markerUI.optionsContainer:Add('ixSettingsRowArray')
            sWeapon:SetText('NPC Weapon')
            sWeapon:Dock(TOP)
            sWeapon.setting:SetFont('ixMenuButtonFontSmall')
            markerUI.weapons = sWeapon

            for k, v in pairs(weapons.GetList()) do
                sWeapon.setting:AddChoice(v.PrintName, v.ClassName)
            end

            local listView = container:Add('DListView')
            markerUI.list = listView
            listView:Dock(FILL)
            local n = listView:AddColumn('Name')
            listView:AddColumn('Category').Header:SetTextColor(color_black)
            listView:AddColumn('Class').Header:SetTextColor(color_black)
            Populate(false)
        end
    },
    {
        name = 'Run Command',
        icon = 'materials/icon16/application_xp_terminal.png',
        prompt = function() end,
        id = 'commandEvent'
    },
    --@p for activating player
    {
        name = 'Run Camera',
        icon = 'materials/icon16/camera.png',
        prompt = function() end,
        id = 'cameraEvent'
    }
}

if CLIENT then
    options[3].prompt()
end

local function DistancePrompt(text, eventType, triggerType, timeSeconds)
    Derma_StringRequest('Distance', text, '16', function(text)
        eventType.prompt(triggerType, timeSeconds, {
            distance = tonumber(text),
            delay = timeSeconds
        })
    end)
end

local triggers = {
    {
        name = 'On Enter Distance',
        icon = 'materials/icon16/arrow_right.png',
        promptTitle = 'Input Distance',
        promptText = 'How many units of distance?',
        id = 'enterEvent',
        prompt = function(self, eventType, timeSeconds)
            DistancePrompt('How far away do you want this to trigger from?', eventType, self, timeSeconds)
        end
    },
    -- eventType.prompt(triggerType, timeSeconds)
    --{
    --    name = 'On Exit Distance',
    --    icon = 'materials/icon16/arrow_left.png',
    --    promptTitle = 'Input Distance',
    --    promptText = 'How many units of distance?',
    --    id = 'exitEvent',
    --    prompt = function(self, eventType, timeSeconds)
    --        eventType.prompt(triggerType, timeSeconds)
    --    end
    --},
    {
        name = 'On Use',
        icon = 'materials/icon16/calculator.png',
        promptTitle = 'Input Distance',
        promptText = 'How many units of distance?',
        id = 'useEvent',
        prompt = function(self, eventType, timeSeconds)
            eventType.prompt(triggerType, timeSeconds)
        end
    },
    {
        name = 'On Phrase',
        icon = 'materials/icon16/heart.png',
        promptTitle = 'What Phrase',
        promptText = 'What exact phrase would you like to trigger this event?',
        id = 'phraseEvent',
        prompt = function(self, eventType, timeSeconds)
            eventType.prompt(triggerType, timeSeconds)
        end
    },
    {
        name = 'On Stare At',
        icon = 'materials/icon16/eye.png',
        promptTitle = 'How long',
        promptText = 'How long does someone have to stare at this object to activate the event?',
        id = 'lookEvent',
        prompt = function(self, eventType, timeSeconds)
            eventType.prompt(triggerType, timeSeconds)
        end
    },
    {
        name = 'By Fire Event Command',
        id = 'triggerEvent',
        icon16 = 'materials/icon16/application_osx_terminal.png',
        promptTitle = 'Command Name',
        promptText = 'When you use /FireEvent, what name should this event call under?',
        prompt = function(self, eventType, timeSeconds)
            eventType.prompt(triggerType, timeSeconds)
        end
    }
}

local function Input(eventType, triggerType, timeSeconds)
    triggerType:prompt(eventType, timeSeconds)
    --eventType.prompt(triggerType, timeSeconds)
end

local quickTimeOptions = { 1, 5, 10, 15, 30, 45, 60 }

function TOOL.BuildCPanel(panel)
    panel:Help('You can load a preset event below.')
    local addPresetButton = vgui.Create('DButton')
    addPresetButton:SetIcon('icon16/add.png')
    addPresetButton:SetText('')
    addPresetButton.Paint = function() end
    local cmb = vgui.Create('DComboBox')
    cmb:Dock(FILL)
    panel:AddItem(addPresetButton, cmb)
    addPresetButton:SetWide(48)
    local lv = vgui.Create('DListView')
    panel:AddItem(lv)
    ix.gui.jankylistview = lv
    --We need to manually set the headers text color as black.
    --Since we don't need the columns later, we can just use the func on the object it returns.
    lv:AddColumn('Event').Header:SetTextColor(color_black)
    lv:AddColumn('Delay').Header:SetTextColor(color_black)
    lv:AddColumn('When').Header:SetTextColor(color_black)
    lv:Dock(TOP)
    lv:SetTall(200)
    local addButton = panel:Button('Add Event')

    function addButton:DoClick()
        local dmenu = DermaMenu(true, lv)

        for index, eventType in pairs(options) do
            local opt = AddEventOption(dmenu, eventType.name, eventType.icon)
            local triggerCategory = opt:AddSubMenu('Triggers', function() end)

            for triggerIndex, triggerType in pairs(triggers) do
                local trigger = triggerCategory:AddOption(triggerType.name, function() end)
                trigger:SetIcon(triggerType.icon)
                local timeSubMenu = trigger:AddSubMenu('Delay', function() end)

                timeSubMenu:AddOption('Instant', function()
                    Input(eventType, triggerType, 0)
                end)

                for i = 1, #quickTimeOptions do
                    local timeOpt = timeSubMenu:AddOption(quickTimeOptions[i] .. ' Seconds', function()
                        Input(eventType, triggerType, quickTimeOptions[i])
                    end)

                    timeOpt:SetIcon('materials/icon16/clock.png')
                end

                timeSubMenu:AddOption('Custom', function()
                    Derma_StringRequest('Enter Time', 'Enter the time, in Seconds, that you want to delay this event.', 120)
                end)
            end
        end

        dmenu:Open()
    end
end

local function PackageEvent()
end