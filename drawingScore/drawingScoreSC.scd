//Time Composition
NdefMixer.new(s);
s.options.outDevice = ("Multi-Output Device");

s.options.memSize = 8192*16;
s.options.numWireBufs = 64*8;


(
~num = 72;
Ndef(\time,{

	var root = \root.kr(65.406);
	var harms = \harms.kr((1..~num), 0.2)
	.collect { |harm| harm * LFDNoise3.kr(exprand(0.2, 2), 0.08, 1) };
	var freqs = root * harms;

	var ampcomps = AmpComp.kr(freqs, 250, 0.6);
	var amps = \amps.kr(0!~num, 0.2) * ampcomps;

	var sig = SinOsc.ar(freqs, mul: amps);

	// amps[0].poll;
	Splay.ar(sig.clump(2).flop.flat) * 0.2;
})
);

/*
Ndef(\time).clear;
Ndef(\time).gui;
Ndef(\time).set(\amps,  0.1!~num);
Ndef(\time).set(\amps,  { 0.5.rand }!~num);
Ndef(\time).set(\amps,  { 0.1.rand }!~num);
Ndef(\time).set(\amps,  0.0!~num);

Ndef(\time).set(\harms,  (1..~num));

Ndef(\time).set(\harms,  (1..~num).collect { |num| num  + 0.03.bilinrand });


Ndef(\time).set(\amps,  [0.1, 0, 0.1, 0, 0, 0.1, 0].wrapExtend(39));
*/

(

//[1400,1800] get less bg low sound;
//[1400,1700] get more bg low sound;

~greyrange = [ 1400, 1700];

OSCdef(\processingListener, { |msg|
	var vals = msg.drop(1).reverse;
	vals = vals.linlin(~greyrange[0], ~greyrange[1],3,0);
	// vals.round(0.01).postln;
	// msg.keep(-5).postln;

	Ndef(\time).set(\amps, vals);

}, '/drawingScore');
);

NetAddr.langPort;




