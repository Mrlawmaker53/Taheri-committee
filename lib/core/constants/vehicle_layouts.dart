// VEHICLE LAYOUTS FOR SEAT BOOKING SYSTEM

// LAND CRUISER — 11 passengers + 1 driver
// Canvas: 240 × 420 logical units (scaled at render time)
// RHD: steering wheel on right side

const Map<String, List<Map<String, dynamic>>> vehicleLayouts = {
  'cruiser': [
    // Row 1 — front (driver row)
    {'id':'DR',   'label':'Driver','type':'driver',    'x':148.0,'y':58.0, 'w':46.0,'h':38.0},
    {'id':'F-L1', 'label':'F-L1', 'type':'passenger', 'x':52.0, 'y':58.0, 'w':46.0,'h':38.0},
    {'id':'F-L2', 'label':'F-L2', 'type':'passenger', 'x':104.0,'y':58.0, 'w':46.0,'h':38.0},
    // Row 2 — middle (sliding door row, 3 across)
    {'id':'M-L1', 'label':'M-L1', 'type':'passenger', 'x':44.0, 'y':156.0,'w':46.0,'h':38.0},
    {'id':'M-C1', 'label':'M-C1', 'type':'passenger', 'x':96.0, 'y':156.0,'w':46.0,'h':38.0},
    {'id':'M-R1', 'label':'M-R1', 'type':'passenger', 'x':148.0,'y':156.0,'w':46.0,'h':38.0},
    // Rows 3-5 — rear left column
    {'id':'RL-1', 'label':'RL-1', 'type':'passenger', 'x':52.0, 'y':238.0,'w':46.0,'h':38.0},
    {'id':'RL-2', 'label':'RL-2', 'type':'passenger', 'x':52.0, 'y':286.0,'w':46.0,'h':38.0},
    {'id':'RL-3', 'label':'RL-3', 'type':'passenger', 'x':52.0, 'y':334.0,'w':46.0,'h':38.0},
    // Rows 3-5 — rear right column
    {'id':'RR-1', 'label':'RR-1', 'type':'passenger', 'x':144.0,'y':238.0,'w':46.0,'h':38.0},
    {'id':'RR-2', 'label':'RR-2', 'type':'passenger', 'x':144.0,'y':286.0,'w':46.0,'h':38.0},
    {'id':'RR-3', 'label':'RR-3', 'type':'passenger', 'x':144.0,'y':334.0,'w':46.0,'h':38.0},
  ],
  'eeco': [
    {'id':'DR',  'label':'Driver','type':'driver',    'x':88.0, 'y':30.0, 'w':42.0,'h':36.0},
    {'id':'F-1', 'label':'F-1',  'type':'passenger', 'x':32.0, 'y':30.0, 'w':42.0,'h':36.0},
    {'id':'M-1', 'label':'M-1',  'type':'passenger', 'x':32.0, 'y':90.0, 'w':42.0,'h':36.0},
    {'id':'M-2', 'label':'M-2',  'type':'passenger', 'x':88.0, 'y':90.0, 'w':42.0,'h':36.0},
    {'id':'R-1', 'label':'R-1',  'type':'passenger', 'x':14.0, 'y':150.0,'w':42.0,'h':36.0},
    {'id':'R-2', 'label':'R-2',  'type':'passenger', 'x':62.0, 'y':150.0,'w':42.0,'h':36.0},
    {'id':'R-3', 'label':'R-3',  'type':'passenger', 'x':110.0,'y':150.0,'w':42.0,'h':36.0},
  ],
};

const Map<String, int> vehicleCanvasWidth  = {'cruiser': 240, 'eeco': 160};
const Map<String, int> vehicleCanvasHeight = {'cruiser': 420, 'eeco': 260};
const Map<String, int> vehicleTotalSeats   = {'cruiser': 11,  'eeco': 6};
