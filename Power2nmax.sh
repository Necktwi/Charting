#! /usr/local/Cellar/bash/4.4_1/bin/bash

declare -A TrafficInRange
Power2NearMax=1;
MaxTraffic=2000;
while [ $MaxTraffic > $Power2NearMax ]; do
    echo "Power2NearMax=$Power2NearMax"
    (( Power2NearMax*=2 ));
    TrafficInRange[$Power2NearMax]=0;
    echo "MaxTraffic=$MaxTraffic"
    echo "TrafficInRange[$Power2NearMax]:${TrafficInRange[$Power2NearMax]}";
done

