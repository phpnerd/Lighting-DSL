package nl.ru.sws.dsl.lighting.generator.cohla

import nl.ru.sws.dsl.lighting.building.Area
import nl.ru.sws.dsl.lighting.building.Building
import nl.ru.sws.dsl.lighting.building.Corridor
import nl.ru.sws.dsl.lighting.building.Room
import nl.ru.sws.dsl.lighting.building.RoomType

class InterfaceGenerator {

static def generate(Building building, int nrOfActors, boolean separateClasses, boolean separateActors) {
  val hasBasicRoom = building.areas.exists[a | a instanceof Room && (a as Room).type == RoomType.BASIC]
  val hasOffice = building.areas.exists[a | a instanceof Room && (a as Room).type == RoomType.OFFICE]
  val hasOfficeSpace = building.areas.exists[a | a instanceof Room && (a as Room).type == RoomType.OFFICESPACE]
  val hasCorridor = building.areas.exists[a | a instanceof Corridor]
  return
'''
import "FedClasses.hla"
«IF nrOfActors > 0»
import "Actor.hla"
«ENDIF»

«IF !separateClasses»«generateBasicInterfaces("", hasBasicRoom, hasOffice, hasOfficeSpace, hasCorridor, nrOfActors > 0)»
«ELSE»«building.areas.map[a | generateInterfaces(a, nrOfActors, separateActors)].join("\n\n")»
«ENDIF»
'''
}

static def generateBasicInterfaces(String suffix, boolean hasBasicRoom, boolean hasOffice, boolean hasOfficeSpace, boolean hasCorridor, boolean hasActors)
'''
«IF hasBasicRoom»
«basicRoomControllerToOccupancySensor(suffix)»

«basicRoomControllerToDimmableLight(suffix)»

«ENDIF»«IF hasOffice»
«officeControllerToOccupancySensor(suffix)»

«officeControllerToDimmableLight(suffix)»

«ENDIF»«IF hasOfficeSpace»
«officeSpaceControllerToOccupancySensor(suffix)»

«officeSpaceControllerToDimmableLight(suffix)»

«ENDIF»«IF hasCorridor»
«corridorControllerToOccupancySensor(suffix)»

«corridorControllerToDimmableLight(suffix)»

«ENDIF»«IF hasActors»
«occupancySensorToActor(suffix, false)»
«ENDIF»
'''

static def generateInterfaces(Area area, int nrOfActors, boolean separateActors)
'''
«IF area instanceof Room && (area as Room).type == RoomType.BASIC»
«basicRoomControllerToOccupancySensor(area.name.toFirstUpper)»

«basicRoomControllerToDimmableLight(area.name.toFirstUpper)»

«ENDIF»«IF area instanceof Room && (area as Room).type == RoomType.OFFICE»
«officeControllerToOccupancySensor(area.name.toFirstUpper)»

«officeControllerToDimmableLight(area.name.toFirstUpper)»

«ENDIF»«IF area instanceof Room && (area as Room).type == RoomType.OFFICESPACE»
«officeSpaceControllerToOccupancySensor(area.name.toFirstUpper)»

«officeSpaceControllerToDimmableLight(area.name.toFirstUpper)»

«ENDIF»«IF area instanceof Corridor»
«corridorControllerToOccupancySensor(area.name.toFirstUpper)»

«corridorControllerToDimmableLight(area.name.toFirstUpper)»

«ENDIF»«IF nrOfActors > 0»
«occupancySensorToActor(area.name.toFirstUpper, separateActors)»
«ENDIF»
'''

static def basicRoomControllerToOccupancySensor(String suffix)
'''
Interface between BasicRoomController«suffix» and OccupancySensor«suffix» {
  Connection { BasicRoomController«suffix».occupied <- OccupancySensor«suffix».occupied }
}
'''

static def basicRoomControllerToDimmableLight(String suffix)
'''
Interface between BasicRoomController«suffix» and DimmableLight«suffix» {
  Connection { DimmableLight«suffix».setpoint <- BasicRoomController«suffix».setpoint }
}
'''

static def officeControllerToOccupancySensor(String suffix)
'''
Interface between OfficeController«suffix» and OccupancySensor«suffix» {
  Connection { OfficeController«suffix».occupied <- OccupancySensor«suffix».occupied }
}
'''

static def officeControllerToDimmableLight(String suffix)
'''
Interface between OfficeController«suffix» and DimmableLight«suffix» {
  Connection { DimmableLight«suffix».setpoint <- OfficeController«suffix».setpoint }
}
'''

static def officeSpaceControllerToOccupancySensor(String suffix)
'''
Interface between OfficeSpaceController«suffix» and OccupancySensor«suffix» {
  Connection { OfficeSpaceController«suffix».occupied <- OccupancySensor«suffix».occupied }
}
'''

static def officeSpaceControllerToDimmableLight(String suffix)
'''
Interface between OfficeSpaceController«suffix» and DimmableLight«suffix» {
  Connection { DimmableLight«suffix».setpoint <- OfficeSpaceController«suffix».setpoint }
}
'''

static def corridorControllerToOccupancySensor(String suffix)
'''
Interface between CorridorController«suffix» and OccupancySensor«suffix» {
  Connection { CorridorController«suffix».activity <- OccupancySensor«suffix».occupied }
}
'''

static def corridorControllerToDimmableLight(String suffix)
'''
Interface between CorridorController«suffix» and DimmableLight«suffix» {
  Connection { DimmableLight«suffix».setpoint <- CorridorController«suffix».setpoint }
}
'''

static def occupancySensorToActor(String suffix, boolean separateActors)
'''
Interface between OccupancySensor«suffix» and Actor«IF separateActors»«suffix»«ENDIF» {
  Connection { OccupancySensor«suffix».actorXPosition <- Actor«IF separateActors»«suffix»«ENDIF».xPosition }
  Connection { OccupancySensor«suffix».actorYPosition <- Actor«IF separateActors»«suffix»«ENDIF».yPosition }
}
'''

}