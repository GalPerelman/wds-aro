clc
clear all
close all

addpath('ROME_1.0.9\',...
        'ROME_1.0.9\utilityfuncs\',...
        'C:\Program Files\Mosek\10.0\toolbox\r2017a')

import ROME_1.0.9.*;
disp('Solve inventory example with ROME')

% Inventory setup parameters
T = 10;                     % Number of periods 
xMax = 260;                 % Maximum ordering level
c = 0.1*ones(T,1);          % Ordering costs
h = 0.02*ones(T,1);         % Holding costs
b = [0.2*ones(T-1,1); 2];   % Shortage costs

% Demand information
mu = 200;       % mean 
alpha = 0.5;    % degree of demand correlation
zRange = mu/T;
zSample = -zRange:zRange/20:zRange;           
zDist   = ones(length(zSample),1)/length(zSample);
% Determine deviation information using divmeasure function
[zMean, zStd, zFDev, zBDev,zMin,zMax] =  divmeasure(zSample,zDist);

% begin rome
rome_h = rome_begin;   
rome_h.Solver = 'MOSEK';

% Define uncertain factors
newvar z(T) uncertain;
z.set_mean(0);
% rome_constraint(norm2(z) <= 20);
rome_box(z, zMin, zMax);

z.Covar = zStd^2;  % Covariance is diagonal with values equal to variance
z.FDev = zFDev;
z.BDev = zBDev;

% Demand relations with uncertain factors
d = mu + alpha*z(1);
for t = 2:T
    d(t) = d(t-1) - (1-alpha)*z(t-1) + z(t);
end

% Model variables
% Ordering levels
pX = logical([tril(ones(T)), zeros(T, 1)]); % Dependency patter of x on z. 
newvar x(T, z, 'Pattern', pX) linearrule;

% Inventory level
newvar y(T+1,z) linearrule;   % Note that dependency of y is enforced in
                              % inventory balance equation
% Objective
rome_minimize(c'*mean(x) + h'*mean(pos(y(2:T+1))) + b'*mean(neg(y(2:T+1))));

% Constraints
rome_constraint(y(1)==0);  % Initial inventory level
for t = 1:T
    rome_constraint(y(t+1)==y(t) + x(t) - d(t));
end

% order quantity constraint
rome_box(x, 0, xMax);

% solve
rome_h.solve;
obj_val = rome_h.objective;
x_val   = rome_h.eval(x);
y_val = rome_h.eval(y);
rome_end;

disp(obj_val);
x_val;

sz = size(x_val.LDRAffineMap,2) - 1;
z = randn(sz,1);

a = [];

for jj=1:1000
    r = normrnd(0,5,sz,1);
    x = x_val.insert(r);
    x = reshape(x, x_val.Size(1), []);
    y = y_val.insert(z);
    y = reshape(y, y_val.Size(1), []);
    
    f=sum(c'*mean(x') + h'*mean(pos(y(2:T+1)')) + b'*mean(neg(y(2:T+1)')));
    a=[a;f];
end
histogram(a)



