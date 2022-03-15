--todo, not shitty.
--globals for rendering
INTERACTION_IS_ENT_SELECTED = nil
INTERACTION_SELECTED_ENTITY = nil
TOOL.Category = 'Helix'
TOOL.Name = 'Interactionator'
TOOL.Command = nil
TOOL.ConfigName = ''
TOOL.LeftClickAutomatic = false
TOOL.RightClickAutomatic = false
if CLIENT then
    TOOL.Information = {
        {
            name = "info",
            stage = 1
        },
        {
            name = 'info_marker'
        },
        {
            name = "left",
            stage = 1,
        },
        {
            name = "right_select_prompt",
            stage = 0
        },
        {
            name = 'right_select_prompt_selected',
            stage = 1
        }
    }

    language.Add('tool.interaction_generator.desc', 'Configure the event in the spawnmenu')
    language.Add('tool.interaction_generator.info', 'Props with interactions are only highlighted for those in observer.')
    language.Add('tool.interaction_generator.left', 'Apply Interaction')
    language.Add('tool.interaction_generator.info_marker', 'Create markers with /marker [name] [bSendToClients]')
    language.Add('tool.interaction_generator.name', 'Interactionator')
    language.Add('tool.interaction_generator.right_select_prompt', 'Select an entity')
    language.Add('tool.interaction_generator.right_select_prompt_selected', 'Select another entity, or select the world to deselect.')
    language.Add('tool.interaction_generator.1', 'Now edit the interaction in the spawn menu, or left click to apply it.')
end

function TOOL:LeftClick(trace)
    --@todo privilege check
    if not IsFirstTimePredicted() then return true end --This is stupid.
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

