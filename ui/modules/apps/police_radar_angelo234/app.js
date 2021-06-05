angular.module('beamng.apps')
.directive('policeRadarAngelo234', ['$log', 'StreamsManager', 'Utils', function ($log, StreamsManager, Utils) {
  return {
    restrict: 'E',
    templateUrl: 'modules/apps/police_radar_angelo234/app.html',
    replace: true,
    link: function (scope, element, attrs) {
      var strongest_speed = document.getElementById("strongest-speed");
      var fastest_speed = document.getElementById("fastest-speed");
      var patrol_speed = document.getElementById("patrol-speed");

      var strongest_speed_display = new SegmentDisplay("strongest-speed-display");
      var fastest_speed_display = new SegmentDisplay("fastest-speed-display");
      var patrol_speed_display = new SegmentDisplay("patrol-speed-display");
      
      
      var streamsList = ['wheelInfo', 'electrics', 'sensors'];
      StreamsManager.add(streamsList);
          
      function initSegmentDisplays() {    
        strongest_speed_display.pattern         = "###";
        strongest_speed_display.displayAngle    = 0;
        strongest_speed_display.digitHeight     = 20;
        strongest_speed_display.digitWidth      = 12;
        strongest_speed_display.digitDistance   = 2.5;
        strongest_speed_display.segmentWidth    = 2.5;
        strongest_speed_display.segmentDistance = 0.5;
        strongest_speed_display.segmentCount    = 7;
        strongest_speed_display.cornerType      = 3;
        strongest_speed_display.colorOn         = "#ff0000";
        strongest_speed_display.colorOff        = "#4b1e05";
        strongest_speed_display.draw();
        
        fastest_speed_display.pattern         = "###";
        fastest_speed_display.displayAngle    = 0;
        fastest_speed_display.digitHeight     = 20;
        fastest_speed_display.digitWidth      = 12;
        fastest_speed_display.digitDistance   = 2.5;
        fastest_speed_display.segmentWidth    = 2.5;
        fastest_speed_display.segmentDistance = 0.5;
        fastest_speed_display.segmentCount    = 7;
        fastest_speed_display.cornerType      = 3;
        fastest_speed_display.colorOn         = "#ff0000";
        fastest_speed_display.colorOff        = "#4b1e05";
        fastest_speed_display.draw();
        
        patrol_speed_display.pattern         = "###";
        patrol_speed_display.displayAngle    = 0;
        patrol_speed_display.digitHeight     = 20;
        patrol_speed_display.digitWidth      = 12;
        patrol_speed_display.digitDistance   = 2.5;
        patrol_speed_display.segmentWidth    = 2.5;
        patrol_speed_display.segmentDistance = 0.5;
        patrol_speed_display.segmentCount    = 7;
        patrol_speed_display.cornerType      = 3;
        patrol_speed_display.colorOn         = "#ff0000";
        patrol_speed_display.colorOff        = "#4b1e05";
        patrol_speed_display.draw();
      }
      
      initSegmentDisplays();
      
      function convertToDisplay(s) {
        var spaces = "";       
        
        for (var i = 0; i < 3 - s.length; i++) {
          spaces += ' ';
        }
       
        return spaces + s; 
      }
      
      scope.$on('sendRadarInfo', function (event, data) {
        var strongest_speed_str = Math.trunc(data.strongest_speed * 3.6).toString();
        strongest_speed_display.setValue(convertToDisplay(strongest_speed_str));

        if (data.fastest_speed !== undefined) {
          var fastest_speed_str = Math.trunc(data.fastest_speed * 3.6).toString();
          fastest_speed_display.setValue(convertToDisplay(fastest_speed_str));
        }
        else {
          fastest_speed_display.setValue('');
        }       
        
        var patrol_speed_str = Math.trunc(data.patrol_speed * 3.6).toString();     
        patrol_speed_display.setValue(convertToDisplay(patrol_speed_str));
      });
      
      scope.$on('streamsUpdate', function (event, streams) {
        
        
        
      });
      
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });
    },
  };
}
]);