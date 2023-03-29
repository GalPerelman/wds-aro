clc

addpath('RSOME 1.2 release','C:\gurobi1001\win64\matlab')

data_folder = 'data\sopron';
sim = Simulation;
sim = sim.init(data_folder, 1, 24);

[obj, x_fsp, x_vsp, model] = lp(sim);

% Objective value
fprintf('Optimal objective value: %.1f', obj);

% Plot the volume trajectory for a tank
vol = sim.get_tank_vol(x_fsp, x_vsp, 4);
plot(vol);
grid();


