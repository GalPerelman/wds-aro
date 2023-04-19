function [obj_val, x_val] = solve_robust_inventory_ldr(N, c, hcost, pcost, mu, xMax, alpha, zCovar, zFDev, zBDev)
% 
% +ROMETEST\SOLVE_ROBUST_INVENTORY_LDR Helper routine to solve
% a robust inventory problem using the linear decision rule. 
%
% Inputs:
%   N     : Number of periods (integer)
%   c     : Order cost of goods in each period
%   hcost : Holding cost of goods in each period
%   pcost : Backorder cost of goods in each period
%   alpha : Autocorrelation factor (betweeen 0 and 1)
%   xMax  : Maximum order quantity in each period
%   mu    : Mean demand in each period (scalar)
%   zCovar: Covariance of random variables
%   zFDev : Upper bound on forward deviation 
%   zBDev : Upper bound on backward deviation 
%
% Modified by:
% 1. Joel (Created 20 May 2009)
% 

zSymRange = mu ./ N;

if(nargin < 10)
    zBDev = 0.58 * zSymRange;
end
if(nargin < 9)
    zFDev = 0.58 * zSymRange;
end
if(nargin < 8)
    zCovar = (0.58 * zSymRange)^2 * speye(N);
end
if(nargin < 7)
    alpha = 0;
end

% construct indices
end_ind = cumsum(1:N);
start_ind = 1 + end_ind - (1:N);
L2 = zeros(N, sum(1:N));
for ii = 1:N
    L2(ii, start_ind(ii):end_ind(ii)) = 1;
end

% construct another set of indices
L3 = zeros(sum(1:N), N);
for ii = 1:N
    L3(start_ind(ii):end_ind(ii), 1:ii) = eye(ii);
end

% begin rome
h = rome_begin('Robust Inventory');   

% uncertainties
z = rome_rand_model_var(N);
z.set_mean(0);

rome_box(z, -zSymRange, zSymRange);
z.Covar = zCovar;
z.FDev = zFDev;
z.BDev = zBDev;

% model variables
pX = logical([tril(ones(N)), zeros(N, 1)]);
x = rome_linearrule(N, z, 'Pattern', pX);
y = rome_linearrule(N, z);

% differencing matrix
D = eye(N) - diag(ones(N-1, 1), -1);

% demand 
d = (alpha* tril( ones(N), -1) + eye(N)) * z + mu; 

% inventory balance constraint
rome_constraint(D*y == x - d);

% order quantity constraint
rome_box(x, 0, xMax);

% objective
rome_minimize(c'*mean(x) ...
    + hcost'*rome_create_bound(y, @rome_supp_bound, @rome_covar_bound, @rome_dirdev_bound) ...
    + pcost'*rome_create_bound(-y, @rome_supp_bound, @rome_covar_bound, @rome_dirdev_bound));

% solve
h.solve;
obj_val = h.objective;
x_val   = squeeze(linearpart(h.eval(x)));

rome_end;


