//
// Copyright (c) Thomas Nägele and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package nl.ru.sws.dsl.lighting.generator.cohla

import java.util.List

class ActorGenerator {
  
static def generate(int nrOfActors, boolean separateClasses, List<String> names) {
  var result = ''''''
  for (var i = 0; i < nrOfActors; i++) {
    if (separateClasses)
      result += names.map[n | generateActor("Actor" + n.toFirstUpper)].join("\n")
    else
      result += generateActor() 
  }
  return result
}

static def generateActor() {
  return generateActor("Actor")
}
  
static def generateActor(String name) {
  return generateActor(name, 5.0, 0.1)
}
  
static def generateActor(String name, double stepSize, double lookahead)
'''
FederateClass «name» {
  Type None
  Attributes {
    Output Real xPosition
    Output Real yPosition
  }
  AdvanceType TimeAdvanceRequest
  DefaultStepSize «stepSize»
  DefaultLookahead «lookahead»
}
''' 
}