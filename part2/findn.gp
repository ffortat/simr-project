set grid
plot "./findn-10_190_5.tr" u 1:2 title "Global loss rate" w l 
replot "./findn-10_190_5.tr" u 1:3 title "Data loss rate" w l 
replot "./findn-10_190_5.tr" u 1:4 title "Voice loss rate" w l 
replot "./findn-10_190_5.tr" u 1:5 title "Video loss rate" w l 

set terminal svg rounded
set output "findn.svg"
replot