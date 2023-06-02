clc
clear all
% https://groups.google.com/g/yalmip/c/WoQDFI_L7C8/m/H8H21CFvsgMJ

T = 24;
t = 1:1:24;
d0 = 1000 * (1 + 0.5*sin(pi*(t-1)/12))';
alpha = [1;1.5;2];
c = alpha * (1 + 0.5*sin(pi*(t-1)/12));

P = 567;
Q = 13600;
vmin = 500;
vmax = 2000;
v = 500;
theta = 0.20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tau = sdpvar;
x = sdpvar(T,1);
d = sdpvar(T,1);
constr = [(1-theta)*d0 <= d <= (1+theta)*d0, uncertain(d)];

for t=2:T
    yalmip('setdependence',x(t), d(1:t-1));
end

constr = [constr, x >= 0];
constr = [constr, x <= 1800];
for t=1:T
    constr = [constr, v + sum(x(1:t)) - sum(d(1:t)) >= vmin];
    constr = [constr, v + sum(x(1:t)) - sum(d(1:t)) <= vmax];
end
constr = [constr, sum(x(1:T)) - sum(d(1:T)) >= 0];
constr = [constr, c(2,1:T) * x <= tau];

objective = tau;

ops = sdpsettings('robust.auxred','affine', 'verbose', 0, 'debug', 1);
diagnostics = solvesdp(constr, objective, ops);
value(objective)
xx = value(x);
diagnostics.problem

methods(x)
getvariables(x)
%%%
% [constr,obj] = robustify(constr,objective,ops);
% obj
% ops = sdpsettings('verbose', 0, 'debug', 1);
% constr = [constr, d==d0];
% solvesdp(constr,obj,ops);
% value(obj)


