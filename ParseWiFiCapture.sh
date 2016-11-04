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
    if [ ${TrafficFrom[$Addr2]} -gt $MaxTraffic ]; then \
        MaxTraffic=${TrafficFrom[$Addr2]}
    fi
done
echo "MaxTraffic=$MaxTraffic"
Increment=MaxTraffic/20
(( ++Increment ))
declare -A TrafficInRange
declare -a TrafficRanges
Power2NearMax=1
i=0
while [[ $MaxTraffic -gt "$Power2NearMax" ]]; do
    (( Power2NearMax*=2 ))
    TrafficInRange[$Power2NearMax]=0
    TrafficRanges[$i]=$Power2NearMax
    (( ++i ))
done

for Addr2 in "${!TrafficFrom[@]}"; do
    for i in "${!TrafficRanges[@]}"; do
        Range=${TrafficRanges[$i]}
        if [ $Range -gt ${TrafficFrom[$Addr2]} ]; then \
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
data = new google.visualization.DataTable();
data.addColumn('string', 'Title');
data.addColumn('number', 'Value');
data.addRows([
EOF
for i in "${!TrafficRanges[@]}"; do
    Range=${TrafficRanges[$i]}
    echo "['$Range', ${TrafficInRange[$Range]}]," >> $TEMP
done
cat >> $TEMP << EOF
]);

// Set chart options
var options = {'title':'n frames',
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
<div id="Description">Each pie represents fraction of clients producing 'n' number of frames</div>
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
