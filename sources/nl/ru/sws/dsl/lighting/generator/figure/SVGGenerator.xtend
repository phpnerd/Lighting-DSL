//
// Copyright (c) Thomas Nägele and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package nl.ru.sws.dsl.lighting.generator.figure

import nl.ru.sws.dsl.lighting.building.Building
import nl.ru.sws.dsl.lighting.building.Area
import nl.ru.sws.dsl.lighting.building.Corridor
import nl.ru.sws.dsl.lighting.building.Room
import java.util.List
import nl.ru.sws.dsl.lighting.building.Coord
import nl.ru.sws.dsl.lighting.building.Device
import nl.ru.sws.dsl.lighting.building.Light
import nl.ru.sws.dsl.lighting.building.Sensor

class SVGGenerator {
  
static val padding = 5
static val strokeWidth = 1
static val strokeColor = "#000000"
static val fontFamily = "Verdana"
static val fontSize = 28
  
static def generate(Building building, int occupancySensorRange, boolean hideSensorRange)
'''
<?xml version="1.0" encoding="UTF-8" ?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1">
  «building.areas.map[generate(occupancySensorRange, hideSensorRange)].join("\n")»
</svg>
'''

static def generate(Building building, int occupancySensorRange, boolean hideSensorRange, int nrOfActors, String height, String width)
'''
<svg height="«height»" width="«width»">
  «building.areas.map[generate(occupancySensorRange, hideSensorRange)].join("\n")»
  «generateActors(nrOfActors)»
</svg>
'''

static def generate(Area area, int occupancySensorRange, boolean hideSensorRange) {
  val coords = area.draw.coords
  if (coords.size == 4) {
    val minX = coords.map[x].min
    val minY = coords.map[y].min
    val width = coords.map[x].max - minX
    val height = coords.map[y].max - minY
'''«rect(area.name, minX, minY, width, height, getFillColor(area))»
«(area.devices.filter(Light) + area.devices.filter(Sensor)).map[generate(occupancySensorRange, hideSensorRange)].join("\n")»
«print(area.name, area.name, minX + width / 2, minY + fontSize + padding)»'''
  } else {
'''«freeForm(area.name, coords)»'''
  }
}

static def generate(Device device, int occupancySensorRange, boolean hideSensorRange) {
  val areaName = (device.eContainer as Area).name
  val devName = areaName + "_" + device.name
  var s = '''«circle(devName, device.location.x, device.location.y, device.size, device.fillColor)»'''
  if (!hideSensorRange)
    if (device instanceof Sensor)
      switch (device.type) {
        case OCCUPANCY: s += '''«dottedCircle(devName + "_range", device.location.x, device.location.y, occupancySensorRange)»'''
      }
  return s
}

static def getFillColor(Area area) {
  if (area instanceof Corridor)
    return "EFEFEF"
  else if (area instanceof Room) {
    switch (area.type) {
      case BASIC: return "E0E0E0"
      case OFFICE: return "E2E2E2"
      case OFFICESPACE: return "E4E4E4"
    }
  }
}

static def getFillColor(Device device) {
  if (device instanceof Sensor)
    return "41D6F4"
  else if (device instanceof Light) {
    switch (device.type) {
      case DIMMABLE: return "F4CB42"
      case ONOFF: return "F1F441"
    }
  }
}

static def getSize(Device device) {
  if (device instanceof Sensor)
    return 10
  else if (device instanceof Light)
    return 20
}

static def generateActors(int nrOfActors) {
  var s = ''''''
  for (var i = 0; i < nrOfActors; i++) {
      s += '''«circle("actor" + i, -10, -10, 10, "#000000")»
      '''
  }
  return s;
}

static def print(String id, String s, int xPos, int yPos) {
  print(id, s, xPos, yPos, fontSize)
}

static def print(String id, String s, int xPos, int yPos, int size)
'''<text x="«xPos»" y="«yPos»" font-family="«fontFamily»" font-size="«size»" text-anchor="middle" id="lbl_«id»">«s»</text>'''

static def rect(String id, int xPos, int yPos, int width, int height) {
  rect(id, xPos, yPos, width, height, null)
}

static def rect(String id, int xPos, int yPos, int width, int height, String color)
'''<rect x="«xPos»" y="«yPos»" width="«width»" height="«height»" «fill(color)»stroke-width="«strokeWidth»" stroke="«strokeColor»" id="«id»" />'''

static def circle(String id, int xPos, int yPos, int radius) {
  circle(id, xPos, yPos, radius, null)
}

static def circle(String id, int xPos, int yPos, int radius, String color)
'''<circle cx="«xPos»" cy="«yPos»" r="«radius»" «fill(color)»stroke-width="«strokeWidth»" stroke="«strokeColor»" id="«id»" />'''

static def dottedCircle(String id, int xPos, int yPos, int radius)
'''<circle cx="«xPos»" cy="«yPos»" r="«radius»" stroke-width="«strokeWidth»" stroke="«strokeColor»" stroke-dasharray="3, 7" fill-opacity="0" id="«id»" />'''

static def freeForm(String id, List<Coord> coords) {
  var s = ''''''
  for (var i = 0; i < coords.size; i++)
    s += '''<line x1="«coords.get(i).x»" y1="«coords.get(i).y»" x2="«coords.get((i+1)%coords.size).x»" y2="«coords.get((i+1)%coords.size).y»" stroke-width="«strokeWidth»" stroke="«strokeColor»" id="line«i»_«id»" />
    '''
  return s
}

static def fill(String fillColor) '''«IF fillColor !== null»fill="#«fillColor»"«ENDIF» '''
  
}