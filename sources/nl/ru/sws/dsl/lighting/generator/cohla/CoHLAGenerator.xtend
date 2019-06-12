//
// Copyright (c) Thomas Nägele and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package nl.ru.sws.dsl.lighting.generator.cohla

import nl.ru.sws.dsl.lighting.building.Building
import nl.ru.sws.dsl.lighting.building.Area
import nl.ru.sws.dsl.lighting.building.Room
import nl.ru.sws.dsl.lighting.building.Corridor
import org.eclipse.emf.ecore.EObject
import nl.ru.sws.dsl.lighting.building.Device
import nl.ru.sws.dsl.lighting.building.Light
import nl.ru.sws.dsl.lighting.building.Sensor
import java.util.List
import nl.ru.sws.dsl.lighting.building.SensorType
import nl.ru.sws.dsl.lighting.building.Scenario
import java.util.HashMap
import java.util.ArrayList
import java.math.BigDecimal
import java.math.RoundingMode

class CoHLAGenerator {
  
static def generate(Building building, List<Scenario> scenarios, int nrOfActors, List<Integer> occupancySensorRanges, 
  boolean hasLogger, int measureTime, List<Integer> distributions, boolean separateClasses, boolean separateActors)
'''
«generateImports(building, hasLogger, nrOfActors, separateClasses)»

«generateBuilding(building, scenarios, nrOfActors, occupancySensorRanges, hasLogger, measureTime, distributions, separateClasses, separateActors)»
'''

static def generateImports(Building building, boolean hasLogger, int nrOfActors, boolean separateClasses)
'''import "orti.cohla"
import "connectionsets.cohla"
«IF nrOfActors> 0»
import "Actor.cohla"
«ENDIF»«IF hasLogger»
import "Logger.cohla"
«ENDIF»
import "FedClasses.cohla"
'''

static def generateBuilding(Building building, List<Scenario> scenarios, int nrOfActors, List<Integer> occupancySensorRanges, 
  boolean hasLogger, int measureTime, List<Integer> distributions, boolean separateClasses, boolean separateActors
)
'''Federation «building.name» {
  Instances {
    «generateInstances(building, separateClasses)»
    «IF hasLogger»// Logger(s)
    «IF !separateClasses»logger : Logger
    «ELSE»«building.areas.map[a | "logger" + a.name.toFirstUpper + " : Logger" + a.name.toFirstUpper].join("\n")»
    «ENDIF»
    «ENDIF»
    «generateActors(nrOfActors, separateActors, building.areas.map[name])»
  }
  
  Connections {
    «generateConnections(building, nrOfActors, hasLogger, separateClasses, separateActors)»
  }
  
  «generateSituation(building)»
  «occupancySensorRanges.map[r | generateSituation(building, r) + "\n" + generateSituationFull(building, r)].join»
  «IF !scenarios.empty»
  
  «scenarios.map[s | generate(s, measureTime, separateActors, building.areas.map[name])].join»
  «ENDIF»
  
  DSE sensorRanges {
    SweepMode Independent
    Situations: «occupancySensorRanges.map[r | "base" + r].join(", ")»
  }
  «IF !distributions.empty»
  
  «distributions.map[d | generateDistribution(building, d, hasLogger, nrOfActors, "dist" + d, separateClasses, separateActors)].join»
  «ENDIF»
}
'''

static def generateInstances(Building building, boolean separateClasses)
'''«FOR i : building.areas.map[a | generateInstance(a, separateClasses)]»«i»
«ENDFOR»'''

static def generateInstance(Area area, boolean separateClasses) {
  if (area instanceof Room)
    return generateInstance(area, separateClasses)
  else if (area instanceof Corridor)
    return generateInstance(area, separateClasses)
}

static def generateInstance(Room room, boolean separateClasses)
'''// Room «room.name»
«getInstanceName(room)» : «getInstanceClass(room, separateClasses)»
«FOR d : room.devices»«generateInstance(d, separateClasses)»
«ENDFOR»'''

static def generateInstance(Corridor corridor, boolean separateClasses)
'''// Corridor connecting areas «corridor.connectedRooms.map[name].join(", ")»
«getInstanceName(corridor)» : «getInstanceClass(corridor, separateClasses)»
«FOR d : corridor.devices»«generateInstance(d, separateClasses)»
«ENDFOR»'''

static def generateInstance(Device device, boolean separateClasses)
  '''«getInstanceName(device)» : «getInstanceClass(device, separateClasses)»'''

static def generateConnections(Building building, int nrOfActors, boolean hasLogger, boolean separateClasses, boolean separateActors)
'''«FOR room : building.areas.filter(Room)»
// Connections for Room «room.name»
«generateConnections(room, hasLogger)»
«ENDFOR»«FOR corridor : building.areas.filter(Corridor)»
// Connections for Corridor «corridor.name»
«generateConnections(corridor, hasLogger)»
«ENDFOR»«IF nrOfActors > 0»
// Actor - Sensor connections
«IF !separateActors»«generateConnections(building.areas.map[devices].flatten.filter(Sensor).toList, nrOfActors, "")»
«ELSE»«building.areas.map[a | generateConnections(a.devices.filter(Sensor).toList, nrOfActors, a.name.toFirstUpper)].join("\n")»
«ENDIF»«ENDIF»«IF hasLogger»
// Logger connections
«var s = ''''''»
«for (var i = 0; nrOfActors > 0 && i < nrOfActors; i++) {
  s += '''actor«i».xPosition, actor«i».yPosition, '''
}»
«IF !separateClasses»{ logger <- «s»«building.areas.flatMap[devices].map[generateLoggedAttributes].join(", ")» }
«ELSE»«building.areas.map[a | "{ logger" + a.name.toFirstUpper + " <- " + a.devices.map[generateLoggedAttributes].join(", ") + " }"].join("\n")»
«ENDIF»
«ENDIF»'''

static def generateConnections(Room room, boolean hasLogger)
'''
«FOR d : room.devices»
{ «getInstanceName(room)» - «getInstanceName(d)» }
«ENDFOR»'''

static def generateConnections(Corridor corridor, boolean hasLogger)
'''«val iName = getInstanceName(corridor)»
«FOR l : corridor.devices.filter(Light)»
{ «iName» - «getInstanceName(l)» }
«ENDFOR»«FOR s : corridor.devices.filter(Sensor)»
{ «iName» - «getInstanceName(s)» }
«ENDFOR»«FOR s : corridor.connectedRooms.map[devices].flatten.filter(Sensor)»
{ «iName».relatedActivity <- «getInstanceName(s)».«getOutAttribute(s)» }
«ENDFOR»'''

static def generateConnections(List<Sensor> sensors, int nrOfActors, String suffix) {
  var s = ''''''
  for (sensor : sensors) {
    for (var i = 0; i < nrOfActors; i++)
      s += 
'''{ «getInstanceName(sensor)» - actor«i»«suffix» }
'''
  }
  return s
}

static def generateSituation(Building building)
'''Situation structure {
  «FOR s : building.areas.flatMap[devices].filter[d | d instanceof Sensor && (d as Sensor).type == SensorType.OCCUPANCY]»
  «val bounds = (s.eContainer as Area).draw.coords»
  «val boundMinX = bounds.map[x].min»
  «val boundMaxX = bounds.map[x].max»
  «val boundMinY = bounds.map[y].min»
  «val boundMaxY = bounds.map[y].max»
  Init «getInstanceName(s)».Bounded_rangeOrigin0 as "«s.location.x»"
  Init «getInstanceName(s)».Bounded_rangeOrigin1 as "«s.location.y»"
  Init «getInstanceName(s)».Bounded_rangeBounds1 as "«boundMinX»"
  Init «getInstanceName(s)».Bounded_rangeBounds3 as "«boundMinY»"
  Init «getInstanceName(s)».Bounded_rangeBounds0 as "«boundMaxX»"
  Init «getInstanceName(s)».Bounded_rangeBounds2 as "«boundMaxY»"
  «ENDFOR»
}
'''

static def generateSituation(Building building, int occupancySensorRange) 
'''Situation range«occupancySensorRange» {
  «FOR s : building.areas.flatMap[devices].filter[d | d instanceof Sensor && (d as Sensor).type == SensorType.OCCUPANCY]»
  Init «getInstanceName(s)».Bounded_rangeRange as "«occupancySensorRange»"
  «ENDFOR»
}
'''

static def generateSituationFull(Building building, int occupancySensorRange)
'''Situation base«occupancySensorRange» {
  «FOR s : building.areas.flatMap[devices].filter[d | d instanceof Sensor && (d as Sensor).type == SensorType.OCCUPANCY]»
  «val bounds = (s.eContainer as Area).draw.coords»
  «val boundMinX = bounds.map[x].min»
  «val boundMaxX = bounds.map[x].max»
  «val boundMinY = bounds.map[y].min»
  «val boundMaxY = bounds.map[y].max»
  Init «getInstanceName(s)».Bounded_rangeRange as "«occupancySensorRange»"
  Init «getInstanceName(s)».Bounded_rangeOrigin0 as "«s.location.x»"
  Init «getInstanceName(s)».Bounded_rangeOrigin1 as "«s.location.y»"
  Init «getInstanceName(s)».Bounded_rangeBounds1 as "«boundMinX»"
  Init «getInstanceName(s)».Bounded_rangeBounds3 as "«boundMinY»"
  Init «getInstanceName(s)».Bounded_rangeBounds0 as "«boundMaxX»"
  Init «getInstanceName(s)».Bounded_rangeBounds2 as "«boundMaxY»"
  «ENDFOR»
}

'''

static def generate(Scenario scenario, int measureTime, boolean separateClasses, List<String> names)
'''
Scenario «scenario.name» {
  «IF measureTime > 0»
  AutoStop: «measureTime».0
  «ENDIF»
  «var time = 0»
  «var pX = scenario.startPosition.x as double»
  «var pY = scenario.startPosition.y as double»
  «val activity = scenario.actorActivity ?: null»
  «IF !separateClasses»0.0: actor«scenario.actorId».xPosition = "«scenario.startPosition.x»"
  0.0: actor«scenario.actorId».yPosition = "«scenario.startPosition.y»"
«ELSE»«names.map[n | '''0.0: actor«scenario.actorId»«n.toFirstUpper».xPosition = "«scenario.startPosition.x»"
0.0: actor«scenario.actorId»«n.toFirstUpper».yPosition = "«scenario.startPosition.y»" '''].join("\n")»
  «ENDIF»
  «FOR step : scenario.steps»
  «IF activity !== null && step.delay > activity.startFrom + activity.endBefore»
  «var s = ''''''»
  «val hardEndBound = time + step.delay - activity.endBefore»
  «for (var subTime = time; subTime < hardEndBound; subTime += activity.total) {
    val startTime = subTime + activity.portion
    val endTime = Integer.min(subTime + activity.total, hardEndBound)
s += '''
«IF !separateClasses»«startTime».0: actor«scenario.actorId».xPosition = "-10"  // Interrupt
«startTime».0: actor«scenario.actorId».yPosition = "-10"
«endTime».0: actor«scenario.actorId».xPosition = "«pX»"
«endTime».0: actor«scenario.actorId».yPosition = "«pY»"  // End interrupt
«ELSE»«val _pX = pX»«val _pY = pY»«names.map[n | '''«startTime».0: actor«scenario.actorId»«n.toFirstUpper».xPosition = "-10"  // Interrupt
«startTime».0: actor«scenario.actorId»«n.toFirstUpper».yPosition = "-10"
«endTime».0: actor«scenario.actorId»«n.toFirstUpper».xPosition = "«_pX»"
«endTime».0: actor«scenario.actorId»«n.toFirstUpper».yPosition = "«_pY»"  // End interrupt'''].join("\n")»
«ENDIF»'''
  }»
  «s»
  «ENDIF»
  «IF scenario.interpolate && scenario.interpolateStep > 0»
  «var s = ''''''»
  «val iSteps = step.delay / scenario.interpolateStep»
  «val xStep = (step.position.x - pX) / iSteps»
  «val yStep = (step.position.y - pY) / iSteps»
  «for (var subTime = time + scenario.interpolateStep, var i = 0; i < iSteps - 1 && (xStep != 0.0 || yStep != 0.0); i++, subTime += scenario.interpolateStep) {
    pX = pX + xStep
    pY = pY + yStep
    s += '''«IF separateClasses»«FOR name : names»«subTime».0: actor«scenario.actorId»«name.toFirstUpper».xPosition = "«new BigDecimal(pX).setScale(2, RoundingMode.HALF_UP).doubleValue()»" // Interpolated
«subTime».0: actor«scenario.actorId»«name.toFirstUpper».yPosition = "«new BigDecimal(pY).setScale(2, RoundingMode.HALF_UP).doubleValue()»" // Interpolated
«ENDFOR»«ELSE»«subTime».0: actor«scenario.actorId».xPosition = "«new BigDecimal(pX).setScale(2, RoundingMode.HALF_UP).doubleValue()»" // Interpolated
«subTime».0 actor«scenario.actorId».yPosition = "«new BigDecimal(pY).setScale(2, RoundingMode.HALF_UP).doubleValue()»" // Interpolated
«ENDIF»'''
  }»
  «s»
  «ENDIF»
  «IF !separateClasses»«time += step.delay».0: actor«scenario.actorId».xPosition = "«pX = step.position.x»"
  «time».0: actor«scenario.actorId».yPosition = "«pY = step.position.y»"
«ELSE»«var s = ''''''»«for (var i = 0; i < names.length; i++) {
    if (i == 0) {
      time += step.delay
      pX = step.position.x
      pY = step.position.y
    }
    s += '''«time».0: actor«scenario.actorId»«names.get(i).toFirstUpper».xPosition = "«pX»"
«time».0: actor«scenario.actorId»«names.get(i).toFirstUpper».yPosition = "«pY»"
'''
  }»«s»
  «ENDIF»
  «ENDFOR»
}
'''

static def generateDistribution(Building building, int systems, boolean hasLogger, int nrOfActors, String name, boolean separateClasses, boolean separateActors) {
  var distribution = new HashMap<Integer, List<String>>()
  for (var i = 0 ; i < systems; i++)
    distribution.put(i, new ArrayList<String>())
  if (hasLogger && !separateClasses)
    distribution.get(0).add("logger")
  if (!separateActors)
    for (var i = 0; i < nrOfActors; i++)
      distribution.get(0).add("actor" + i)
  val areas = building.areas.sortBy[a | a.devices.length]
  for (area : areas.reverseView) {
    val minKey = distribution.entrySet.minBy[e | e.value.length].key
    if (separateClasses)
      if (hasLogger)
        distribution.get(minKey).add("logger" + area.name.toFirstUpper)
    if (separateActors)
      for (var i = 0; i < nrOfActors; i++)
        distribution.get(minKey).add("actor" + i + area.name.toFirstUpper)
    distribution.get(minKey).add(area.instanceName)
    distribution.get(minKey).addAll(area.devices.map[instanceName])
  }
  var badDistribution = new HashMap<Integer, List<String>>()
  for (var i = 0 ; i < systems; i++)
    badDistribution.put(i, new ArrayList<String>())
  if (hasLogger && !separateClasses)
    badDistribution.get(0).add("logger")
  if (!separateActors)
    for (var i = 0; i < nrOfActors; i++)
      badDistribution.get(0).add("actor" + i)
  for (area : areas.reverseView) {
    val minKey = badDistribution.entrySet.minBy[e | e.value.length].key
    var i = 0
    if (separateClasses)
      if (hasLogger)
        badDistribution.get((minKey + (i++)) % systems).add("logger" + area.name.toFirstUpper)
    if (separateActors)
      for (var j = 0; j < nrOfActors; j++)
        badDistribution.get((minKey + (i++)) % systems).add("actor" + j + area.name.toFirstUpper)
    badDistribution.get((minKey + (i++)) % systems).add(area.instanceName)
    for (device : area.devices.map[instanceName]) {
      badDistribution.get((minKey + (i++)) % systems).add(device)
    }
  }
  return 
'''
Distribution «name» over «systems» systems {
  «distribution.entrySet.map[e | e.value.join(e.key + ": ", " ", "", [toString])].join("\n")»
}
Distribution bad«name» over «systems» systems {
  «badDistribution.entrySet.map[e | e.value.join(e.key + ": ", " ", "", [toString])].join("\n")»
}
'''
}

static def generateLoggedAttributes(Device d) {
  if (d instanceof Light)
    '''«getInstanceName(d)».«getOutAttribute(d)»'''
  else if (d instanceof Sensor)
    '''«getInstanceName(d)».«getOutAttribute(d)»'''
}

static def generateLogger(int measureTime, String suffix)
'''
FederateClass Logger«suffix.toFirstUpper» {
  Type CSV {
    DefaultMeasureTime «measureTime».0
  }
}'''

static def generateActors(int nrOfActors, boolean separateActors, List<String> names) {
  var s = ''''''
  if (nrOfActors > 0) {
    s += 
'''// Actors
'''
    for (var i = 0; i < nrOfActors; i++)
      s += 
'''«IF !separateActors»actor«i» : Actor
«ELSE»«val j = i»«names.map[n | "actor" + j + n.toFirstUpper + " : Actor" + n.toFirstUpper].join("\n")»
«ENDIF»'''
  }
  return s
}

static def getInstanceClass(EObject obj, boolean separateClasses) {
  var suffix = ""
  if (obj instanceof Room) {
    if (separateClasses)
      suffix = (obj as Room).name.toFirstUpper
    switch (obj.type) {
      case BASIC: return "BasicRoomController" + suffix
      case OFFICE: return "OfficeController" + suffix
      case OFFICESPACE: return "OfficeSpaceController" + suffix
    }
  } if (obj instanceof Corridor) {
    if (separateClasses)
      suffix = (obj as Corridor).name.toFirstUpper
    return "CorridorController" + suffix
  }
  if (separateClasses)
    suffix = ((obj as Device).eContainer as Area).name.toFirstUpper
  if (obj instanceof Light)
    switch (obj.type) {
      case DIMMABLE: return "DimmableLight" + suffix
      case ONOFF: return "OnOffLight" + suffix
    }
  if (obj instanceof Sensor)
    switch (obj.type) {
      case OCCUPANCY: return "OccupancySensor" + suffix
    }
}

static def getInstanceName(EObject obj) {
  if (obj instanceof Room) // Controller
    return obj.name.toFirstLower + "Controller"
  if (obj instanceof Corridor) // Controller
    return obj.name.toFirstLower + "Controller"
  val cName = (obj.eContainer as Area).name
  if (obj instanceof Light)
    return cName + "_" + obj.name.toFirstLower
  if (obj instanceof Sensor)
    return cName + "_" + obj.name.toFirstLower
}

static def getOutAttribute(EObject o) {
  if (o instanceof Sensor) {
    switch(o.type) {
      case OCCUPANCY: return "occupied"
    }
  } else if (o instanceof Light) {
    switch (o.type) {
      case DIMMABLE: return "power"
      case ONOFF: return "power"
    }
  }
}
  
  
}