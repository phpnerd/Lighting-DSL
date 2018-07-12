//
// Copyright (c) Thomas Nägele and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package nl.ru.sws.dsl.lighting.generator.cohla

class ORTIGenerator {

static def generate()
'''
HlaEnvironment {
  HlaVersion OpenRTI
  openRTIlibRoot: "/opt/OpenRTI-libs"
  PublishOnlyChanges
}
'''

}