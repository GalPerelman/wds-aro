clc

addpath('packages/RSOME 1.2 release','C:\gurobi1001\win64\matlab')

data_folder = 'data\sopron';
sim = Simulation;
sim = sim.init(data_folder, 1, 24);

[obj, x_fsp, x_vsp, model] = lp(sim);

% Objective value
fprintf('Optimal LP objective value: %.1f\n', obj);

% Plot the volume trajectory for a tank
vol = sim.get_tank_vol(x_fsp, x_vsp, 1);
plot(vol);
grid();

% Robust optimization
[obj, x_fsp, x_vsp, model] = ro(sim, 2, 1, 0.1);
fprintf('Optimal TO objective value: %.1f\n', obj);
