package nl.ru.sws.dsl.lighting.generator.cohla

import java.util.List

class LoggerGenerator {
  
static def generate(int measureTime, boolean separateClasses, List<String> names)
'''
«IF separateClasses»«names.map[n | generateLogger("Logger" + n.toFirstUpper, measureTime)].join("\n")»
«ELSE»«generateLogger(measureTime)»
«ENDIF»'''

static def generateLogger(int measureTime) {
  return generateLogger("Logger", measureTime)
}
  
static def generateLogger(String name, int measureTime)
'''
FederateClass «name» {
  SimulatorType CSV
  DefaultMeasureTime «measureTime».0
}
''' 
}