(
{
var dur = 1;
b = Buffer.alloc(s, dur*44100, 2);
s.sync;
y = { arg rate=1, bufnum, gate= 1;
    var in, p, l;
    in = SoundIn.ar;
	l = Line.ar(0, 10, 10);
	SendTrig.kr(1-gate, 0, l);
	Linen.kr(1-gate, 0, 0, 0, 2);
	p = l * SampleRate.ir;
//	p = Phasor.ar(0, BufRateScale.kr(bufnum) * rate, 666, BufFrames.kr(bufnum));
    BufWr.ar(in, 0, p);
    0.0 //quiet
	}.play(args: [bufnum: b.bufnum]);
	1.wait;
	y.release;

}.fork;

o = OSCdef(\whatever, { arg msg, time;
 //   [time, msg].postln;
	[msg[2], msg[3]].postln;
},'/tr', s.addr);

)



s.latency = nil

