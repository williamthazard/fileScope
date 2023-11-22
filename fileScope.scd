//fileScope

o = Server.default.options;
o.memSize_(2.pow(20));
o.outDevice_("External Headphones");
~bf = Buffer.alloc(Server.default,4096,2);
~fb = Bus.audio(Server.default,2);
Window.closeAll;
w = Window("lissajous",Window.availableBounds)
.background_(Color.black)
.fullScreen
.onClose_({~topScope.stop; ~bf.free; ~fb.free});
~color_vals = Array.fill(3,{Array.fill(3,{rrand(0,255)})});
~topScope = ScopeView(w,
	Rect(0,
		0,
		w.view.bounds.width,
		w.view.bounds.height
	)
)
.bufnum_(~bf.bufnum)
.server_(Server.default)
.style_(2)
.xZoom_(24)
.yZoom_(24)
.waveColors_(
	[
		Color.new255(
			~color_vals[0][0],
			~color_vals[1][0],
			~color_vals[2][0]
		),
		Color.new255(
			~color_vals[0][1],
			~color_vals[1][1],
			~color_vals[2][1]
		)
	]
)
.background_(Color.black)
.start;

Task({
	var delta = 128/61440;
	loop {
		3.do({
			arg i;
			3.do({
				arg j;
				if(
					~color_vals[i][j] == 255,
					{
						~color_vals[i][j] = ~color_vals[i][j]-[0,1].choose
					}
				);
				if(
					~color_vals[i][j] == 0,
					{
						~color_vals[i][j] = ~color_vals[i][j]+[0,1].choose
					}
				);
				if(
					(~color_vals[i][j] < 255) && (~color_vals[i][j] > 0),
					{
						~color_vals[i][j] = ~color_vals[i][j]+[0,1,-1].wchoose([0.5,0.25,0.25])
					}
				);
			});
		});
		~topScope.waveColors_(
			[
				Color.new255(
					~color_vals[0][0],
					~color_vals[1][0],
					~color_vals[2][0]
				),
				Color.new255(
					~color_vals[0][1],
					~color_vals[1][1],
					~color_vals[2][1]
				)
			]
		);
		delta.yield;
	}
},AppClock
).play;

~af = SynthDef("duoscope", { arg bus, bufnum;
	var z;
	z = In.ar(bus, 2);
	ScopeOut2.ar(z, bufnum);
	Out.ar(0, z);
}).play(
	target: RootNode(Server.default),
	args: [\bus, ~fb.index, \bufnum, ~bf.bufnum],
	addAction: \addToTail
);

p = "/Users/spencerkingmangraham/Desktop/audio/albums/Félicia Atkinson - Richard Chartier - Ni envers ni endroit que cette roche brûlante (Pour Georgia O’Keeffe) - Recurrence.Expansion/Félicia Atkinson - Ni envers ni endroit que cette roche brûlante (Pour Georgia O’Keeffe) - R - 01 'Ni envers ni endroit que cette roche brûlante (Pour Georgia O’Keeffe)'.wav";
b = Buffer.readChannel(s, p, channels: [0]);
c = Buffer.readChannel(s, p, channels: [1]);

Task({
 	SynthDef(\PlayBufPlayer, {
 		arg out=0,
 		bufnum=0,
 		rate=1,
 		start=0,
 		end=1,
 		t_trig=0,
 		loops=1,
 		amp=0.2,
 		pan=0,
 		rateSlew=0.1,
 		panSlew=1,
 		bus=~fb.index;
 		var snd,
 		snd2,
 		pos,
 		pos2,
 		frames,
 		duration,
 		env,
 		sig,
 		startA,
 		endA,
 		startB,
 		endB,
 		crossfade,
 		aOrB;
 		aOrB=ToggleFF.kr(t_trig);
 		startA=Latch.kr(start,aOrB);
 		endA=Latch.kr(end,aOrB);
 		startB=Latch.kr(start,1-aOrB);
 		endB=Latch.kr(end,1-aOrB);
 		crossfade=Lag.ar(K2A.ar(aOrB),0.1);
 		rate=Lag.kr(rate,rateSlew)*BufRateScale.kr(bufnum);
 		frames=BufFrames.kr(bufnum);
 		duration=frames*(end-start)/rate.abs/s.sampleRate*loops;
 		env=EnvGen.ar(
 			Env.new(
 				levels: [0,amp,amp,0],
 				times: [0,duration-0.1,0.1],
 			),
 			gate:t_trig,
 		);
 		pos=Phasor.ar(
 			trig:aOrB,
 			rate:rate,
 			start:(((rate>0)*startA)+((rate<0)*endA))*frames,
 			end:(((rate>0)*endA)+((rate<0)*startA))*frames,
 			resetPos:(((rate>0)*startA)+((rate<0)*endA))*frames,
 		);
 		snd=BufRd.ar(
 			numChannels:1,
 			bufnum:bufnum,
 			phase:pos,
 			interpolation:4,
 		);
 		pos2=Phasor.ar(
 			trig:(1-aOrB),
 			rate:rate,
 			start:(((rate>0)*startB)+((rate<0)*endB))*frames,
 			end:(((rate>0)*endB)+((rate<0)*startB))*frames,
 			resetPos:(((rate>0)*startB)+((rate<0)*endB))*frames,
 		);
 		snd2=BufRd.ar(
 			numChannels:1,
 			bufnum:bufnum,
 			phase:pos2,
 			interpolation:4,
 		);
 		sig=Pan2.ar(
 			MoogFF.ar(
 				in:(crossfade*snd)+((1-crossfade)*snd2)*env,
 				freq:\cutoff.kr(12000),
 			gain:\resonance.kr(1)),
 			pan
 		);
 		Out.ar(bus,sig)
 	}).play(s,[\out,0]);
 	s.sync;
	Synth(\PlayBufPlayer,[\bufnum,b,\t_trig,1,\bus,~fb.index,\pan,-1]);
	Synth(\PlayBufPlayer,[\bufnum,c,\t_trig,1,\bus,~fb.index,\pan,1]);
}).play
