//
// Copyright (c) Thomas Nägele and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package nl.ru.sws.dsl.lighting.generator.web

import nl.ru.sws.dsl.lighting.building.Building

class JavascriptGenerator {
  
  static def generate(Building building, int nrOfActors)
'''
var data = {};
var time = 0.0;
var idx = 0;
var stepSize = 1.0;
var speed = 1.0;
var running = false;
var lights = [];
var sensors = [];
var actors = [];

function isAPIAvailable() {
  if (window.File && window.FileReader && window.FileList && window.Blob)
    return true;
  else {
    console.log("API not available");
    return false;
  }
}

function attachHandlers() {
  lights = $("circle").filter(function() { 
      return this.id.match(/(r(oom|)|c(orridor|))(\d*)_l(\d+)/);
    });
  sensors = $("circle").filter(function() { 
      return this.id.match(/(r(oom|)|c(orridor|))(\d*)_s(\d+)/);
    });
  actors = $("circle").filter(function() { 
      return this.id.match(/actor(\d+)/);
    });
  
  $("#logFile").change(handleLoadFile);
  $("#checkShowSensorRadius").change(toggleShowSensorRadius);
  $("#inStepSize").change(changeStepSize);
  $("#inSpeed").change(changeSpeed);
  $("#btnPrev").click(function(e) {
    stepBack();
  });
  $("#btnNext").click(function(e) {
    step();
  });
  $("#btnPlayPause").click(playPause);
  $("#btnRestart").click(reset);
  $("#btnEnd").click(end);
}

function handleLoadFile(event) {
  var files = event.target.files;
  if (files.length == 0) {
    console.log("No file selected!");
    return;
  }
  var file = files[0];
  $("#lblLogFile").html(file.name);
  readFile(file);
}

function readFile(file) {
  var reader = new FileReader();
  reader.readAsText(file);
  reader.onload = function(event) {
    var csv = event.target.result;
    data = $.csv.toObjects(csv, {
      separator: ";"
    });
    console.log("Succesfully read file " + file.name);
    init();
  };
  reader.onerror = function() {
    console.log("Failed to read file " + file.name);
  };
}

function toggleShowSensorRadius() {
  var radius = $("circle").filter(function() { 
    return this.id.match(/(.*?)_range/);
  });
  if ($("#checkShowSensorRadius").prop("checked"))
    radius.show();
  else
    radius.hide();
}

function changeStepSize() {
  stepSize = Number($("#inStepSize").val());
}

function changeSpeed() {
  speed = Number($("#inSpeed").val());
}

function init() {
  lights.each(function(i, l) {
    setLightState(l, 0);
  });
  
  sensors.each(function(i, l) {
    setSensorState(l, false);
  });
  actors.each(function(i, a) {
    setActorState(a, -10, -10);
  });
  $("button").attr("disabled", false);
}

function playPause() {
  var btn = $("#btnPlayPause");
  if (btn.html() == " Play ") {
    $("#btnSettings").attr("disabled", true);
    btn.html(" Pause ");
    running = true;
    run();
  } else if (btn.html() == " Pause ") {
    btn.html(" Play ");
    running = false;
    $("#btnSettings").attr("disabled", false);
  } else {
    console.log("Wait wut? (" + btn.html() + ")");
  }
}

function reset() {
  idx = 0;
  time = 0.0;
  $("#inTime").val(time);
  init();  
}

function end() {
  idx = data.length - 1;
  time = Number(data[idx].Time);
  $("#inTime").val(time);
  setState(data[idx]);
}

async function run() {
  while (running) {
    step(stepSize);
    await sleep(1000/speed/stepSize);
  }
}

function stepBack() {
  if (idx <= 0)
    return;
  time = Number(data[idx-2].Time);
  setState(data[(--idx)-1]);
  $("#inTime").val(time);
}

function step(step) {
  if (idx >= data.length)
    return;
  if (step) {
    time += step;
    if (Number(data[idx].Time) <= time) {
      while(Number(data[idx].Time) <= time)
        idx++;
      setState(data[idx++]);
    }
    $("#inTime").val(time);
  } else {
    time = Number(data[idx].Time);
    setState(data[idx++]);
    $("#inTime").val(time);
  }
}

function setState(state) {
  actors.each(function(i, a) {
    var _c = a.id.capitalize();
    var xPos = state[_c + "XPosition"];
    var yPos = state[_c + "YPosition"];
    if (xPos) $(a).attr("cx", xPos);
    if (yPos) $(a).attr("cy", yPos);
  });
  sensors.each(function(i, s) {
    var _id = s.id.capitalize();
    var occupied = state[_id + "Occupied"];
    if (occupied) setSensorState(s, occupied == 1 || occupied == "true");
  });
  lights.each(function(i, l) {
    var _id = l.id.capitalize();
    var power = state[_id + "Power"];
    if (power) setLightState(l, power);
  });
}

function setActorState(actor, x, y) {
  $(actor).attr("cx", x).attr("cy", y);
}

function setSensorState(sensor, state) {
  $(sensor).attr("fill-opacity", state ? 1 : 0);
}

function setLightState(light, power) {
  var opac = 0.0;
  if (power == "true")
    opac = 1.0;
  else if (power == "false")
    opac = 0.0;
  else
    opac = power / 100;
  $(light).attr("fill-opacity", opac);
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1);
}
'''
  
}