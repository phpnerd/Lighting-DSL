package nl.ru.sws.dsl.lighting.generator.web

import nl.ru.sws.dsl.lighting.building.Building
import nl.ru.sws.dsl.lighting.generator.figure.SVGGenerator

class HTMLGenerator {
  
  static def generate(Building building, int occupancySensorRange, boolean hideSensorRange, int nrOfActors)
'''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>«building.name» Visualiser</title>
  <script src="js/jquery.min.js"></script>
  <script src="js/jquery-csv.min.js"></script>
  <script src="js/popper.min.js"></script>
  <script src="js/bootstrap.min.js"></script>
  <script src="js/replay.js"></script>
  <link rel="stylesheet" type="text/css" href="css/bootstrap.min.css" />
  <link rel="stylesheet" type="text/css" href="css/style.css" />
</head>
<body>
<div class="container-fluid">
  <nav class="navbar fixed-bottom navbar-expand-lg navbar-light bg-light">
    <a class="navbar-brand" href="#">«building.name»</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
  
    <div class="collapse navbar-collapse" id="navbarSupportedContent">
      <form class="form-inline">
        <button type="button" class="btn btn-light" id="btnRestart" disabled> << </button>
        <button type="button" class="btn btn-light" id="btnPrev" disabled> < </button>
        <input type="number" class="form-control" size="4" value="0.0" id="inTime" style="text-align:center;" readonly />
        <button type="button" class="btn btn-light" id="btnNext" disabled> > </button>
        <button type="button" class="btn btn-light" id="btnEnd" disabled> >> </button>
        <button type="button" class="btn btn-success" id="btnPlayPause" disabled> Play </button>
        <button type="button" class="btn btn-info" id="btnSettings" data-toggle="modal" data-target="#settingsModal">Settings</button>
      </form>
    </div>
    <form class="form-inline">
      <div class="custom-file">
        <input type="file" class="custom-file-input" id="logFile">
        <label class="custom-file-label" for="logFile" id="lblLogFile">Select Log</label>
      </div>
    </form>
  </nav>
  
  <div>
    «SVGGenerator.generate(building, occupancySensorRange, hideSensorRange, nrOfActors, "100%", "100%")»
  </div>
  
  <div class="modal" tabindex="-1" role="dialog" id="settingsModal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Settings</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <form class="form">
            <div class="form-check form-check-inline">
              <input class="form-check-input" type="checkbox" id="checkShowSensorRadius" checked />
              <label class="form-check-label" for="checkShowSensorRadius">Show Sensor Radius: </label>
            </div>
            <div class="form-group">
              <label for="stepSize">Step Size: </label>
              <input class="form-control" type="number" id="inStepSize" value="1.0" />
            </div>
            <div class="form-group">
              <label for="speed">Speed: </label>
              <input class="form-control" type="number" id="inSpeed" value="1.0" />
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" data-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
  
</div>
<script type="text/javascript">
  $(function() {
    if (isAPIAvailable()) {
      attachHandlers();
    }
  });
</script>
</body>
</html>
'''
  
}