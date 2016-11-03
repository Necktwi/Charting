#! /usr/local/Cellar/bash/4.4_1/bin/bash

# Substitute for `read -r' that doesn't merge adjacent delimiters.
# http://stackoverflow.com/questions/4622355/read-in-bash-on-tab-delimited-file-without-empty-fields-collapsing#answer-19538478
myread() {
    local input
    IFS= read -r input || return $?
    while [[ "$#" > 1 ]]; do
        IFS= read -r "$1" <<< "${input%%[$IFS]*}"
        input="${input#*[$IFS]}"
        shift
    done
    IFS= read -r "$1" <<< "$input"
}

TotalNetworkDevices=0;
TotalTraffic=0;

# Declare associative array TrafficFrom
declare -A TrafficFrom

# Read the frames from wificapture-1.txt and each frame field
# Addr2 is the source address
# http://unix.stackexchange.com/questions/41232/loop-through-tab-delineated-file-in-bash-script
while myread Time Addr1 Addr2 Addr3 Addr4 Length Channel Description; do
    if [ $Addr2 ]; then \
        if [ ${TrafficFrom["$Addr2"]} ]; then \
            (( ++TrafficFrom["$Addr2"] ))
        else
            TrafficFrom["$Addr2"]=1
            (( ++TotalNetworkDevices ))
        fi
        (( ++TotalTraffic ))
    fi
done < wificapture-1.txt
echo "TotalNetworkDevices=$TotalNetworkDevices"
echo "TotalTraffic=$TotalTraffic"
MaxTraffic=0
for Addr2 in "${!TrafficFrom[@]}"; do
    echo "TrafficFrom[$Addr2]=${TrafficFrom[$Addr2]}"
    if [ ${TrafficFrom[$Addr2]} > $MaxTraffic ]; then \
        MaxTraffic=${TrafficFrom[$Addr2]}
    fi
done
echo "MaxTraffic=$MaxTraffic"
declare -A TrafficInRange
Power2NearMax=1
while [ $Power2NearMax < $MaxTraffic ]; do
    (( Power2NearMax=2*Power2NearMax ))
    TrafficInRange[$Power2NearMax]=0
    echo "TrafficInRange[$Power2NearMax]:${TrafficInRange[$Power2NearMax]}"
done

for Addr2 in "${!TrafficFrom[@]}"; do
    for Range in "${!TrafficInRange[@]}"; do
        if [ $Range > ${TrafficFrom[$Addr2]} ]; then \
            (( ++TrafficInRange[$Range] ))
            break
        fi
    done
done
for Range in "${!TrafficInRange[@]}"; do
    echo "TrafficInRange[$Range]:${TrafficInRange[$Range]}"
done

# Create and open html file that produces pie chart
# http://stackoverflow.com/questions/11917818/make-a-simple-pie-graph-using-bash-shell-script
TEMP=GoogleChart.html
QUERY1=36
QUERY2=64
cat > $TEMP << EOF
<html>
<head>
<!--Load the AJAX API-->
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">

// Load the Visualization API and the piechart package.
google.load('visualization', '1.0', {'packages':['corechart']});

// Set a callback to run when the Google Visualization API is loaded.
google.setOnLoadCallback(drawChart);

// Callback that creates and populates a data table,
// instantiates the pie chart, passes in the data and
// draws it.
function drawChart() {

// Create the data table.
var data = new google.visualization.DataTable();
data.addColumn('string', 'Title');
data.addColumn('number', 'Value');
data.addRows([
['Error Percentage', $QUERY1],
['No Error Percentage', $QUERY2]
]);

// Set chart options
var options = {'title':'Errors',
'width':400,
'height':300};

// Instantiate and draw our chart, passing in some options.
var chart = new google.visualization.PieChart(document.getElementById('chart_div'));
chart.draw(data, options);
}
</script>
</head>

<body>
<!--Div that will hold the pie chart-->
<div id="chart_div"></div>
</body>
</html>
EOF

# open browser
case $(uname) in
Darwin)
open -a /Applications/Safari.app $TEMP
;;

Linux|SunOS)
firefox $TEMP
;;
esac
