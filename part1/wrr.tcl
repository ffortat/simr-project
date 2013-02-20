set ns [new Simulator]

set b [lindex $argv 0]
set ton 1
set bursttime [expr $ton]ms
set idletime [expr ($b - 1) * $ton]ms
set bitrate [expr $b * 30]Mb

proc finish {} {
	global ns
	processblock
	displaymeans
	$ns flush-trace
	exit 0
}

set simulationlength 100.0
set blocklength 5.0

set nbvalues 0
set meanglobal 0.0
set meandata 0.0
set meanvoice 0.0
set meanvideo 0.0

proc displaymeans {} {
	global simulationlength blocklength
	global b meanglobal meandata meanvoice meanvideo nbvalues

	puts "$b \
		[expr $meanglobal / $nbvalues] \
		[expr $meandata / $nbvalues] \
		[expr $meanvoice / $nbvalues] \
		[expr $meanvideo / $nbvalues]"
}

proc processblock {} {
	global ns b blocklength simulationlength
	global samples samplesdata samplesvoice samplesvideo monitor
	global meanglobal meandata meanvoice meanvideo nbvalues

	$ns at [expr [$ns now] + $blocklength] "processblock"

	set nbvalues [expr $nbvalues + 1]
	set meanglobal [expr $meanglobal + [$samples mean]]
	set meandata [expr $meandata + [$samplesdata mean]]
	set meanvoice [expr $meanvoice + [$samplesvoice mean]]
	set meanvideo [expr $meanvideo + [$samplesvideo mean]]
	# puts "[$samples mean] [$samplesdata mean] [$samplesvoice mean] [$samplesvideo mean] [$monitor set parrivals_] [$monitor set pdrops_]" ; # [$samples cnt] [$samplesdata cnt] [$samplesvoice cnt] [$samplesvideo cnt]"
	$samples reset
	# $samplesdata reset
	# $samplesvoice reset
	# $samplesvideo reset
}

# Définition des trois nœuds source
set nda [$ns node] ; # Données
set nvo [$ns node] ; # Voix
set nvi [$ns node] ; # Vidéo

# Définition des nœuds pour le dsRED/edge
set nq [$ns node] ; # File d'attente
set ndes [$ns node] ; # Destination

# nda \
#      \      RED
# nvo -- nq ------- ndes
#      /
# nvi /


# Création des liens entre les 3 sources et la file d'attente RED
$ns simplex-link $nda $nq 10Gb 0.0ns DropTail
$ns queue-limit $nda $nq 1000000000
$ns simplex-link $nvo $nq 10Gb 0.0ns DropTail
$ns queue-limit $nvo $nq 1000000000
$ns simplex-link $nvi $nq 10Gb 0.0ns DropTail
$ns queue-limit $nvi $nq 1000000000

$ns simplex-link $nq $ndes 100Mb 0.0ns dsRED/edge
$ns queue-limit $nq $ndes 1000000000
set qred [[ $ns link $nq $ndes ] queue ]

# Création des agents UDP (stream audio/vidéo/data)
set agentdata1 [new Agent/UDP]
$agentdata1 set fid_ 1
set agentdata2 [new Agent/UDP]
$agentdata2 set fid_ 1
set agentdata3 [new Agent/UDP]
$agentdata3 set fid_ 1
set agentvoice [new Agent/UDP]
$agentvoice set fid_ 2
set agentvideo [new Agent/UDP]
$agentvideo set fid_ 3

set agentdestdata1 [new Agent/Null]
set agentdestdata2 [new Agent/Null]
set agentdestdata3 [new Agent/Null]
set agentdestvoice [new Agent/Null]
set agentdestvideo [new Agent/Null]

# On attache les agents aux nœuds
$ns attach-agent $nda $agentdata1
$ns attach-agent $nda $agentdata2
$ns attach-agent $nda $agentdata3
$ns attach-agent $nvo $agentvoice
$ns attach-agent $nvi $agentvideo
$ns attach-agent $ndes $agentdestdata1
$ns attach-agent $ndes $agentdestdata2
$ns attach-agent $ndes $agentdestdata3
$ns attach-agent $ndes $agentdestvoice
$ns attach-agent $ndes $agentdestvideo

# Connexions
$ns connect $agentdata1 $agentdestdata1
$ns connect $agentdata2 $agentdestdata2
$ns connect $agentdata3 $agentdestdata3
$ns connect $agentvoice $agentdestvoice
$ns connect $agentvideo $agentdestvideo

