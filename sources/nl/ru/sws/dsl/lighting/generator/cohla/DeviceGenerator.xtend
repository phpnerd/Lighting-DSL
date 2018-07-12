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
  
static def generate(Building building, boolean separateClasses, String modelDir)
'''«val added = new ArrayList<String>()»
«IF !separateClasses»
«(building.areas.map[generateClass(modelDir, added)] + building.areas.map[devices].flatten.map[generateClass(modelDir, added)]).join("\n")»
«ELSE»
«building.areas.map[a | generateClass(a, a.name, modelDir, added) + "\n" + a.devices.map[d | generateClass(d, a.name, modelDir, added)].join("\n")].join("\n")»
«ENDIF»
'''

static def generateClass(EObject obj, String modelDir, List<String> added) {
  return generateClass(obj, "", modelDir, added)
}

static def generateClass(EObject obj, String suffix, String modelDir, List<String> added) {
  if (obj instanceof Room) {
    switch (obj.type) {
      case BASIC: return generateBasicRoomController(suffix, modelDir, added)
      case OFFICE: return generateOfficeController(suffix, modelDir, added)
      case OFFICESPACE: return generateOfficeSpaceController(suffix, modelDir, added)
    }
  } else if (obj instanceof Corridor) {
    return generateCorridorController(suffix, modelDir, added)
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
  Attributes {
    Input Real setpoint
    Output Real power
  }
  Initialisables {
    Initialisable GainK "Gain.K" as Real
    Initialisable IntegrateInitial "Integrate.initial" as Real
  }
  SimulatorType FMU
  DefaultStep Message
  DefaultModel "«modelDir»/DimmableLight.fmu"
  DefaultStepSize 1.0
  DefaultLookahead 0.01
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
  Attributes {
    Input Boolean on
    Output Real power
  }
  Initialisables {
    Initialisable GainK "Gain.K" as Real
    Initialisable IntegrateInitial "Integrate.initial" as Real
  }
  SimulatorType FMU
  DefaultStep Message
  DefaultModel "«modelDir»/OnOffLight.fmu"
  DefaultStepSize 1.0
  DefaultLookahead 0.01
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
  TimePolicy RegulatedAndConstrained
  Attributes {
    Input Real actorXPosition as "x_position"
    Input Real actorYPosition as "y_position"
    Output Boolean occupied
  }
  Initialisables {
    Initialisable Threshold "threshold" as Real
    Initialisable Bounded_rangeRange "bounded_range.range" as Real
    Initialisable Bounded_rangeOrigin0 "bounded_range.origin[0]" as Real
    Initialisable Bounded_rangeOrigin1 "bounded_range.origin[1]" as Real
    Initialisable Bounded_rangeBounds0 "bounded_range.bounds[0]" as Real
    Initialisable Bounded_rangeBounds1 "bounded_range.bounds[1]" as Real
    Initialisable Bounded_rangeBounds2 "bounded_range.bounds[2]" as Real
    Initialisable Bounded_rangeBounds3 "bounded_range.bounds[3]" as Real
    Initialisable Integrate4Initial "Integrate4.initial" as Real
  }
  SimulatorType FMU
  DefaultStep Message
  DefaultModel "«modelDir»/OccupancySensor.fmu"
  DefaultStepSize 5.0
  DefaultLookahead 0.01
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
  TimePolicy RegulatedAndConstrained
  Processes {
    Process "controller" as c
  }
  Attributes {
    InOutput Boolean [||] occupied In Process c as "occupied"
    InOutput Real setpoint In Process c as "setpoint"
  }
  Initialisables {
    Initialisable OccupiedHoldTime "OccupiedHoldTime" as Real in process c
    Initialisable OccupiedLevel "OccupiedLevel" as Real in process c
    Initialisable VacantHoldTime "VacantHoldTime" as Real in process c
    Initialisable VacantLevel "VacantLevel" as Real in process c
  }
  SimulatorType Rotalumis
  SimulationWeight 3
  DefaultStep Message
  DefaultModel "«modelDir»/BasicRoomController.poosl"
  DefaultLookahead 0.01
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
  TimePolicy RegulatedAndConstrained
  Processes {
    Process "controller" as c
  }
  Attributes {
    InOutput Boolean [||] occupied In Process c as "occupied"
    InOutput Real setpoint In Process c as "setpoint"
  }
  Initialisables {
    Initialisable OccupiedHoldTime "OccupiedHoldTime" as Real in process c
    Initialisable OccupiedLevel "OccupiedLevel" as Real in process c
    Initialisable VacantHoldTime "VacantHoldTime" as Real in process c
    Initialisable VacantLevel "VacantLevel" as Real in process c
  }
  SimulatorType Rotalumis
  SimulationWeight 3
  DefaultStep Message
  DefaultModel "«modelDir»/BasicRoomController.poosl"
  DefaultLookahead 0.01
}
'''
}

static def generateBasicRoomController(String modelDir, List<String> added) {
  return generateBasicRoomController("", modelDir, added)
}

static def generateBasicRoomController(String suffix, String modelDir, List<String> added) {
  val name = "BasicRoomController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  TimePolicy RegulatedAndConstrained
  Attributes {
    InOutput Boolean [||] occupied 
    InOutput Real setpoint
  }
  Initialisables {
    Initialisable OccupiedHoldTime "OccupiedHoldTime" as Real
    Initialisable OccupiedLevel "OccupiedLevel" as Real
    Initialisable VacantHoldTime "VacantHoldTime" as Real
    Initialisable VacantLevel "VacantLevel" as Real
  }
  SimulatorType FMU
  SimulationWeight 1
  DefaultStep Message
  DefaultModel "«modelDir»/BasicRoomController.fmu"
  DefaultStepSize 10.0
  DefaultLookahead 0.01
}
'''
}

static def generateCorridorController(String modelDir, List<String> added) {
  return generateCorridorController("", modelDir, added)
}

static def generateCorridorController(String suffix, String modelDir, List<String> added) {
  val name = "CorridorController" + suffix.toFirstUpper
  if (added.contains(name))
    return ''''''
  added.add(name)
  return
'''
FederateClass «name» {
  TimePolicy RegulatedAndConstrained
  Attributes {
    InOutput Boolean [||] activity
    InOutput Boolean [||] relatedActivity
    InOutput Real setpoint
  }
  Initialisables {
    Initialisable OccupiedHoldTime "ActiveHoldTime" as Real
    Initialisable OccupiedLevel "ActiveLevel" as Real
    Initialisable VacantHoldTime "VacantHoldTime" as Real
    Initialisable VacantLevel "VacantLevel" as Real
    Initialisable RelatedHoldTime "RelatedHoldTime" as Real
    Initialisable RelatedLevel "RelatedLevel" as Real
  }
  SimulatorType FMU
  SimulationWeight 1
  DefaultStep Message
  DefaultModel "«modelDir»/CorridorController.fmu"
  DefaultStepSize 10.0
  DefaultLookahead 0.01
}
'''
}

}