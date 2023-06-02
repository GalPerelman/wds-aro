clc
clear all


% parameters:
n = 150;                                % number of stocks
i = 1:1:n;                              % indices of stocks
p = 1.15 + i*0.05/150;                  % mean returns
delta = 0.05/450.*(2*i*n*(n+1)).^0.5;   % deviations of returns
Gamma = 5;                              % budget of uncertainty

model = rsome;
model.Param.solver = 'gurobi';
x = model.decision(n);
z = model.random(n);

u = model.ambiguity;
u.suppset(norm(z, Inf) <= 1, norm(z, 1) <= Gamma);
model.with(u);

model.max((p'+delta'.*z)' * x);
model.append(sum(x) <= 1);
model.append(x >= 0);

model.solve();

model.get();
x = x.get()