function TOOL:Notify(msg)
    INTERACTION_NOTIFICATIONS[#INTERACTION_NOTIFICATIONS + 1] = msg
end

function TOOL:RightClick(trace)
    if not IsFirstTimePredicted() then return true end

    if trace.HitWorld then
        self:SetStage(0)

        if CLIENT then
            INTERACTION_IS_ENT_SELECTED = false
            INTERACTION_SELECTED_ENTITY = nil
            self:Notify('Unselected Entity.')

            return true
        end

        return true
    end

    local ent = trace.Entity
    if not IsValid(ent) then return false end
    self:SetStage(1)

    if CLIENT then
        INTERACTION_IS_ENT_SELECTED = true
        --We must allocate an array type for halo drawing in order to avoid creating a new table each frame. This adds an operational complexity to this variable's lookup!
        INTERACTION_SELECTED_ENTITY = { ent }
        self:Notify(Format('Selected Entity: %s (%s)', ent:EntIndex(), ent:GetClass()))

        return true
    end

    return true
end

hook.Add('PreDrawHalos', 'interactionTOOL.DrawHaloAroundObject', function()
    if INTERACTION_IS_ENT_SELECTED then
        halo.Add(INTERACTION_SELECTED_ENTITY, color_white, 1, 1, 1, 1, 1)
    end
end)

INTERACTION_NOTIFICATIONS = { }

function TOOL:DrawHUD()
    local scrw = ScrW() -- @todo figure out better way to cache this, could create a lookup bump in performance.
    local scrh = ScrH()
    surface.SetFont('DebugFixed')
    local totalHeight = 0

    for k, v in pairs(INTERACTION_NOTIFICATIONS) do
        local txw, txh = surface.GetTextSize(v)
        draw.DrawText(v, 'DebugFixed', scrw - (txw + 32), 128 + totalHeight, col, TEXT_ALIGN_LEFT) --add height of text?
        totalHeight = totalHeight + (txh + 8)
    end

    if totalHeight > scrh * .5 then
        table.remove(INTERACTION_NOTIFICATIONS, 1)
    end

    if CurTime() % 5 == 0 and #INTERACTION_NOTIFICATIONS > 1 then
        table.remove(INTERACTION_NOTIFICATIONS, 1)
    end
end

function TOOL:DrawToolScreen(width, height)
    -- Draw black background
    surface.SetDrawColor(Color(20, 20, 20))
    surface.DrawRect(0, 0, width, height)
    -- Draw white text in middle
    draw.SimpleText("Interactionator", "DermaLarge", width / 2, 32, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if INTERACTION_IS_ENT_SELECTED then
        draw.DrawText(Format('Entity: %s', INTERACTION_SELECTED_ENTITY[1]:GetClass()), 'DermaLarge', 8, 32 + 32, color_white, TEXT_ALIGN_LEFT)
    end
end
end
function TOOL:AddEvent(eventType, eventData)
end
--This can be applied to any dform really.
--Creates a quick dpanel and makes it paint a color, used in BuildCPanel for a divider.
local function DividerLine(dform, lineHeight, color, insetL, insetR)
    local pn = vgui.Create('DPanel')
    pn:SetTall(lineHeight)

    --hacky way to set margins manually within the spawnmenu.
    pn.Paint = function(self, width, height)
        surface.SetDrawColor(color)
        surface.DrawRect(0, 0, width, height)
    end

    dform:AddItem(pn)
    pn:DockPadding(insetL or 32, 0, insetR or 32, 0)
    pn:DockMargin(0, 0, 0, 128)

    return pn
end

local function EmptySpacer(dform, height)
    local pn = vgui.Create('DPanel')
    pn:SetTall(height)
    pn.Paint = function() end
    dform:AddItem(pn)

    return pn
end
local function ComboPaint(self, width, height)
    surface.SetDrawColor(color_black)
    surface.DrawOutlinedRect(0,0,width,height,1)
end
local function PresetList(dform, controlHelp, presetType)
    dform:ControlHelp(controlHelp)
    local pn = vgui.Create('DPanel')
    
    local addPresetButton = pn:Add('DButton')
    addPresetButton:SetIcon('icon16/add.png')
    addPresetButton:SetText('')
    addPresetButton:SetWide(32)
    addPresetButton:Dock(LEFT)
    addPresetButton.Paint = function() end
    local cmb = pn:Add('DComboBox')
    cmb.PaintOver = ComboPaint
    cmb:SetTextColor(color_black)
    cmb:Dock(FILL)
    cmb:AddChoice('FILLER_SELECTION_OPTION')
    dform:AddItem(pn)
end

local function CollapsibleCategory(dform, categoryTitle)
    local cat = vgui.Create('DCollapsibleCategory')
    cat:SetLabel(categoryTitle)
    dform:AddItem(cat)

    return cat
end

local toolTutorial = { 'PRE-RELEASE', 'The Interactionator is a tool used to generate interactions on any entity.', 'An interaction is composed of one or several events, which have a trigger, that trigger is unique to that event.', 'Triggers can have delays, and can vary in type within the interaction, allowing you to dynamically link actions together.', 'You can also make interactions trigger other interactions, if that interaction has a name.', 'The events available vary based on the entity selected. A single entity can only have one interaction. ', 'Currently, only physics props are officially supported. Use on other entities at your own risk.' }
local function ComboBox(dform, label, opts)
    local cmb, label = dform:ComboBox(label, '')
    for k, v in pairs(opts) do
        cmb:AddChoice(v)
    end
    cmb:SetTextColor(color_black)
    cmb:SizeToContents()
    cmb.PaintOver = ComboPaint
end

local function BuildTriggerSettingsCategory(dform, category)
    local pn = vgui.Create('DPanel')
    pn:SetTall(150)
    local tbn = pn:Add('DButton')
    tbn:SetText('Fuck')
    category:SetContents(pn)

end
function TOOL.BuildCPanel(panel)
    --@todo fill
    -- panel:Help('Tool tutorial:\nJust use the tool omegalul')
    DividerLine(panel, 2, Color(100, 100, 100, 100))
    for i = 1, #toolTutorial do
        panel:Help(toolTutorial[i])
    end

    DividerLine(panel, 2, Color(100, 100, 100, 100))
    EmptySpacer(panel, 8)
    PresetList(panel, 'You can load a preset interaction below.', 'interaction')
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
    DividerLine(panel, 2, Color(100, 100, 100, 100))
    -- DividerLine(panel, 1, color_black)
    panel:Help('Event Settings')
    EmptySpacer(panel, 2)
    PresetList(panel, 'You can load a preset event below.', 'event')
    -- EmptySpacer(panel, 4)
    -- DividerLine(panel, 2, Color(100, 100, 100, 100))
    -- DividerLine(panel, 1, color_black)
    EmptySpacer(panel, 3)
    -- panel:ControlHelp('Event Type')
    panel:ControlHelp('An event name is only required if this event should be triggered manually, or by another event.')
    panel:TextEntry('Event Name', '')
    -- panel:ComboBox('Event Type', '')
    ComboBox(panel, 'Event Type', {'Razzle', 'My fucking', 'Dazzle'})
    EmptySpacer(panel, 3)
    panel:Help('Execution Options')
    EmptySpacer(panel, 4)
    panel:NumberWang('Event Delay', '', 0, 30000)
    EmptySpacer(panel, 4)
    DividerLine(panel, 1, color_black)
    EmptySpacer(panel, 4)
    CollapsibleCategory(panel, 'Event Specific Settings')
    EmptySpacer(panel, 16)
    panel:Help('Trigger Settings')
    ComboBox(panel, 'Trigger Type', {'Manual'})
    local triggerCategory = CollapsibleCategory(panel, 'Trigger Specific Settings')
    BuildTriggerSettingsCategory(panel, triggerCategory)
end
end
