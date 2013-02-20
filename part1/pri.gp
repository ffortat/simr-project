set grid
set title "Latence des flux en fonction de la sporadicité du flux vidéo avec priorité"
set xlabel "Sporadicité du flux vidéo"
set ylabel "Latence (ms)"
set terminal svg size 1754,1240 rounded
set output "pri.svg"

plot 	"./pri-2-ms.tr" u 1:2 title "Global" w l, \
			"./pri-2-ms.tr" u 1:3 title "Données" w l, \
			"./pri-2-ms.tr" u 1:4 title "Voix" w l, \
			"./pri-2-ms.tr" u 1:5 title "Video" w l

set logscale y
set output "pri-log.svg"
replot
unset logscale y