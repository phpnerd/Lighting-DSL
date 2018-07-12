package nl.ru.sws.dsl.lighting.generator.web

import org.eclipse.xtext.generator.IFileSystemAccess2
import nl.ru.sws.dsl.lighting.building.Building
import java.util.List

class WebGenerator {
  
  static def generate(IFileSystemAccess2 fsa, Building building, List<Integer> occupancySensorRanges, boolean hideSensorRange, int nrOfActors) {
    var webDir = building.name.toFirstUpper + "/web/"
    for (occupancySensorRange : occupancySensorRanges)
      fsa.generateFile(webDir + "range" + occupancySensorRange + ".html", HTMLGenerator.generate(building, occupancySensorRange, hideSensorRange, nrOfActors))
    fsa.generateFile(webDir + "js/jquery.min.js", DepGenerator.generateJQuery)
    fsa.generateFile(webDir + "js/jquery-csv.min.js", DepGenerator.generateJQueryCSV)
    fsa.generateFile(webDir + "js/popper.min.js", DepGenerator.generatePopper)
    fsa.generateFile(webDir + "js/bootstrap.min.js", DepGenerator.generateBootstrapJS)
    fsa.generateFile(webDir + "css/bootstrap.min.css", DepGenerator.generateBootstrapCSS)
    
    fsa.generateFile(webDir + "js/replay.js", JavascriptGenerator.generate(building, nrOfActors))
    fsa.generateFile(webDir + "css/style.css", CSSGenerator.generate)
  }
  
}