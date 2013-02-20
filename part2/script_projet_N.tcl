set ns [new Simulator]

proc finish {} {
	global ns tf samples_object
	$ns flush-trace
	exit 0
}

proc relance_cbr {} {
	global cbr1 it_rel_cbr ns agentvoix
	$cbr1 stop
	delete $cbr1
	set cbr1 [new Application/Traffic/CBR]
	$cbr1 set packet_size_ 100
	$cbr1 set rate 20Mb
	$cbr1 attach-agent $agentvoix
	$cbr1 start
	$ns at [ expr [$ns now + $int_rel_cbr] "relance_cbr"
}

proc affiche-delais {} {
	global monitor_nAnB globalsample dsampvideo dsampledonnee dsampvoix buffer
	set arrivals [$monitor_nAnB set parrivals_]
	set pdrops [$monitor_nAnB set pdrops_ ]
	set dropRate [expr [$monitor_nAnB set pdrops_ ]* (1.0/[$monitor_nAnB set parrivals_]) ]	
	puts "$buffer    $dropRate"
}

set b [lindex $argv 0]
set rate [expr ($b * 30)]Mb
set buffer [lindex $argv 1]

set na [$ns node]
set nb [$ns node]
set nodeData [$ns node]
set nodeVideo [$ns node]
set nodeVoix [$ns node]

set donnee1 [new Application/Traffic/Exponential]
$donnee1 set packetSize_ 50
$donnee1 set burst_time_ 0
$donnee1 set idle_time_ 0.413ms
$donnee1 set rate_ 100Gb

set donnee2 [new Application/Traffic/Exponential]
$donnee2 set packetSize_ 500
$donnee2 set burst_time_ 0
$donnee2 set idle_time_ 0.5511ms
$donnee2 set rate_ 100Gb

set donnee3 [new Application/Traffic/Exponential]
$donnee3 set packetSize_ 1500
$donnee3 set burst_time_ 0
$donnee3 set idle_time_ 0.5511ms
$donnee3 set rate_ 100Gb

set voix [new Application/Traffic/CBR]
$voix set rate_ 20Mb
$voix set packet_size_ 100
$voix set random_ 1

set video [new Application/Traffic/Exponential]
$video set packetSize_ 1000
$video set burst_time_ 0.001
$video set idle_time_  0.002
$video set rate_  $rate


$ns simplex-link $nodeData $na 10Gb 0.0ns DropTail
$ns queue-limit $nodeData $na 10000000
$ns simplex-link $nodeVoix $na 10Gb 0.0ns DropTail
$ns queue-limit $nodeVoix $na 10000000
$ns simplex-link $nodeVideo $na 10Gb 0.0ns DropTail
$ns queue-limit $nodeVideo $na 10000000

$ns simplex-link $na $nb 100Mb 0.0ns dsRED/edge
$ns queue-limit $na $nb $buffer

set qnanb [[$ns link $na $nb] queue]

$qnanb set numQueues_ 1
$qnanb setNumPrec 1
$qnanb meanPktSize 287

$qnanb addPolicyEntry [$nodeData id] [$nb id] Null 10
$qnanb addPolicyEntry [$nodeVideo id] [$nb id] Null 11
$qnanb addPolicyEntry [$nodeVoix id] [$nb id] Null 12

$qnanb addPolicerEntry Null 10
$qnanb addPolicerEntry Null 11
$qnanb addPolicerEntry Null 12

$qnanb addPHBEntry 10 0 0
$qnanb addPHBEntry 11 0 0
$qnanb addPHBEntry 12 0 0

$qnanb setMREDMode DROP 0
$qnanb configQ 0 0 $buffer 999999 1.0


set videoAgent [new Agent/UDP]
$videoAgent set fid_ 1
set donneeAgent1 [new Agent/UDP]
$donneeAgent1 set fid_  2
set donneeAgent2 [new Agent/UDP]
$donneeAgent2 set fid_  2
set donneeAgent3 [new Agent/UDP]
$donneeAgent3 set fid_  2
set voixAgent [new Agent/UDP]
$voixAgent set fid_  3

set donneeAgent1DST [new Agent/Null]
set donneeAgent2DST [new Agent/Null]
set donneeAgent3DST [new Agent/Null]

set voixAgentDST [new Agent/Null]

set videoAgentDST [new Agent/Null]

set monitor_nAnB [$ns makeflowmon Fid]
set globalsample [new Samples]
ns attach-fmon [$ns link $na $nb] $monitor_nAnB
$monitor_nAnB set-delay-samples $globalsample

set fdescvideo [new QueueMonitor/ED/Flow]
set dsampvideo [new Samples]
$fdescvideo set-delay-samples $dsampvideo
set classif [$monitor_nAnB classifier]
set slot2 [$classif installNext $fdescvideo]
$classif set-hash auto $videoAgent $videoAgentDST 1 $slot2

set fdescdonnee [new QueueMonitor/ED/Flow]
set dsampledonnee [new Samples]
$fdescdonnee set-delay-samples $dsampledonnee
$classif set-hash auto $donneeAgent1 $donneeAgent1DST 2 [$classif installNext $fdescdonnee]
$classif set-hash auto $donneeAgent2 $donneeAgent2DST 2 [$classif installNext $fdescdonnee]
$classif set-hash auto $donneeAgent3 $donneeAgent3DST 2 [$classif installNext $fdescdonnee]

set fdescvoix [new QueueMonitor/ED/Flow]
set dsampvoix [new Samples]
$fdescvoix set-delay-samples $dsampvoix
set slot3 [$classif installNext $fdescvoix]
$classif set-hash auto $voixAgent $voixAgentDST 3 $slot3

$ns attach-agent $nodeData $donneeAgent1
$ns attach-agent $nodeData $donneeAgent2
$ns attach-agent $nodeData $donneeAgent3
$ns attach-agent $nodeVoix $voixAgent
$ns attach-agent $nodeVideo $videoAgent

$ns attach-agent $nb $donneeAgent1DST
$ns attach-agent $nb $donneeAgent2DST
$ns attach-agent $nb $donneeAgent3DST
$ns attach-agent $nb $voixAgentDST
$ns attach-agent $nb $videoAgentDST

$video attach-agent $videoAgent
$voix attach-agent $voixAgent
$donnee1 attach-agent $donneeAgent1
$donnee2 attach-agent $donneeAgent2
$donnee3 attach-agent $donneeAgent3


$ns connect $donneeAgent1 $donneeAgent1DST
$ns connect $donneeAgent2 $donneeAgent2DST
$ns connect $donneeAgent3 $donneeAgent3DST
$ns connect $voixAgent $voixAgentDST
$ns connect $videoAgent $videoAgentDST

$ns at 0.0 "$donnee1 start"
$ns at 0.0 "$donnee2 start"
$ns at 0.0 "$donnee3 start"
$ns at 0.0 "$voix start"
$ns at 0.0 "$video start"

$ns at 100 "$donnee1 stop"
$ns at 100 "$donnee2 stop"
$ns at 100 "$donnee3 stop"
$ns at 100 "$voix stop"
$ns at 100 "$video stop"

$ns at 100 "affiche-delais"
$ns at 100 "finish"
$ns run
