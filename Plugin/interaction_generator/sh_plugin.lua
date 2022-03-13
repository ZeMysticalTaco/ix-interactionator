PLUGIN.name = 'Interaction Generator'
PLUGIN.author = 'TomSL #1104 / ZeMysticalTaco'
PLUGIN.description = 'Dave, why do you do the things you do?'
ix.interaction = {}
ix.interaction.entities = {}
ix.interaction.markers = {}
PLUGIN.markers = ix.interaction.markers
PLUGIN.markerIndex = 1
PLUGIN.interactables = {}
--Markers are used with the Interaction Generator. They're used to mark specific points in the world that 
local playerMeta = FindMetaTable('Player')
local PLUGIN = PLUGIN
ix.util.Include('sh_trigger.lua')
ix.util.Include('sh_event.lua')
if SERVER then
    util.AddNetworkString('MarkerSendMarker')
    util.AddNetworkString('MarkerRequestMarkers')
    util.AddNetworkString('MarkerSendMarkers') --SendMarkers is a more efficient version of SendMarker.
    util.AddNetworkString('InteractionGenerator_RequestCurrentEvent')
    util.AddNetworkString('InteractionGenerator_SendCurrentEvent')
    net.Receive('MarkerRequestMarkers', function(len, ply)
        if ply.requestedMarkers then return end --no lag here sir.

        for k, v in pairs(PLUGIN.markers) do
            PLUGIN:SendMarker(ply, v)
        end

        ix.log.AddRaw('Sent all markers to ' .. ply:Name())
        ply.requestedMarkers = true
    end)
end

function PLUGIN:SendMarker(target, marker, bBroadcast)
    net.Start('MarkerSendMarkers')
    net.WriteString(marker.name)
    net.WriteVector(marker.pos)
    net.WriteAngle(marker.ang)
    net.WriteAngle(marker.eyeAng)
    net.WriteUInt(marker.index, 16)

    if bBroadcast then
        net.Broadcast()

        return
    end

    net.Send(target)
end

ix.command.Add('Marker', {
    description = 'Creates a marker at the position and direction you are facing.',
    privilege = 'Production',
    arguments = { ix.type.string, bit.bor(ix.type.bool, ix.type.optional) },
    alias = { 'M' },
    OnRun = function(self, client, markerName, bSendToClients)
        local marker = {
            pos = client:GetPos(),
            eyeAng = client:EyeAngles(),
            ang = client:GetAngles(),
            name = markerName,
            bSendToClients = bSendToClients,
            index = PLUGIN.markerIndex
        }
        PLUGIN.markerIndex = PLUGIN.markerIndex + 1 //increment index for marker UI ID
        PLUGIN.markers[markerName] = marker
        PLUGIN:SendMarker(client, marker)

        if bSendToClients then
            PLUGIN:SendMarker(nil, marker, true)
        end
    end
})

ix.command.Add('MarkerInfo', {
    description = 'Output info about a marker.',
    arguments = ix.type.string,
    privilege = 'Production',
    OnRun = function(self, client, markerName)
        local marker = PLUGIN.markers[markerName]

        if not marker then
            client:Notify('That marker does not exist!')

            return
        end

        local output = {
            pos = 'Marker position: %s',
            ang = 'Marker angles: %s',
            eyeAng = 'Marker eye angles: %s',
            name = 'Marker name: %s',
            index = 'Marker index: %s'
        }

        client:ChatPrint(Format('--MARKER INFO: %s--', marker.name))
        for k, v in pairs(output) do
            client:ChatPrint(Format(v, tostring(marker[k])))
        end
        client:ChatPrint('--END MARKER INFO--')
    end
})

function PLUGIN:SaveMarkers(name)
end

function PLUGIN:LoadMarkers(name)
end

ix.command.Add('SaveMarkers', {
    description = 'Save all currently active markers under a name.',
    arguments = ix.type.text,
    privilege = 'Production',
    OnRun = function(self, client, saveName)
        PLUGIN:SaveMarkers(saveName)
    end
})

ix.command.Add('LoadMarkers', {
    description = 'Load markers from a save file.',
    arguments = ix.type.text,
    privilege = 'Production',
    OnRun = function(self, client, saveName)
        PLUGIN:LoadMarkers(saveName)
    end
})

ix.command.Add('ClearMarkers', {
    description = 'Kills all active markers.',
    privilege = 'Production',
    OnRun = function(self, client)
        PLUGIN.markers = { }
        net.Start('MarkerClearMarkers')
        net.Broadcast()
        ix.log.AddRaw(client:Name() .. ' cleared all markers.')
    end
})

if CLIENT then
    net.Receive('MarkerSendMarker', function(len, ply)
        local marker = net.ReadTable()
        PLUGIN.markers[marker.name] = marker
    end)

    hook.Add('InitPostEntity', 'MarkerLoadActiveMarkers', function()
        net.Start('MarkerRequestMarkers')
        net.SendToServer()
    end)

    net.Receive('MarkerSendMarkers', function()
        local n = net.ReadString()
        local p = net.ReadVector()
        local ang = net.ReadAngle()
        local eyeAng = net.ReadAngle()
        local index = net.ReadUInt(16)

        PLUGIN.markers[n] = {
            pos = p,
            ang = ang,
            eyeAng = eyeAng,
            name = n,
            index = index
        }
    end)
end

ix.util.Include('sh_tests.lua')