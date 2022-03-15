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
end
function TOOL:Notify(msg)
end
function TOOL:RightClick(trace)
end
function TOOL:DrawHUD()
end
function TOOL:DrawToolScreen(width, height)
end
function TOOL:AddEvent(eventType, eventData)
end
function TOOL.BuildCPanel(panel)
end
