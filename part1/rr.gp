set grid
set title "Latence des flux en fonction de la sporadicité du flux vidéo avec Round Robin"
set xlabel "Sporadicité du flux vidéo"
set ylabel "Latence (ms)"
set terminal svg size 1754,1240 rounded
set output "rr.svg"

plot 	"./rr-2-ms.tr" u 1:2 title "Global" w l, \
			"./rr-2-ms.tr" u 1:3 title "Données" w l, \
			"./rr-2-ms.tr" u 1:4 title "Voix" w l, \
			"./rr-2-ms.tr" u 1:5 title "Vidéo" w l
