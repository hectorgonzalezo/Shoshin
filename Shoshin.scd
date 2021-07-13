(
Window.closeAll;

s.freeAll;

s.waitForBoot({
	s.latency=0.1;



	{Limiter.ar(SoundIn.ar(0)!2*0.6, 0.8)}.play;
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////SYNTHDEFS
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////

	SynthDef(\stereobufShift,
		{
			|out=0, buf = 0, rate=1, trig=1, pos=0, loop=1, amp=1, atk=4, rel =3, pan=0, gate=1, vol=1, trigTime=0|
			var sig, env, loopEnv;

			env = EnvGen.kr(Env.dadsr(3, atk,0.05, 1,rel),gate, doneAction:2);
			sig= PlayBuf.ar(
				2,
				buf,
				BufRateScale.ir(buf) * rate,
				trig*Pulse.kr(trigTime.reciprocal),
				BufFrames.kr(buf)*pos,
				loop
			);
			sig = Limiter.ar(sig, 0.9);
			loopEnv = EnvGen.kr(
				Env([0.2,1,1,0.2], [0.2,trigTime-0.4, 0.2]),
				LFPulse.kr(trigTime.reciprocal,0,0.999));
			Out.ar(out,Splay.ar(sig*amp*env*loopEnv,1,1,pan));
		}
	).add;




	SynthDef(\recorder, { arg out = 0, buf, run = 1, in, pan=0, vol=1, gate=1;
		var input, env;
		env = EnvGen.kr(Env.asr(releaseTime:0.01),gate);
		input = Limiter.ar(SoundIn.ar(0)!2, 0.9);
		RecordBuf.ar(input*vol*env, buf, recLevel: vol, run:run, loop:0, doneAction:2);
	}).add;



	SynthDef(\pShift,{
		|gate=1, grainSize= 0.2, ratio =1, pitchDisp =0, timeDisp=0, atk=0.1, rel=0.1, panRand= 0, pan=0, vol=1|
		var env, sig, panCtrl;

		env = EnvGen.kr(Env.asr(atk,1,rel),gate, doneAction:2);

		panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

		sig = PitchShift.ar(
			Limiter.ar(SoundIn.ar(0), 0.9),
			grainSize,
			ratio,
			pitchDisp,
			timeDisp
		);

		sig = Splay.ar(sig*env,1,vol,panCtrl);

		Out.ar(0,sig);
	}
	).add;


	SynthDef(\del,
		{
			|out=0, atk=0.1, rel=0.5, gate=1, randFreq=0, randRange=1, vol=1, center=0|
			var sig, env, random, in;

			env = EnvGen.kr(Env.asr(atk,1,rel),gate, doneAction:2);

			random = LFNoise1.kr(
				LFNoise0.kr(randFreq).range(0.5,3)
			).range(randRange,randRange.reciprocal)!8;

			in = Limiter.ar(SoundIn.ar(0), 0.8);

			sig =CombC.ar(
				in,
				0.2,
				(Array.rand(4,0.01,0.2).sort)*random,
				Array.rand(4,0.5,2).sort.reverse,
				4.reciprocal
			).poll;

			sig = LPF.ar(sig, 5000);

			sig = Splay.ar(sig*env, SinOsc.kr(1).range(0,1), vol, center);

			Out.ar(out,sig);
		}
	).add;








	~shaperBuf0 = Buffer.alloc(s, 512, 1, { |buf| buf.chebyMsg(Array.fill(rrand(5,12),{rrand(0.15, 1.0)}))});

	SynthDef(\shaper,{
		|buf, out=0, vol=1, gate=1, pos = 0, atk=0.5, amp=1, releaseTime=1, width=2, noismul=1, distAmp=0.8, cutFreq=10000, mix=0|
		var source, sig, env;
		source = SoundIn.ar(0);
		sig = LPF.ar(Shaper.ar(buf,(source*distAmp).abs),cutFreq);
		sig = Limiter.ar(sig,0.9);
		env = EnvGen.kr(Env.asr(atk,1,releaseTime,1), gate,doneAction:2);
		sig = FreeVerb.ar(sig,mix);
		sig = PanAz.ar(
			2,
			sig,
			pos,
			1,
			width
		);

		Out.ar(0,sig*env*vol*amp);
	};
	).add;







	SynthDef(\grey, {
		arg in, out= 0, vol = 0.7, time=1, damp=0, size=1, sizech=0, diff = 0.707, fback =0.3, fbch=0, modDepth=0.1, modFreq=2, atk= 0.02, sus =2, releaseTime = 1, crv = -1, gate=1, pos=0, spafr=0, width=2;
		var source, sig, env;
		env = EnvGen.kr(Env.asr(atk,sus,releaseTime,crv),gate, doneAction:2);
		source = SoundIn.ar(0);
		sig = Greyhole.ar(
			source,
			time.lag2(1),
			damp.lag2(0.5),
			size.lag2(1) + LFNoise0.kr(sizech),
			diff.lag2(0.5),
			fback.lag2(1),
			LFNoise1.kr(fbch),
			modDepth,
			modFreq);

		sig = Limiter.ar(sig, 0.9);
		sig = PanAz.ar(
			2,
			sig,
			pos,
			1,
			width
		);
		Out.ar(out, sig*env*vol.lag2(0.5)*0.3);
	}).add;


	s.sync;


	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////GUI
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////




	~x = 600;
	~y = 350;
	~gui = Window.new(
		"Shoshin",
		Rect(
			0,
			(Window.screenBounds.height/2)-(~y/2),//20,
			~x,~y))
	.front
	.alwaysOnTop_(false)
	.background_(Color.grey(0.8));



	~title = StaticText(~gui, Rect(175,15,250,75))
	.string_("Shoshin")
	.stringColor_(Color.black)
	.font_(Font("Sakkal Majalla",65, false, false))
	.align_(\center);





	~loopText = [
		StaticText(~gui, Rect(15,100,1000,75))
	.string_("A# loop unactive")
	.stringColor_(Color.blue)
	.font_(Font("Sakkal Majalla",30, false, false))
	.align_(\left),
		StaticText(~gui, Rect(15,225,1000,75))
	.string_("B loop unactive")
	.stringColor_(Color.blue)
	.font_(Font("Sakkal Majalla",30, false, false))
		.align_(\left)];




	~meter = ServerMeterView(s,~gui,350@100, 2, 2).start;




	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////start MIDI
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////

	MIDIClient.init;

	MIDIIn.connectAll;

	MIDIClient.sources;



	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////Groups
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////



	~ewiGrp = Group.new;
	~ewiFxGrp = Group(~ewiGrp, \addAfter);


	~loopGrp = Array.fill(2,{Group.new(~ewiFxGrp, \addBefore);});







	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////BUFFERS AND INITIAL VALUES
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////






	~buffers = Array.fill(2,{Buffer.alloc(s, 48000 * 10.0, 2);});


	~improLoopDur= Array.fill(2,{0});

	~improLoop= Array.fill(2,{nil});



	~gate=0;
	~vol =1;



	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////FUNCTION FOR PITCH SHIFTING	//////////////////////////////////////////////////////////////////////////////////////////////////////////////




	~pitchFunc ={

		arg pitches;

		MIDIdef.noteOff(\EWIoff,
			{
				"EWIOFF".postln;
				if(a[1].isPlaying,
					{a.do({|n| n.set(\gate, 0)});}
				);
				~gate=0;

				MIDIdef.cc(\downBend).free;
				MIDIdef.cc(\upBend).free;
				MIDIdef.cc(\bite).free;
				MIDIdef.cc(\breath).free;
			}
		);



		MIDIdef.cc(\downBend).free;
		MIDIdef.cc(\upBend).free;
		MIDIdef.cc(\bite).free;
		MIDIdef.cc(\breath).free;


		~ewiGrp.deepFree;

		if(~gate==0,{

			a = pitches.collect{
				arg n, i;
				Synth(\pShift,
					[\ratio, n.midiratio,
						\rel, 0.1,
						\grainSize, 0.2,
						\pitchDisp, 0,
						\timeDisp, 0.1,
						\panRand, 0,
						\vol, i.linlin(0,2,1,0.4)/pitches.size
					],
					~ewiGrp
				);
			};

			pitches.postln;
			NodeWatcher.register(a[0]);

			~gate=1;
		},
		{nil}
		);




		MIDIdef.cc(\breath,
			{
				|val, nn|

				if(a[0].isPlaying,{

					~vol =  val.linlin(0,127,0,1);
					a.do({|n| n.set(\vol, val.linlin(0,127,0,3/pitches.size))});


					if(val ==0, {
						a.do({|n| n.set(\gate, 0)});


					});

				};
				)
			},9
		);




		MIDIdef.cc(\downBend, {
			|val|


			a.do({|n| n.set(\timeDisp, val.linlin(0,127,0,1))});

		},1);


		MIDIdef.cc(\upBend,{
			|val|


			a.do({|n| n.set(\panRand, val.linlin(0,127,0,1))});
		}, 64
		);



		MIDIdef.cc(\bite, {
			|val|


			a.do({|n| n.set(\pitchDisp, val.linlin(0,127,0,1))});
		},8);
	};





	~loopFunc = {
		|i, num, amp=0.3|


		if(~improLoop[num].isPlaying,
						{

							MIDIdef.cc(\breath).free;
							MIDIdef.cc(\bite).free;
							MIDIdef.cc(\upBend).free;
							MIDIdef.cc(\downBend).free;


				~loopGrp[num].set(\gate,0);
				"se calla".postln;


				{~loopText[num].string_(i.midinote[0].asString ++ i.midinote[1].asString ++" loop unactive").stringColor_(Color.blue);}.defer;
						},


						{

					~buffers[num].free;
				~buffers[num] = Buffer.alloc(s, 48000 * 10.0, 2);


							b = Synth(\recorder,[
								\buf, ~buffers[num]
							],
							~loopGrp[num],
							\addToTail
							);
					~improLoopDur[num]=0;

							Tdef(\counter,{
								inf.do{
									0.01.wait;
									~improLoopDur[num]=~improLoopDur[num]+0.01;
									~improLoopDur[num].postln;
								}
							}
				).play(quant:0);


				{~loopText[num].string_(i.midinote[0].asString ++ i.midinote[1].asString ++" loop recording").stringColor_(Color.red)}.defer;


							MIDIdef.cc(\breath,
								{
									|val, nn|



									if(val==0,
										{
											Tdef(\counter).stop;
											"llega a 0".postln;
											b.set(\gate, 0);



										if(~improLoop[num].isPlaying,
												{nil},
												{

													~improLoop[num]= Synth(\stereobufShift,[
													\buf, ~buffers[num],
														\loop, 1,
														\amp, amp,
														\out, 0,
													\trigTime, ~improLoopDur[num];
													],
													~loopGrp[num]);

													NodeWatcher.register(~improLoop[num]);
											});



											MIDIdef.cc(\bite).free;




									{~loopText[num].string_(i.midinote[0].asString ++ i.midinote[1].asString ++" loop active").stringColor_(Color.green(0.5));}.defer;




										}
									);


								},9
							);
						}
					)
			};



	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////MAIN EWI PATCH
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////




	MIDIdef.noteOn(\EWI,
		{
			|val, nn|


			switch(nn%12,

				0, {~pitchFunc.value([0, [-1, 11].wchoose([0.7,0.3]), [-3, 9].wchoose([0.7,0.3])])},   //Eb D C   (C)

				1, {~pitchFunc.value([0, [-2, 10].wchoose([0.7,0.3]), [-4, 8].wchoose([0.7,0.3])])},   //E D C    (C#)

				2, {~pitchFunc.value([0, [-3, 9].wchoose([0.7,0.3]), [-5, 7].wchoose([0.7,0.3])])},   //F D C    (D)

				3, {~pitchFunc.value([0, [-4, 8].wchoose([0.7,0.3]), [-5, 7].wchoose([0.7,0.3])])},   //F Db C   (D#)

				4, {~pitchFunc.value([0, [-1, 11].wchoose([0.7,0.3]), [-5, 7].wchoose([0.7,0.3])])},   //F E C    (E)

				5, {~pitchFunc.value([0, -7, 5])},   // (F)
				6, {~pitchFunc.value([0, -6, 6])},   // (F#)




				//distortion (G)
				7, {

					MIDIdef.noteOff(\EWIoff,
						{

							"EWIOFF".postln;
							if(a.isPlaying,{a.set(\gate, 0)});
							~gate=0;

							MIDIdef.cc(\downBend).free;
							MIDIdef.cc(\upBend).free;
							MIDIdef.cc(\bite).free;
							MIDIdef.cc(\breath).free;
						}
					);



					MIDIdef.cc(\downBend).free;
					MIDIdef.cc(\upBend).free;
					MIDIdef.cc(\bite).free;
					MIDIdef.cc(\breath).free;


					~ewiGrp.deepFree;

					if(~gate==0,{

						a = Synth(\shaper, [\buf, ~shaperBuf0]);
						"distortion on".postln;

						NodeWatcher.register(a);

						~gate=1;
					},
					{nil}
					);




					MIDIdef.cc(\breath,
						{
							|val, nn|

							if(a.isPlaying,{

								~vol =  val.linlin(0,127,0,0.7);
								a.set(\vol, val.linlin(0,127,0,0.7));


								if(val ==0, {
									a.set(\gate, 0);


								});

							};
							)
						},9
					);




					MIDIdef.cc(\downBend, {
						|val|


						a.set(\cutFreq, val.linexp(0,127,10000,1000));

					},1);


					MIDIdef.cc(\upBend,{
						|val|


						a.set(\mix, val.linlin(0,127,0.0,1));
					}, 64
					);



					MIDIdef.cc(\bite, {
						|val|


						a.set(
							\distAmp, val.linlin(0, 127, 0.8, 8),
							\amp, val.linlin(0, 127, 1, 0.2));

					},8);

				},



				//Greyhole  (G#)

				8, {

					MIDIdef.noteOff(\EWIoff,
						{

							"EWIOFF".postln;
							if(a.isPlaying,{a.set(\gate, 0)});
							~gate=0;

							MIDIdef.cc(\downBend).free;
							MIDIdef.cc(\upBend).free;
							MIDIdef.cc(\bite).free;
							MIDIdef.cc(\breath).free;
						}
					);



					MIDIdef.cc(\downBend).free;
					MIDIdef.cc(\upBend).free;
					MIDIdef.cc(\bite).free;
					MIDIdef.cc(\breath).free;


					~ewiGrp.deepFree;

					if(~gate==0,{

						a = Synth(\grey,[\vol,0]);

						NodeWatcher.register(a);

						~gate=1;

						"grey on".postln;
					},
					{nil}
					);




					MIDIdef.cc(\breath,
						{
							|val, nn|

							if(a.isPlaying,{

								~vol =  val.linlin(0,127,0,1.5);
								a.set(\vol, val.linlin(0,127,0,1.5));


								if(val ==0, {
									a.set(\gate, 0);


								});

							};
							)
						},9
					);




					MIDIdef.cc(\downBend, {
						|val|

						a.set(\diff, val.linlin(0,127, 0.707, 0.1),
							\sizech, val.linlin(0, 127, 0, 5));

					},1);


					MIDIdef.cc(\upBend,{
						|val|


						a.set(\time, val.linlin(0,127,1,6));

					}, 64
					);



					MIDIdef.cc(\bite, {
						|val|


						a.set(\fback, val.linlin(0,127,0.3,1.4));
					},8);

				},





				//(A)

				9,{

					MIDIdef.noteOff(\EWIoff,
						{

							"EWIOFF".postln;
							if(a.isPlaying,{a.set(\gate, 0)});
							~gate=0;

							MIDIdef.cc(\downBend).free;
							MIDIdef.cc(\upBend).free;
							MIDIdef.cc(\bite).free;
							MIDIdef.cc(\breath).free;
						}
					);



					MIDIdef.cc(\downBend).free;
					MIDIdef.cc(\upBend).free;
					MIDIdef.cc(\bite).free;
					MIDIdef.cc(\breath).free;


					~ewiGrp.deepFree;

					if(~gate==0,{

						a = Synth(\del, [\vol, 0]);

						NodeWatcher.register(a);

						~gate=1;
					},
					{nil}
					);




					MIDIdef.cc(\breath,
						{
							|val, nn|

							if(a.isPlaying,{

								~vol =  val.linlin(0,127,0,2.5);
								a.set(\vol, val.linlin(0,127,0,2.5));


								if(val ==0, {
									a.set(\gate, 0);


								});

							};
							)
						},9
					);




					MIDIdef.cc(\downBend, {
						|val|


						a.set(\center, val.linlin(0,127,0,-1));

					},1);


					MIDIdef.cc(\upBend,{
						|val|


						a.set(\center, val.linlin(0,127,0,0.9));
					}, 64
					);



					MIDIdef.cc(\bite, {
						|val|

						a.set(
							\randFreq, val.linlin(0,127,0, 3),
							\randRange, val.linlin(0,127,1,0.75));
					},8);

				},



				//LOOPERS
				//(Bb)
				10, {
							~loopFunc.value(nn%10, nn%10, 0.055);

				},

				11, {
							~loopFunc.value(nn%10, nn%10, 0.55);

				}



			)

		}
	);
}
);



)


s.record;
s.stopRecording;