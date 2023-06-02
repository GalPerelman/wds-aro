clc
clear all
addpath(genpath('C:\Users\User\Documents\GitHub\YALMIP-master'));
addpath('C:\gurobi1001\win64\matlab')

T=24;
m=2;
v0 = 1000;
d0 = [131, 127, 128, 137, 188, 216, 242, 245, 213, 217, 237, 202, 212,...
      200, 185, 196, 212, 237, 283, 290, 236, 190, 185, 155]';

% c = [1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1]';

% Example Robusk Knapsack - https://xiongpengnus.github.io/rsome/example_ro_knapsack
N = 50;
b = 2000;
% r = 1;

c = 2*randi([5 10],N,1);
w = 2*randi([10 41],N,1);
delta = 0.2*w;

results=[];
xx = [];
for r=1:0.2:4
    x = sdpvar(N,1);
    z = sdpvar(N,1);
    constr = [];
    constr = [constr, ismember(x,[0 1])];
    constr = [constr, abs(z) <= 1];
    constr = [constr, norm(z, 1) <= r];
    constr = [constr, (w + z .* delta)' * x <= b];
    constr = [constr, uncertain(z)];
    
    obj = -1 * c' * x;
    
    options = sdpsettings('solver', 'gurobi', 'verbose', 0, 'debug', 1);
    optimize(constr ,obj, options);
    results = [results; -1*value(obj)];
    xx = [xx, value(x)];
end

plot(1:0.2:4, results,'-o')
grid()

% Obtain nominal solution
x = sdpvar(N,1);
constr = [];
constr = [constr, ismember(x,[0 1])];
constr = [constr, (w + delta)' * x <= b];
obj = -1 * c' * x;
options = sdpsettings('solver', 'gurobi', 'verbose', 0, 'debug', 1);
optimize(constr ,obj, options);
fprintf('Nominal solution: %.1f\n', -1*value(obj));


% F = [x+sum(w) <= 1];
% W = [norm(w) <= 1/sqrt(2), uncertain(w)];
% objective = -x
% sol = optimize(F + W,objective);