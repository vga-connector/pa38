##########################################
# Autostart
##########################################

var autostart = func (msg=1) {
    if (getprop("/engines/engine/running")) {
        if (msg)
            gui.popupTip("Engine already running", 5);
        return;
    }

    # Filling fuel tanks
    setprop("/fdm/jsbsim/propulsion/tank[1]/collector-valve", 1);
    setprop("/fdm/jsbsim/propulsion/tank[2]/collector-valve", 1);
	

    # Setting levers and switches for startup
    setprop("/controls/switches/magnetos", 3);
	setprop("/controls/fuel/fuel-selector", 1);
    setprop("/controls/engines/engine/throttle", 0.2);
    setprop("/controls/engines/engine/mixture", 0.95);
    setprop("/controls/flight/elevator-trim", 0.2);
    setprop("/controls/switches/master-bat", 1);
    setprop("/controls/switches/master-alt", 1);
	setprop("/controls/engines/engine/primer", 3);

    # Setting lights
    setprop("/controls/lighting/nav-lights-switch", 1);
    setprop("/controls/lighting/strobe-switch", 1);

    # Setting flaps to 0
    setprop("/controls/flight/flaps", 0.0);

    # All set, starting engine
    setprop("controls/switches/starter", 1);
    setprop("/engines/engine/auto-start", 1);

    var engine_running_check_delay = 5.0;
    settimer(func {
        if (!getprop("/engines/engine/running")) {
            gui.popupTip("The autostart failed to start the engine. You must lean the mixture and start the engine manually.", 5);
        }
        setprop("controls/switches/starter", 0);
        setprop("/engines/engine/auto-start", 0);
    }, engine_running_check_delay);
};

var update_pax = func {
    var state = 0;
    state = bits.switch(state, 0, getprop("pax/pilot/present"));
    state = bits.switch(state, 1, getprop("pax/co-pilot/present"));
    setprop("/payload/pax-state", state);
};


#Transponder ident light
var ident_status = maketimer(10.0, func {
    setprop("/instrumentation/transponder/ident_status", 1);
});
ident_status.start();

var ident_light_timer = maketimer(0.1, func {
    var light_intensity = getprop("/instrumentation/transponder/ident_light");
    var light_status = getprop("/instrumentation/transponder/ident_light_status");
    var actual_ident = getprop("/instrumentation/transponder/ident_status");

    if ( (light_intensity < 1) and (light_status == 0) and (actual_ident == 1) ) {
       setprop("/instrumentation/transponder/ident_light", light_intensity + 0.1);
       if ( light_intensity > 0.89 ) {
           setprop("/instrumentation/transponder/ident_light_status", 1);
           setprop("/instrumentation/transponder/ident_light", 1);
       }
    }
    else {
       setprop("/instrumentation/transponder/ident_light", light_intensity - 0.1);
       if ( light_intensity < 0.11 ) {
           setprop("/instrumentation/transponder/ident_light_status", 0);
           setprop("/instrumentation/transponder/ident_light", 0);
           setprop("/instrumentation/transponder/ident_status", 0);
       }
    }
});
ident_light_timer.start();

##########################################
# Click Sounds
##########################################

var click = func (name, timeout=0.1, delay=0) {
    var sound_prop = "/sim/model/pa38/sound/click-" ~ name;

    settimer(func {
        # Play the sound
        setprop(sound_prop, 1);

        # Reset the property after 0.2 seconds so that the sound can be
        # played again.
        settimer(func {
            setprop(sound_prop, 0);
        }, timeout);
    }, delay);
};


# ADF freequencies
var originalfreq  = getprop("/instrumentation/adf/frequencies/selected-khz");
setprop("/instrumentation/adf/frequencies/digit100-khz", ( originalfreq - math.mod(originalfreq, 100))/100);
setprop("/instrumentation/adf/frequencies/digit10-khz", (( originalfreq - (originalfreq - math.mod(originalfreq, 100)) - math.mod(originalfreq, 10))/10) );
setprop("/instrumentation/adf/frequencies/digit1-khz", ( math.mod(originalfreq, 10)) );

setlistener("/instrumentation/adf/frequencies/digit100-khz", func (node) {
    var digit100 = getprop("/instrumentation/adf/frequencies/digit100-khz");
    var actualfreq = getprop("/instrumentation/adf/frequencies/selected-khz");
    setprop("/instrumentation/adf/frequencies/selected-khz", (digit100 * 100) + math.mod(actualfreq, 100) );
});

setlistener("/instrumentation/adf/frequencies/digit10-khz", func (node) {
    var digit10 = getprop("/instrumentation/adf/frequencies/digit10-khz");
    var actualfreq = getprop("/instrumentation/adf/frequencies/selected-khz");
    setprop("/instrumentation/adf/frequencies/selected-khz", actualfreq - math.mod(actualfreq, 100)  + (digit10 * 10) + math.mod(actualfreq, 10) );
});


