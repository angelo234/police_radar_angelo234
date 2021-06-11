angular.module('beamng.apps')
.directive('policeRadarAngelo234', ['$log', 'StreamsManager', 'Utils', function ($log, StreamsManager, Utils) {
  return {
    restrict: 'E',
    templateUrl: 'modules/apps/police_radar_angelo234/app.html',
    replace: true,
    link: function (scope, element, attrs) {
      var strongest_speed_display = new SegmentDisplay("strongest-speed-display");
      var middle_display = new SegmentDisplay("middle-display");
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
        
        middle_display.pattern         = "###";
        middle_display.displayAngle    = 0;
        middle_display.digitHeight     = 20;
        middle_display.digitWidth      = 12;
        middle_display.digitDistance   = 2.5;
        middle_display.segmentWidth    = 2.5;
        middle_display.segmentDistance = 0.5;
        middle_display.segmentCount    = 7;
        middle_display.cornerType      = 3;
        middle_display.colorOn         = "#ff0000";
        middle_display.colorOff        = "#4b1e05";
        middle_display.draw();
        
        patrol_speed_display.pattern         = "###";
        patrol_speed_display.displayAngle    = 0;
        patrol_speed_display.digitHeight     = 20;
        patrol_speed_display.digitWidth      = 12;
        patrol_speed_display.digitDistance   = 2.5;
        patrol_speed_display.segmentWidth    = 2.5;
        patrol_speed_display.segmentDistance = 0.5;
        patrol_speed_display.segmentCount    = 7;
        patrol_speed_display.cornerType      = 3;
        patrol_speed_display.colorOn         = "#00ff00";
        patrol_speed_display.colorOff        = "#1e4b05";
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
        if (!data.radar_xmitting) {
          //Radar hold mode (not transmitting)
          strongest_speed_display.setValue('');
          middle_display.setValue('HLd');
          patrol_speed_display.setValue('');
        }
        else{
          //Transmitting
          
          //Left Display
          
          if (data.strongest_speed !== undefined) {
            var strongest_speed_str = Math.min(999, Math.trunc(Math.abs(data.strongest_speed * 2.23694))).toString();
            strongest_speed_display.setValue(convertToDisplay(strongest_speed_str));
          }
          else {
            strongest_speed_display.setValue('');
          } 
          
          //Middle Display
          
          switch(data.middle_display_mode) {
            case "fastest_speed":
              if (data.fastest_speed !== undefined) {
                var fastest_speed_str = Math.min(999, Math.trunc(Math.abs(data.fastest_speed * 2.23694))).toString();
                middle_display.setValue(convertToDisplay(fastest_speed_str));
              }
              else {
                middle_display.setValue('');
              }
              break;
            
            case "locked_speed":
              var locked_speed_str = Math.min(999, Math.trunc(Math.abs(data.locked_speed * 2.23694))).toString();
              middle_display.setValue(convertToDisplay(locked_speed_str));
            
              break;
          }           
          
          //Right Display
          
          if (data.patrol_speed !== undefined) {
            var patrol_speed_str = Math.min(999, Math.trunc(Math.abs(data.patrol_speed * 2.23694))).toString();     
            patrol_speed_display.setValue(convertToDisplay(patrol_speed_str));
          }
          else {
            patrol_speed_display.setValue('');
          }  
        }
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