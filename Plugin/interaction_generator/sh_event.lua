ix.interaction.event = ix.interaction.event or { }
ix.interaction.event.events = { }
--Object Globals
ix.meta.interaction = ix.meta.interaction or { }
ix.meta.interaction.event = INTERACTION_EVENT_META or ix.middleclass('interactionEvent')
local META = ix.meta.interaction.event

function META:Initialize(uniqueID)
    self.uniqueID = uniqueID
    self.trigger = { }
    self.entity = false
    ix.interaction.event.events[uniqueID] = self
end

function META:AttachTrigger(triggerID)
    self.trigger[#self.trigger + 1] = triggerID
end

--Create a new instance of this event.
function META:Instance(eventData)
end

--Some events may have conditions where they cannot fire. Override this to enable that behvior.
function META:ShouldFire()
    return true
end

function META:OnFire()
end

--@internal
function META:FireEvent()
    if self:ShouldFire() then
        self:OnFire()
    end
end

local function GenerateUniqueID(s)
    return s:sub(4, -5)
end

--Loads an object from a directory.
function ix.interaction.event.LoadFromDir(directory)
    --Loop through the directory for all lua files.
    for _, v in ipairs(file.Find(directory .. '/*.lua', 'LUA')) do
        local objectUniqueID = GenerateUniqueID(v)
        EVENT = ix.meta.interaction.event:New(objectUniqueID)
        --Include the file.
        ix.util.Include(directory .. '/' .. v)
        EVENT.field = EVENT.field or 'Unknown'
        EVENT = nil
    end
end

--Stored reference to your object[for top level access]
INTERACTION_EVENT_META = ix.interaction.event.meta
--Typically is PLUGIN.folder .. '/event'
ix.interaction.event.LoadFromDir(PLUGIN.folder .. '/events')

-------------------------------------
function ix.interaction.event.NewEvent(eventType, eventData)
    local ev = ix.interac
end

function ix.interaction.GetEvents()
    return ix.interaction.event.events
end

function ix.interaction.GetEvent(eventID)
    return ix.interaction.GetEvents()[eventID]
end
