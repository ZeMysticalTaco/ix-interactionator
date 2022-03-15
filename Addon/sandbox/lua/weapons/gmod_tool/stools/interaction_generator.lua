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
end
function TOOL:AddEvent(eventType, eventData)
end
function TOOL.BuildCPanel(panel)
end
