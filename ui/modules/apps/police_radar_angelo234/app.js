angular.module('beamng.apps')
.directive('policeRadarAngelo234', ['$log', 'StreamsManager', 'Utils', 'UiUnits', function ($log, StreamsManager, Utils, UiUnits) {
  return {
    restrict: 'E',
    templateUrl: 'modules/apps/police_radar_angelo234/app.html',
    replace: true,
    link: function (scope, element, attrs) {
      var strongest_speed_display = new SegmentDisplay("strongest-speed-display");
      var middle_display = new SegmentDisplay("middle-display");
      var patrol_speed_display = new SegmentDisplay("patrol-speed-display");
      
      var locked_speed_indicator = document.getElementById('locked-speed-indicator');
      var fastest_speed_indicator = document.getElementById('fastest-speed-indicator');
      
      var streamsList = ['wheelInfo', 'electrics', 'sensors'];
      StreamsManager.add(streamsList);
          
      function initSegmentDisplays() {    
        strongest_speed_display.pattern         = "###";
        strongest_speed_display.displayAngle    = 5;
        strongest_speed_display.digitHeight     = 60;
        strongest_speed_display.digitWidth      = 37.5;
        strongest_speed_display.digitDistance   = 10;
        strongest_speed_display.segmentWidth    = 7.5;
        strongest_speed_display.segmentDistance = 1;
        strongest_speed_display.segmentCount    = 7;
        strongest_speed_display.cornerType      = 3;
        strongest_speed_display.colorOn         = "#FD7102";
        strongest_speed_display.colorOff        = "#5A2302";
        strongest_speed_display.draw();
        
        middle_display.pattern         = "###";
        middle_display.displayAngle    = 5;
        middle_display.digitHeight     = 60;
        middle_display.digitWidth      = 37.5;
        middle_display.digitDistance   = 10;
        middle_display.segmentWidth    = 7.5;
        middle_display.segmentDistance = 1;
        middle_display.segmentCount    = 7;
        middle_display.cornerType      = 3;
        middle_display.colorOn         = "#F40C0A";
        middle_display.colorOff        = "#460000";
        middle_display.draw();
        
        patrol_speed_display.pattern         = "###";
        patrol_speed_display.displayAngle    = 5;
        patrol_speed_display.digitHeight     = 60;
        patrol_speed_display.digitWidth      = 37.5;
        patrol_speed_display.digitDistance   = 10;
        patrol_speed_display.segmentWidth    = 7.5;
        patrol_speed_display.segmentDistance = 1;
        patrol_speed_display.segmentCount    = 7;
        patrol_speed_display.cornerType      = 3;
        patrol_speed_display.colorOn         = "#0FF439";
        patrol_speed_display.colorOff        = "#005B44";
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
          
          locked_speed_indicator.style.color = "black";
          fastest_speed_indicator.style.color = "black";
        }
        else{
          //Transmitting
          
          //Left Display
          
          if (data.strongest_speed !== undefined) {
            var speed = UiUnits.speed(data.strongest_speed).val;
          
            var strongest_speed_str = Math.min(999, Math.trunc(Math.abs(speed))).toString();
            strongest_speed_display.setValue(convertToDisplay(strongest_speed_str));
          }
          else {
            strongest_speed_display.setValue('');
          } 
          
          //Middle Display
          
          switch(data.middle_display_mode) {
            case "fastest_speed":
              if (data.fastest_speed !== undefined) {
                var speed = UiUnits.speed(data.fastest_speed).val;
              
                var fastest_speed_str = Math.min(999, Math.trunc(Math.abs(speed))).toString();
                middle_display.setValue(convertToDisplay(fastest_speed_str));
              }
              else {
                middle_display.setValue('');
              }
              
              locked_speed_indicator.style.color = "black";
              fastest_speed_indicator.style.color = "red";
              
              break;
            
            case "locked_speed":
              var speed = UiUnits.speed(data.locked_speed).val;
              
              var locked_speed_str = Math.min(999, Math.trunc(Math.abs(speed))).toString();
              middle_display.setValue(convertToDisplay(locked_speed_str));
            
              locked_speed_indicator.style.color = "red";
              fastest_speed_indicator.style.color = "black";
            
              break;
          }           
          
          //Right Display
          
          if (data.patrol_speed !== undefined) {
            var speed = UiUnits.speed(data.patrol_speed).val;
          
            var patrol_speed_str = Math.min(999, Math.trunc(Math.abs(speed))).toString();     
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