# Sources de trafic
# Data : Poisson 50
set data1 [new Application/Traffic/Exponential]
$data1 set packetSize_ 50
$data1 set burst_time_ 0
$data1 set idle_time_ 0.413ms ; # en secondes (débit de paquets)
$data1 set rate_ 9999Mb
$data1 attach-agent $agentdata1
# Data : Poisson 500
set data2 [new Application/Traffic/Exponential]
$data2 set packetSize_ 500
$data2 set burst_time_ 0
$data2 set idle_time_ 0.551ms
$data2 set rate_ 9999Mb
$data2 attach-agent $agentdata2
# Data : Poisson 1500
set data3 [new Application/Traffic/Exponential]
$data3 set packetSize_ 1500
$data3 set burst_time_ 0
$data3 set idle_time_ 0.551ms
$data3 set rate_ 9999Mb
$data3 attach-agent $agentdata3

# Voice : CBR
set voice [new Application/Traffic/CBR]
$voice set packet_size_ 100
$voice set rate_ 20Mb
$voice set random_ 1
$voice attach-agent $agentvoice

# Video : ON/OFF
set video [new Application/Traffic/Exponential]
$video set packet_size_ 1000
$video set burst_time_ $bursttime
$video set idle_time_ $idletime
$video set rate_ $bitrate
$video attach-agent $agentvideo
# FIN : Sources de trafic


# Configuration de la Queue (doc. cf. notes-projet)
$qred set numQueues_ 3
$qred setNumPrec 1
$qred meanPktSize 287
$qred addPolicyEntry [$nda id] [$ndes id] Null 10
$qred addPolicyEntry [$nvo id] [$ndes id] Null 11
$qred addPolicyEntry [$nvi id] [$ndes id] Null 12
$qred addPolicerEntry Null 10
$qred addPolicerEntry Null 11
$qred addPolicerEntry Null 12
$qred addPHBEntry 10 0 0
$qred addPHBEntry 11 1 0
$qred addPHBEntry 12 2 0
$qred setMREDMode DROP 0
$qred setMREDMode DROP 1
$qred setMREDMode DROP 2
$qred configQ 0 0 1000000 1000000 1.0
$qred configQ 1 0 1000000 1000000 1.0
$qred configQ 2 0 1000000 1000000 1.0

$qred setSchedularMode WRR
$qred addQueueWeights 0 30	; # data
$qred addQueueWeights 1 310 ; # voix
$qred addQueueWeights 2 50	; # video

# Définition du moniteur pour la trace
set monitor [$ns makeflowmon Fid]
$ns attach-fmon [$ns link $nq $ndes] $monitor
set classif [$monitor classifier]

# Samples global
set samples [new Samples]
$monitor set-delay-samples $samples

# Samples pour Données
set flowdata [new QueueMonitor/ED/Flow]
set samplesdata [new Samples]
$flowdata set-delay-samples $samplesdata
$classif set-hash auto $agentdata1 $agentdestdata1 1 [$classif installNext $flowdata]
$classif set-hash auto $agentdata2 $agentdestdata2 1 [$classif installNext $flowdata]
$classif set-hash auto $agentdata3 $agentdestdata3 1 [$classif installNext $flowdata]

# Samples pour Voix
set flowvoice [new QueueMonitor/ED/Flow]
set samplesvoice [new Samples]
$flowvoice set-delay-samples $samplesvoice
$classif set-hash auto $agentvoice $agentdestvoice 2 [$classif installNext $flowvoice]

# Samples pour video
set flowvideo [new QueueMonitor/ED/Flow]
set samplesvideo [new Samples]
$flowvideo set-delay-samples $samplesvideo
$classif set-hash auto $agentvideo $agentdestvideo 3 [$classif installNext $flowvideo]




# Définition de démarrage et arrêt du trafic
$ns at 0.0 "$data1 start"
$ns at 0.0 "$data2 start"
$ns at 0.0 "$data3 start"
$ns at 0.0 "$voice start"
$ns at 0.0 "$video start"
$ns at $simulationlength "$data1 stop"
$ns at $simulationlength "$data2 stop"
$ns at $simulationlength "$data3 stop"
$ns at $simulationlength "$voice stop"
$ns at $simulationlength "$video stop"

# Définition de la durée d'exécution
$ns at $simulationlength "finish"

# Lancement de NS
$ns at $blocklength "processblock"
$ns run