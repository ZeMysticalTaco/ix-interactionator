ix.interaction.trigger = { }
ix.interaction.trigger.triggers = { }
--Object
ix.meta.interaction = ix.meta.interaction or { }
ix.meta.interaction.trigger = INTERACTION_TRIGGER_META or ix.middleclass('interactionTriggers')
local META = ix.meta.interaction.trigger

function META:Initialize(uniqueID)
    self.uniqueID = uniqueID
    self.event = ''
    ix.interaction.trigger.triggers[uniqueID] = self
end

function META:AttachToEvent(eventID)
end

function META:ShouldFire(playerList)
    return false
end

--Loads an object from a directory.
local function GenerateUniqueID(s)
    return s:sub(4, -5)
end

function ix.interaction.trigger.LoadFromDir(directory)
    --Loop through the directory for all lua files.
    for _, v in ipairs(file.Find(directory .. '/*.lua', 'LUA')) do
        local objectUniqueID = GenerateUniqueID(v)
        TRIGGER = ix.meta.interaction.trigger:New(objectUniqueID)
        --Include the file.
        ix.util.Include(directory .. '/' .. v)
        TRIGGER = nil
    end
end

--Stored reference to your object[for top level access]
INTERACTION_TRIGGER_META = ix.meta.interaction.trigger
--Typically is PLUGIN.folder .. '/interactionTrigger'
ix.interaction.trigger.LoadFromDir(PLUGIN.folder .. '/triggers')