set ns [new Simulator]

set b [lindex $argv 0]
set ton 1
set bursttime [expr $ton]ms
set idletime [expr ($b - 1) * $ton]ms
set bitrate [expr $b * 30]Mb

set countBlock 0
set globalMoy 0.0
set voiceMoy 0.0
set dataMoy 0.0
set videoMoy 0.0

proc finish {} {
	global ns simulLength blocLength b
	global globalMoy countBlock voiceMoy dataMoy videoMoy
	affiche-traces
	puts "$b [expr $globalMoy / $countBlock ] [expr $voiceMoy / $countBlock ] [expr $dataMoy / $countBlock ] [expr $videoMoy / $countBlock ]"
	$ns flush-trace
	exit 0
}


proc affiche-traces {} {
	global ns tf samples_object dsampVoice dsampData dsampVideo
	global monitorNANB blocLength
	global countBlock globalMoy voiceMoy dataMoy videoMoy

	set countBlock [expr $countBlock + 1]
	set globalMoy [expr $globalMoy + [$samples_object mean] ]
	set voiceMoy [expr $voiceMoy + [$dsampVoice mean] ]
	set dataMoy [expr $dataMoy + [$dsampData mean] ]
	set videoMoy [expr $videoMoy + [$dsampVideo mean] ]

	$samples_object reset
	$dsampVideo reset
	$dsampData reset
	$dsampVoice reset

	$ns at [expr [$ns now] + $blocLength] "affiche-traces"
}

set int_rel_cbr 3.0
proc relance-cbr {} {
	global cbrVo int_rel_cbr ns agentVo
	$cbrVo stop
	delete $cbrVo
	set cbrVo [new Application/Traffic/CBR]
	$cbrVo set packet_size_ 100
	$cbrVo set rate_ 20Mb
	$cbrVo attach-agent $agentVo
	$cbrVo start
	$ns at [expr [$ns now] + $int_rel_cbr] "relance-cbr"
} 

#Nodes
set nVoice [$ns node]
set nData [$ns node]
set nVideo [$ns node]
set na [$ns node]
set nb [$ns node]


$ns simplex-link $nVoice $na 1Gb 0.0000001ms DropTail
$ns simplex-link $nData $na 1Gb 0.0000001ms DropTail
$ns simplex-link $nVideo $na 1Gb 0.0000001ms DropTail
$ns simplex-link $na $nb 100Mb 0.0ms dsRED/edge

$ns queue-limit $nVoice $na 999999999
$ns queue-limit $nData $na 999999999
$ns queue-limit $nVideo $na 999999999
$ns queue-limit $na $nb 999999999

#Agents
set agentVo [new Agent/UDP]
set agentDa1 [new Agent/UDP]
set agentDa2 [new Agent/UDP]
set agentDa3 [new Agent/UDP]
set agentVi [new Agent/UDP]

set agentVoDest [new Agent/Null]
set agentDa1Dest [new Agent/Null]
set agentDa2Dest [new Agent/Null]
set agentDa3Dest [new Agent/Null]
set agentViDest [new Agent/Null]

$agentVo set fid_ 1
$agentDa1 set fid_ 2
$agentDa2 set fid_ 2
$agentDa3 set fid_ 2
$agentVi set fid_ 3

#$agentVo set packetSize_ 100
#$agentDa1 set packetSize_ 50
#$agentDa2 set packetSize_ 500
#$agentDa3 set packetSize_ 1500
#$agentVi set packetSize_ 1000

$ns attach-agent $nVoice $agentVo
$ns attach-agent $nData $agentDa1
$ns attach-agent $nData $agentDa2
$ns attach-agent $nData $agentDa3
$ns attach-agent $nVideo $agentVi

$ns attach-agent $nb $agentVoDest
$ns attach-agent $nb $agentDa1Dest
$ns attach-agent $nb $agentDa2Dest
$ns attach-agent $nb $agentDa3Dest
$ns attach-agent $nb $agentViDest

#Trafics
set cbrVo [new Application/Traffic/CBR]
$cbrVo set packet_size_ 100
$cbrVo set rate_ 20Mb
$cbrVo set random_ 1

