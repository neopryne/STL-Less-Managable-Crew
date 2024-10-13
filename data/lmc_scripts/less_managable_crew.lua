local userdata_table = mods.multiverse.userdata_table
local vter = mods.multiverse.vter
local get_room_at_location = mods.vertexutil.get_room_at_location
local random_point_radius = mods.vertexutil.random_point_radius
local TILE_SIZE = 35
local REDIRECT_RADIUS = TILE_SIZE * 2
local OWNSHIP = 0
local ENEMY_SHIP = 1
local global = Hyperspace.Global.GetInstance()

--maybe this should only apply to your crew.
script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crewmem)
    not_f22 = not (crewmem:GetSpecies() == "fff_f22")
    is_player_crew = crewmem.iShipId == OWNSHIP
  if (not_f22 and is_player_crew) then
    local shipManager = global:GetShipManager(crewmem.iShipId)
    local new_room = 0
    local new_slot = 0
    --print(crewmem.currentSlot.roomId)
    local crewTable = userdata_table(crewmem, "mods.less_managable_crew.crewDestinationTracker")
    if crewTable.previousDestination and
        (crewmem.currentSlot.roomId ~= crewTable.previousDestination.roomId or crewmem.currentSlot.slotId ~= crewTable.previousDestination.slotId) then
          crewTable.moving_to_new_dest = true
        --print("Crew ", crewmem:GetLongName(), " changed destination!  old ", crewTable.previousDestination.roomId, " ", crewTable.previousDestination.slotId, "new ", crewmem.currentSlot.roomId, " ", crewmem.currentSlot.slotId)

        local x = crewmem.currentSlot.worldLocation.x
        local y = crewmem.currentSlot.worldLocation.y
        radius = REDIRECT_RADIUS
        local new_dest_point = random_point_radius(crewmem.currentSlot.worldLocation, radius)

        new_room = get_room_at_location(shipManager, new_dest_point, false)
        --failed to land in a room, shunt loop towards original destination. reduce radius until it is zero.
        while new_room == -1 do
          --redo circle stuff, but smaller.  You can upgrade the lab to reduce the circle size.
          radius = math.min(0, radius - .5)
          new_dest_point = random_point_radius(crewmem.currentSlot.worldLocation, radius)
          new_room = get_room_at_location(shipManager, new_dest_point, false)
        end
        
        --redirect crew to location.  Random slot for now due to limitations.
        local shipGraph = Hyperspace.ShipGraph.GetShipInfo(crewmem.iShipId)
        local shape = shipGraph:GetRoomShape(new_room)
        local width = shape.w / TILE_SIZE
        local height = shape.h / TILE_SIZE
        local count_of_tiles_in_room = width * height
        new_slot = math.floor(math.random() * count_of_tiles_in_room) --zero indexed

        crewmem:MoveToRoom(new_room, new_slot, false)
        
        crewTable.previousDestination = {roomId = new_room, slotId = new_slot}
    else
        crewTable.previousDestination = {roomId = crewmem.currentSlot.roomId, slotId = crewmem.currentSlot.slotId}
    end
  end
end)