set grid
set title "Latence des flux en fonction de la sporadicité du flux vidéo avec Round Robin pondéré"
set xlabel "Sporadicité du flux vidéo"
set ylabel "Latence (ms)"
set terminal svg size 1754,1240 rounded
set output "wrr.svg"

plot 	"./wrr-2-ms.tr" u 1:2 title "Global" w l, \
			"./wrr-2-ms.tr" u 1:3 title "Données" w l, \
			"./wrr-2-ms.tr" u 1:4 title "Voix" w l, \
			"./wrr-2-ms.tr" u 1:5 title "Vidéo" w l