set expoDa1 [new Application/Traffic/Exponential]
$expoDa1 set packetSize_ 50
$expoDa1 set burst_time_ 0
$expoDa1 set idle_time_ 0.413ms
$expoDa1 set rate_ 9999Mb

set expoDa2 [new Application/Traffic/Exponential]
$expoDa2 set packetSize_ 500
$expoDa2 set burst_time_ 0
$expoDa2 set idle_time_ 0.551ms
$expoDa2 set rate_ 9999Mb

set expoDa3 [new Application/Traffic/Exponential]
$expoDa3 set packetSize_ 1500
$expoDa3 set burst_time_ 0
$expoDa3 set idle_time_ 0.551ms
$expoDa3 set rate_ 9999Mb

set expoVi [new Application/Traffic/Exponential]
$expoVi set packetSize_ 1000
$expoVi set burst_time_ $bursttime
$expoVi set idle_time_ $idletime
$expoVi set rate_ $bitrate

$cbrVo attach-agent $agentVo
$expoDa1 attach-agent $agentDa1
$expoDa2 attach-agent $agentDa2
$expoDa3 attach-agent $agentDa3
$expoVi attach-agent $agentVi

#Lien Na Nb dsRED/edge
set qnanb [[$ns link $na $nb] queue] 
$qnanb set numQueues_ 1					
$qnanb setNumPrec 1					
$qnanb meanPktSize 287.37			
$qnanb addPolicyEntry [$nVoice id] [$nb id] Null 10	
$qnanb addPolicyEntry [$nData id] [$nb id] Null 11		
$qnanb addPolicyEntry [$nVideo id] [$nb id] Null 12
$qnanb addPolicerEntry Null 10
$qnanb addPolicerEntry Null 11
$qnanb addPolicerEntry Null 12
$qnanb addPHBEntry 10 0 0
$qnanb addPHBEntry 11 0 0
$qnanb addPHBEntry 12 0 0
 $qnanb setMREDMode DROP 0		
$qnanb configQ 0 0 1000 999999999 1.0

#Affichages des traces
set monitorNANB [$ns makeflowmon Fid]
$ns attach-fmon [$ns link $na $nb] $monitorNANB

set samples_object [new Samples]
$monitorNANB set-delay-samples $samples_object

set fdescVoice [new QueueMonitor/ED/Flow]
set dsampVoice [new Samples]
$fdescVoice set-delay-samples $dsampVoice

set fdescData [new QueueMonitor/ED/Flow]
set dsampData [new Samples]
$fdescData set-delay-samples $dsampData

set fdescVideo [new QueueMonitor/ED/Flow]
set dsampVideo [new Samples]
$fdescVideo set-delay-samples $dsampVideo

set classif [$monitorNANB classifier]
$classif set-hash auto $agentVo $agentVoDest 1 [$classif installNext $fdescVoice]
$classif set-hash auto $agentDa1 $agentDa1Dest 2 [$classif installNext $fdescData]
$classif set-hash auto $agentDa2 $agentDa2Dest 2 [$classif installNext $fdescData]
$classif set-hash auto $agentDa3 $agentDa3Dest 2 [$classif installNext $fdescData]
$classif set-hash auto $agentVi $agentViDest 3 [$classif installNext $fdescVideo]



$ns connect $agentVo $agentVoDest
$ns connect $agentDa1 $agentDa1Dest
$ns connect $agentDa2 $agentDa2Dest
$ns connect $agentDa3 $agentDa3Dest
$ns connect $agentVi $agentViDest

set blocLength 5
set simulLength 100
$ns at $blocLength "affiche-traces"
#$ns at $int_rel_cbr "relance-cbr"
$ns at 0.0 "$cbrVo start"
$ns at 0.0 "$expoDa1 start"
$ns at 0.0 "$expoDa2 start"
$ns at 0.0 "$expoDa3 start"
$ns at 0.0 "$expoVi start"
$ns at $simulLength "$cbrVo stop"
$ns at $simulLength "$expoDa1 stop"
$ns at $simulLength "$expoDa2 stop"
$ns at $simulLength "$expoDa3 stop"
$ns at $simulLength "$expoVi stop"
$ns at $simulLength "finish"
$ns run