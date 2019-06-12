//
// Copyright (c) Thomas Nägele and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package nl.ru.sws.dsl.lighting.generator.cohla

import nl.ru.sws.dsl.lighting.building.Area
import nl.ru.sws.dsl.lighting.building.Building
import nl.ru.sws.dsl.lighting.building.Corridor
import nl.ru.sws.dsl.lighting.building.Room
import nl.ru.sws.dsl.lighting.building.RoomType

class ConnectionSetGenerator {

static def generate(Building building, int nrOfActors, boolean separateClasses, boolean separateActors) {
  val hasBasicRoom = building.areas.exists[a | a instanceof Room && (a as Room).type == RoomType.BASIC]
  val hasOffice = building.areas.exists[a | a instanceof Room && (a as Room).type == RoomType.OFFICE]
  val hasOfficeSpace = building.areas.exists[a | a instanceof Room && (a as Room).type == RoomType.OFFICESPACE]
  val hasCorridor = building.areas.exists[a | a instanceof Corridor]
  return
'''
import "FedClasses.cohla"
«IF nrOfActors > 0»
import "Actor.cohla"
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
ConnectionSet between BasicRoomController«suffix» and OccupancySensor«suffix» {
  { BasicRoomController«suffix».occupied <- OccupancySensor«suffix».occupied }
}
'''

static def basicRoomControllerToDimmableLight(String suffix)
'''
ConnectionSet between BasicRoomController«suffix» and DimmableLight«suffix» {
  { DimmableLight«suffix».setpoint <- BasicRoomController«suffix».setpoint }
}
'''

static def officeControllerToOccupancySensor(String suffix)
'''
ConnectionSet between OfficeController«suffix» and OccupancySensor«suffix» {
  { OfficeController«suffix».occupied <- OccupancySensor«suffix».occupied }
}
'''

static def officeControllerToDimmableLight(String suffix)
'''
ConnectionSet between OfficeController«suffix» and DimmableLight«suffix» {
  { DimmableLight«suffix».setpoint <- OfficeController«suffix».setpoint }
}
'''

static def officeSpaceControllerToOccupancySensor(String suffix)
'''
ConnectionSet between OfficeSpaceController«suffix» and OccupancySensor«suffix» {
  { OfficeSpaceController«suffix».occupied <- OccupancySensor«suffix».occupied }
}
'''

static def officeSpaceControllerToDimmableLight(String suffix)
'''
ConnectionSet between OfficeSpaceController«suffix» and DimmableLight«suffix» {
  { DimmableLight«suffix».setpoint <- OfficeSpaceController«suffix».setpoint }
}
'''

static def corridorControllerToOccupancySensor(String suffix)
'''
ConnectionSet between CorridorController«suffix» and OccupancySensor«suffix» {
  { CorridorController«suffix».activity <- OccupancySensor«suffix».occupied }
}
'''

static def corridorControllerToDimmableLight(String suffix)
'''
ConnectionSet between CorridorController«suffix» and DimmableLight«suffix» {
  { DimmableLight«suffix».setpoint <- CorridorController«suffix».setpoint }
}
'''

static def occupancySensorToActor(String suffix, boolean separateActors)
'''
ConnectionSet between OccupancySensor«suffix» and Actor«IF separateActors»«suffix»«ENDIF» {
  { OccupancySensor«suffix».actorXPosition <- Actor«IF separateActors»«suffix»«ENDIF».xPosition }
  { OccupancySensor«suffix».actorYPosition <- Actor«IF separateActors»«suffix»«ENDIF».yPosition }
}
'''

}