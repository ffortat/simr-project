set grid
set logscale y
plot "./findth-2_172_2.tr" u 1:2 title "Data loss rate" w l 
replot "./findth-2_172_2.tr" u 1:3 title "Realtime loss rate" w l 

set terminal svg rounded
set output "findth.svg"
replot