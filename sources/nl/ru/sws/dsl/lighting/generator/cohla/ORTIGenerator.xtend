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