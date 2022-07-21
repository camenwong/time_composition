//Time Composition
NdefMixer.new(s);
s.options.outDevice = ("Multi-Output Device");

s.options.memSize = 8192*16;
s.options.numWireBufs = 64*8;
~num = 72;

// (
// ~num = 72;
// Ndef(\time,{
//
// 	var root = \root.kr(65.406);
// 	var harms = \harms.kr((1..~num), 0.2)
// 	.collect { |harm| harm * LFDNoise3.kr(exprand(0.2, 2), 0.08, 1) };
// 	var freqs = root * harms;
//
// 	var ampcomps = AmpComp.kr(freqs, 250, 0.6);
// 	var amps = \amps.kr(0 ! ~num, 0.3) * ampcomps;
//
// 	var sig = SinOsc.ar(freqs, mul: amps);
//
// 	// amps[0].poll;
// 	Splay.ar(sig.clump(2).flop.flat) * 0.2;
// })
// );

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

// ~greyrange = [ 1400, 1700];
//
// OSCdef(\processingListener, { |msg|
// 	var vals = msg.drop(1).reverse;
// 	vals = vals.linlin(~greyrange[0], ~greyrange[1],   3, 0);
// 	// vals.round(0.01).postln;
// 	// msg.keep(-5).postln;
//
// 	Ndef(\time).set(\amps, vals);
//
// }, '/drawingScore');
// );
//
// NetAddr.langPort;

~brights = 127 ! 72;
(
OSCdef(\processingMonitor, { |msg|
	var vals = msg.drop(1).reverse;
	~brights  = vals.round(1).asInteger.postln;
}, '/drawingScore');
);
OSCdef(\processingMonitor).disable;


~plotter = ~brights.plot;
(
OSCdef(\processingPlotta, { |msg|
	var vals = msg.drop(1).reverse;
	~brights  = vals.round(1).asInteger;
	defer{ ~plotter.value = ~brights };
}, '/drawingScore');
);
OSCdef(\processingPlotta).disable;
OSCdef(\processingPlotta).enable;

~plotter.findSpecs_(false);
~plotter.specs = [0, 255, \lin, 1].asSpec;


// measure fps
~t0=0;
(
OSCdef(\p5Timing, { |msg, t|
	var dt = (t - ~t0);
	("fps: %\n").postf(1/dt);
	~t0 = t;
}, '/drawingScore');
);
OSCdef(\p5Timing).disable;

// averaging, autocalibration / bg reduction
(
~longtimeAvgs = 200 ! 72;
OSCdef(\p5_autocal, { |msg|
	var ratio = 0.003;
	var vals = msg.drop(1).reverse;
	var avg = vals.mean;
	// var diffs = avg - vals;
	// diffs.asInteger.postln;
	~longtimeAvgs = ((1-ratio) * ~longtimeAvgs) + (ratio * vals);
}, '/drawingScore');
);
OSCdef(\p5_autocal).disable;
OSCdef(\p5_autocal).enable;

// now, finally set the audio
(
OSCdef(\processingListener, { |msg|
	var vals = msg.drop(1).reverse;
	var diffs = ~longtimeAvgs - vals; // pos values for darkness
	var amps = diffs.max(0).linlin(0, 150, 0, 1);
	// diffs.asInteger.postln;
	~longTermDiffs = diffs;
	Ndef(\time).set(\amps, amps);

}, '/drawingScore');
);
OSCdef(\processingListener).enable;

(
// back to plotter
OSCdef(\processingPlotta, { |msg|
	var vals = msg.drop(1).reverse;
	~brights  = vals.round(1).asInteger;
	defer{ ~plotter.value = ~longTermDiffs };
}, '/drawingScore');
);
OSCdef(\processingPlotta).enable;

~plotter.specs = [-32, 255, \lin, 1].asSpec;


// snd
(
Ndef(\time).addSpec(\minFr, \freq);
Ndef(\time).addSpec(\maxFr, \freq);
Ndef(\time, { |minFr=65, maxFr=4000, amp=0.5|
	var freqs = (1 .. ~num).linexp(1, ~num, minFr, maxFr) ;
	var ampcomps = AmpComp.kr(freqs, 250, 0.6);
	var amps = \amps.kr(0 ! ~num, 0.3) * ampcomps;
	var sig = FSinOsc.ar(freqs* LFDNoise3.kr(exprand(0.2, 2),0.08, 1), mul: amps);
	// amps[0].poll;
	Splay.ar(sig.clump(2).flop.flat) * amp;
})
);

Ndef(\time).set(\minFreq, 60, \maxFr, 4000);
Ndef(\time).set(\amp, 0.4);
Ndef(\time).play;
Ndef(\time).end;




/*
// granular
SynthDef("jw_grain",
	{ arg out = 0, freq=800, sustain=0.1, amp=0.1, pan = 0;
		var window, env, u, nu;
		window = Env.sine(sustain);
		env = EnvGen.ar(window,  doneAction:2);
		amp = AmpCompA.ir(freq) * amp;
		u = SinOsc.ar(freq, 0, amp);
		OffsetOut.ar(out,
			Pan2.ar(u, pan)
		)
	}
).add;
/*****
(instrument: \jw_grain).play;
(instrument: \jw_grain, \freq: 2000, \decay: 0.1).play;
******/

(
OSCdef(\processingListener, { |msg|
	var vals = msg.drop(1).reverse;
	var diffs = ~longtimeAvgs - vals; // pos values for darkness
	var amps = diffs.max(0).linexp(0, 150, -36.dbamp, 1);
	// diffs.asInteger.postln;
	~longTermDiffs = diffs;
	amps.collect{|amp, i| if(amp>0.05){
		var freq = i.linexp(1, ~num, 10, 4000);
		(instrument: \jw_grain, \freq: freq, \sustain: 4/freq, amp: 0.1, lag: (1/20).rand).play;
	};
	};

}, '/drawingScore');
);
OSCdef(\processingListener).enable;
*/
