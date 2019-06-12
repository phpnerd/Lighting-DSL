//
// Copyright (c) Thomas Nägele and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package nl.ru.sws.dsl.lighting.generator.cohla

import java.util.ArrayList
import java.util.List
import nl.ru.sws.dsl.lighting.building.Building
import nl.ru.sws.dsl.lighting.building.Corridor
import nl.ru.sws.dsl.lighting.building.Light
import nl.ru.sws.dsl.lighting.building.Room
import nl.ru.sws.dsl.lighting.building.Sensor
import org.eclipse.emf.ecore.EObject

class DeviceGenerator {
  
static def generate(Building building, boolean separateClasses, String modelDir, boolean genPoosl)
'''«val added = new ArrayList<String>()»
«IF !separateClasses»
«(building.areas.map[generateClass(modelDir, added, genPoosl)] + building.areas.map[devices].flatten.map[generateClass(modelDir, added, genPoosl)]).join("\n")»
«ELSE»
«building.areas.map[a | generateClass(a, a.name, modelDir, added, genPoosl) + "\n" + a.devices.map[d | generateClass(d, a.name, modelDir, added, genPoosl)].join("\n")].join("\n")»
«ENDIF»
'''

static def generateClass(EObject obj, String modelDir, List<String> added, boolean genPoosl) {
  return generateClass(obj, "", modelDir, added, genPoosl)
}

static def generateClass(EObject obj, String suffix, String modelDir, List<String> added, boolean genPoosl) {
  if (obj instanceof Room) {
    switch (obj.type) {
      case BASIC: return generateBasicRoomController(suffix, modelDir, added, genPoosl)
      case OFFICE: return generateOfficeController(suffix, modelDir, added)
      case OFFICESPACE: return generateOfficeSpaceController(suffix, modelDir, added)
    }
  } else if (obj instanceof Corridor) {
    return generateCorridorController(suffix, modelDir, added, genPoosl)
  } else if (obj instanceof Light) {
    switch (obj.type) {
      case DIMMABLE: return generateDimmableLight(suffix, modelDir, added)
      case ONOFF: return generateOnOffLight(suffix, modelDir, added)
    }
  } else if (obj instanceof Sensor) {
    switch (obj.type) {
      case OCCUPANCY: return generateOccupancySensor(suffix, modelDir, added)
    }
  }
}

static def generateDimmableLight(String modelDir, List<String> added) {
  return generateDimmableLight("", modelDir, added)
}

static def generateDimmableLight(String suffix, String modelDir, List<String> added) {
  val name = "DimmableLight" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type FMU
  Attributes {
    Input Real setpoint
    Output Real power
  }
  Parameters {
    Real GainK "Gain.K"
    Real IntegrateInitial "Integrate.initial"
  }
  DefaultModel "«modelDir»/DimmableLight.fmu"
  AdvanceType NextMessageRequest
  DefaultStepSize 1.0
  DefaultLookahead 0.1
}
'''
}

static def generateOnOffLight(String modelDir, List<String> added) {
  return generateOnOffLight("", modelDir, added)
}

static def generateOnOffLight(String suffix, String modelDir, List<String> added) {
  val name = "OnOffLight" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type FMU
  Attributes {
    Input Boolean on
    Output Real power
  }
  Parameters {
    Real GainK "Gain.K"
    Real IntegrateInitial "Integrate.initial"
  }
  DefaultModel "«modelDir»/OnOffLight.fmu"
  AdvanceType NextMessageRequest
  DefaultStepSize 1.0
  DefaultLookahead 0.1
}
'''
}

static def generateOccupancySensor(String modelDir, List<String> added) {
  return generateOccupancySensor("", modelDir, added)
}

static def generateOccupancySensor(String suffix, String modelDir, List<String> added) {
  val name = "OccupancySensor" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type FMU
  Attributes {
    Input Real actorXPosition as "x_position"
    Input Real actorYPosition as "y_position"
    Output Boolean occupied
  }
  Parameters {
    Real Threshold "threshold"
    Real Bounded_rangeRange "bounded_range.range"
    Real Bounded_rangeOrigin0 "bounded_range.origin[0]"
    Real Bounded_rangeOrigin1 "bounded_range.origin[1]"
    Real Bounded_rangeBounds0 "bounded_range.bounds[0]"
    Real Bounded_rangeBounds1 "bounded_range.bounds[1]"
    Real Bounded_rangeBounds2 "bounded_range.bounds[2]"
    Real Bounded_rangeBounds3 "bounded_range.bounds[3]"
    Real Integrate4Initial "Integrate4.initial"
  }
  TimePolicy RegulatedAndConstrained
  DefaultModel "«modelDir»/OccupancySensor.fmu"
  AdvanceType NextMessageRequest
  DefaultStepSize 5.0
  DefaultLookahead 0.1
}
'''
}

static def generateOfficeController(String modelDir, List<String> added) {
  return generateOfficeController("", modelDir, added)
}

static def generateOfficeController(String suffix, String modelDir, List<String> added) {
  val name = "OfficeController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type POOSL {
    Processes {
      c in "BasicRoomController"
    }
    DefaultPortConfig "«modelDir»/cosim.ini"
  }
  Attributes {
    InOutput Boolean [||] occupied In Process c as "occupied"
    InOutput Real setpoint In Process c as "setpoint"
  }
  Parameters {
    Real OccupiedHoldTime "OccupiedHoldTime" in c
    Real OccupiedLevel "OccupiedLevel" in c
    Real VacantHoldTime "VacantHoldTime" in c
    Real VacantLevel "VacantLevel" in c
  }
  TimePolicy RegulatedAndConstrained
  DefaultModel "«modelDir»/BasicRoomController.poosl"
  AdvanceType NextMessageRequest
  DefaultLookahead 0.1
  SimulationWeight 3
}
'''
}

