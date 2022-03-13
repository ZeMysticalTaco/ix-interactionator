ig_test = {}
ig_test.results = {}



ig_test.events = {}

function ig_test.events.TestEventCreation()
    local eventEntity = ix.interaction.GetEvent('entity')
    local ev = eventEntity:Instance({marker = 'marker_test'})
    PrintTable(ev)
    print('event', ev.__index)
    print(ev)
end
function ig_test.testEvents()
    ig_test.events.TestEventCreation()
end

ig_test.testEvents()