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
    
    
        var streamsList = ['wheelInfo', 'electrics', 'sensors'];
        StreamsManager.add(streamsList);
        
        
        scope.$on('sendRadarInfo', function (event, data) {
            strongest_speed.textContent = Math.trunc(data.strongest_speed * 3.6) + " km/h";
            
            if (data.fastest_speed !== undefined) {
            	fastest_speed.textContent = Math.trunc(data.fastest_speed * 3.6) + " km/h";
            }
            else {
                fastest_speed.textContent = "";
            }       
            
            patrol_speed.textContent = Math.trunc(data.patrol_speed * 3.6) + " km/h";
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