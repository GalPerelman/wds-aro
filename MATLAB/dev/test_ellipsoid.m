clc
clear all
close all

addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;
disp('Solve inventory example with ROME')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rome_begin;
model = rome_model();
model.Solver = 'MOSEK';

s = 250;
n = 5;

x_lb = zeros(n);  % lower bounds of investment decisions
x_ub = ones(n);  % upper bounds of investment decisions

beta = 0.95;         % confidence interval
w0 = 1;              % investment budget
mu = 0.001;          % target minimum expected return rate


rho = 0.001;
eta = newvar(s, 'uncertain'); 
rome_constraint(norm2(eta) <= 1);
rome_constraint(sum(eta) == 0);
rome_constraint((1/s) + rho * eta >= 0);

pi = (1/s) + rho * eta;

x = newvar(n);
u = newvar(s);
alpha = newvar(1);

rome_minimize(alpha + 1/(1-beta) * (pi' * u));
rome_constraint(u >= y * x - alpha);
rome_constraint(u >= 0);
rome_constraint(pi * y * x >= mu);
rome_constraint(x >= x_lb);
rome_constraint(x <= x_ub);
rome_constraint(x.sum() == w0);

model.solve(grb)