setlistener("/instrumentation/adf/frequencies/digit1-khz", func (node) {
    var digit1 = getprop("/instrumentation/adf/frequencies/digit1-khz");
    var actualfreq = getprop("/instrumentation/adf/frequencies/selected-khz");
    setprop("/instrumentation/adf/frequencies/selected-khz", actualfreq - math.mod(actualfreq, 10) + digit1);
});

setlistener("/instrumentation/adf/actual-mode", func (node) {
    if ( getprop("/instrumentation/adf/actual-mode") == 0 ) {
        setprop("/instrumentation/adf/mode", "adf");
    } else {
    if ( getprop("/instrumentation/adf/actual-mode") == 1 ) {
        setprop("/instrumentation/adf/mode", "ant");
    } else {
    if ( getprop("/instrumentation/adf/actual-mode") == 2 ) {
        setprop("/instrumentation/adf/mode", "bfo");
    }
    }
    }
});

#Adjust comm frequencies
var originalcommfreq  = getprop("/instrumentation/comm[0]/frequencies/selected-mhz");
setprop("/instrumentation/comm[0]/frequencies/enteros-mhz", originalcommfreq - math.mod(originalcommfreq, 1) );
#setprop("/instrumentation/comm[0]/frequencies/decimales-mhz", math.mod(originalcommfreq, 1) );
#var decimales = getprop("/instrumentation/comm[0]/frequencies/decimales-mhz");
var decimales = math.mod(originalcommfreq, 1);
#setprop("/instrumentation/comm[0]/frequencies/decimal1-mhz", decimales - math.mod(decimales, 0.1) );
setprop("/instrumentation/comm[0]/frequencies/decimal1-mhz", decimales );
setprop("/instrumentation/comm[0]/frequencies/decimal2y3-mhz", math.mod(decimales, 0.1) );

setlistener("/instrumentation/comm[0]/frequencies/enteros-mhz", func (node) {
	var enteros = getprop("/instrumentation/comm[0]/frequencies/enteros-mhz");	
#	var decimales = getprop("/instrumentation/comm[0]/frequencies/decimales-mhz");	
	var decimal1 =  getprop("/instrumentation/comm[0]/frequencies/decimal1-mhz");
	var decimal2y3 = getprop("/instrumentation/comm[0]/frequencies/decimal2y3-mhz");
	setprop("/instrumentation/comm[0]/frequencies/decimales-mhz", decimal1 + decimal2y3 );
	setprop("/instrumentation/comm[0]/frequencies/selected-mhz", enteros + decimal1 + decimal2y3 );
});

setlistener("/instrumentation/comm[0]/frequencies/decimal1-mhz", func (node) {
	var enteros = getprop("/instrumentation/comm[0]/frequencies/enteros-mhz");	
#	var decimales = getprop("/instrumentation/comm[0]/frequencies/decimales-mhz");	
	var decimal1 =  getprop("/instrumentation/comm[0]/frequencies/decimal1-mhz");
	var decimal2y3 = getprop("/instrumentation/comm[0]/frequencies/decimal2y3-mhz");
	setprop("/instrumentation/comm[0]/frequencies/decimales-mhz", decimal1 + decimal2y3 );
	setprop("/instrumentation/comm[0]/frequencies/selected-mhz", enteros + decimal1 + decimal2y3 );
});

setlistener("/instrumentation/comm[0]/frequencies/decimal2y3-mhz", func (node) {
	var enteros = getprop("/instrumentation/comm[0]/frequencies/enteros-mhz");	
#	var decimales = getprop("/instrumentation/comm[0]/frequencies/decimales-mhz");	
	var decimal1 =  getprop("/instrumentation/comm[0]/frequencies/decimal1-mhz");
	var decimal2y3 = getprop("/instrumentation/comm[0]/frequencies/decimal2y3-mhz");
	setprop("/instrumentation/comm[0]/frequencies/decimales-mhz", decimal1 + decimal2y3 );
	setprop("/instrumentation/comm[0]/frequencies/selected-mhz", enteros + decimal1 + decimal2y3 );
});

setlistener("/pax/pilot/present", update_pax, 0, 0);
setlistener("/pax/co-pilot/present", update_pax, 0, 0);
update_pax();

setlistener("/engines/engine/running", func (node) {
	var autostart = getprop("/engines/engine/auto-start");
	var cranking  = getprop("/engines/engine/cranking");
	if (autostart and cranking and node.getBoolValue()) {
		setprop("/controls/engines/engine/starter", 0);
        setprop("/engines/engine/auto-start", 0);
    }
}, 0, 0);