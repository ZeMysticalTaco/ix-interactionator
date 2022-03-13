TRIGGER.name = 'Player Enters Distance'
TRIGGER.distance = 0

function TRIGGER:ShouldFire(playerList)
    if not self.event then return false end
    local entity = self.event.entity
    if not IsValid(entity) then return false end

    for i = 1, #playerList do
        local pl = playerList[i]
        if not IsValid(pl) then continue end
        local pos = pl:GetPos()
        local ourPos = entity:GetPos()
        local dist = pos:Distance(ourPos)
        if dist > self.distance then continue end
        --The only applicable and valid condition for this.
        --Is that a player is within distance, no other condition.
        return true
    end

    return false
end