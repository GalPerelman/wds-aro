clc
clear all


data_folder = 'data\pump-well';

sim = Simulation;
sim = sim.init(data_folder, 1, 24);

[obj, x] = lp(sim);

obj
vol = sim.get_tank_vol(x, 1);
flow = sim.get_fsp_flow(x, 'p1');