static def generateOfficeSpaceController(String modelDir, List<String> added) {
  return generateOfficeSpaceController("", modelDir, added)
}

static def generateOfficeSpaceController(String suffix, String modelDir, List<String> added) {
  val name = "OfficeSpaceController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type POOSL {
    Processes {
      c in "BasicRoomController"
    }
    DefaultPortConfig "«modelDir»/cosim.ini"
  }
  Attributes {
    InOutput Boolean [||] occupied In Process c as "occupied"
    InOutput Real setpoint In Process c as "setpoint"
  }
  Parameters {
    Real OccupiedHoldTime "OccupiedHoldTime" in c
    Real OccupiedLevel "OccupiedLevel" in c
    Real VacantHoldTime "VacantHoldTime" in c
    Real VacantLevel "VacantLevel" in c
  }
  TimePolicy RegulatedAndConstrained
  DefaultModel "«modelDir»/BasicRoomController.poosl"
  AdvanceType NextMessageRequest
  DefaultLookahead 0.1
  SimulationWeight 3
}
'''
}

static def generateBasicRoomController(String modelDir, List<String> added, boolean genPoosl) {
  return generateBasicRoomController("", modelDir, added, genPoosl)
}

static def generateBasicRoomController(String suffix, String modelDir, List<String> added, boolean genPoosl) {
  if (genPoosl)
    return generateBasicRoomControllerPoosl(suffix, modelDir, added)
  return generateBasicRoomControllerFMU(suffix, modelDir, added)
}

static def generateBasicRoomControllerFMU(String suffix, String modelDir, List<String> added) {
  val name = "BasicRoomController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type FMU
  Attributes {
    InOutput Boolean [||] occupied 
    InOutput Real setpoint
  }
  Parameters {
    Real OccupiedHoldTime "OccupiedHoldTime"
    Real OccupiedLevel "OccupiedLevel"
    Real VacantHoldTime "VacantHoldTime"
    Real VacantLevel "VacantLevel"
  }
  TimePolicy RegulatedAndConstrained
  DefaultModel "«modelDir»/BasicRoomController.fmu"
  AdvanceType NextMessageRequest
  DefaultStepSize 10.0
  DefaultLookahead 0.1
  SimulationWeight 1
}
'''
}

static def generateBasicRoomControllerPoosl(String suffix, String modelDir, List<String> added) {
  val name = "BasicRoomController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type POOSL {
    Processes {
      c in "BasicRoomController"
    }
    DefaultPortConfig "«modelDir»/cosim.ini"
  }
  Attributes {
    InOutput Boolean [||] occupied in c as "occupied"
    InOutput Real setpoint in c as "setpoint"
  }
  Parameters {
    Real OccupiedHoldTime "OccupiedHoldTime" in c
    Real OccupiedLevel "OccupiedLevel" in c
    Real VacantHoldTime "VacantHoldTime" in c
    Real VacantLevel "VacantLevel" in c
  }
  TimePolicy RegulatedAndConstrained
  DefaultModel "«modelDir»/BasicRoomController.poosl"
  AdvanceType NextMessageRequest
  DefaultLookahead 0.1
  SimulationWeight 3
}
'''
}

static def generateCorridorController(String modelDir, List<String> added, boolean genPoosl) {
  return generateCorridorController("", modelDir, added, genPoosl)
}

static def generateCorridorController(String suffix, String modelDir, List<String> added, boolean genPoosl) {
  if (genPoosl)
    return generateCorridorControllerPoosl(suffix, modelDir, added)
  return generateCorridorControllerFMU(suffix, modelDir, added)
}

static def generateCorridorControllerFMU(String suffix, String modelDir, List<String> added) {
  val name = "CorridorController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type FMU
  Attributes {
    InOutput Boolean [||] activity
    InOutput Boolean [||] relatedActivity
    InOutput Real setpoint
  }
  Parameters {
    Real OccupiedHoldTime "ActiveHoldTime"
    Real OccupiedLevel "ActiveLevel"
    Real VacantHoldTime "VacantHoldTime"
    Real VacantLevel "VacantLevel"
    Real RelatedHoldTime "RelatedHoldTime"
    Real RelatedLevel "RelatedLevel"
  }
  TimePolicy RegulatedAndConstrained
  DefaultModel "«modelDir»/CorridorController.fmu"
  AdvanceType NextMessageRequest
  DefaultStepSize 10.0
  DefaultLookahead 0.1
  SimulationWeight 1
}
'''
}

static def generateCorridorControllerPoosl(String suffix, String modelDir, List<String> added) {
  val name = "CorridorController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  Type POOSL {
    Processes {
      c in "CorridorController"
    }
    DefaultPortConfig "«modelDir»/cosim.ini"
  }
  Attributes {
    InOutput Boolean [||] activity in c as "activity"
    InOutput Boolean [||] relatedActivity in c as "relatedActivity"
    InOutput Real setpoint in c as "setpoint"
  }
  Parameters {
    Real OccupiedHoldTime "ActiveHoldTime" in c
    Real OccupiedLevel "ActiveLevel" in c
    Real VacantHoldTime "VacantHoldTime" in c
    Real VacantLevel "VacantLevel" in c
    Real RelatedHoldTime "RelatedHoldTime" in c
    Real RelatedLevel "RelatedLevel" in c
  }
  TimePolicy RegulatedAndConstrained
  DefaultModel "«modelDir»/CorridorController.poosl"
  AdvanceType NextMessageRequest
  DefaultLookahead 0.1
  SimulationWeight 3
}
'''
}

}