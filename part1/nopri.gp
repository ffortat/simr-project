set grid
set title "Latence des flux en fonction de la sporadicité du flux vidéo sans priorité"
set xlabel "Sporadicité du flux vidéo"
set ylabel "Latence (ms)"
set terminal svg size 1754,1240 rounded
set output "nopri.svg"

plot 	"./nopri-2-ms.tr" u 1:2 title "Global" w l, \
			"./nopri-2-ms.tr" u 1:3 title "Données" w l, \
			"./nopri-2-ms.tr" u 1:4 title "Voix" w l, \
			"./nopri-2-ms.tr" u 1:5 title "Vidéo" w l
