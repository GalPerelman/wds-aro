function [obj_val, V, W, X] = solve_warehouse_linearrule(z_LB, z_UB, mean_d_it, a_it, c_j, s_j, r_j)

% 
% +ROMETEST\SOLVE_WAREHOUSE_LINEARRULE Helper routine to solve
% warehouse problem using a linear-decision rule
%
%   [obj_val, V, W, X] = SOLVE_WAREHOUSE(z_LB, z_UB, d, A, C, S, R) returns the
%   minimum cost, storage policy V, retrieval policy W, and holding policy
%   X for the supplied data.
%   
%   Define: M as the number of types of good, N as number of storage
%   classes, and T as the planning horizon, the arguments to this function
%   are:
%
%   z_LB: M by T matrix of lower bound on primitive uncertainty
%   z_UB: M by T matrix of upper bound on primitive uncertainty
%   d   : M by T matrix of mean demand in each period. The actual demand is
%         computed as d_actual = d + z;
%   A   : M by T matrix of fixed supply of goods in each period.
%   C   : N by 1 column vector of capacity of each storage class
%   S   : N by 1 column vector of storage costs for the storage classes
%   R   : N by 1 column vector of retrieval costs for the storage classes
%
%   Defaults: M = 3, T = 3, N = 5. Default values for each of the arguments
%   can be found in the .m file.
%
% Modified by:
% 1. Joel (22 Oct 2008)
%

% begin rome environment
rome_begin;

% default arguments
if(nargin < 7) 
    r_j  = [  1, 1.5,  2,  3, 100]';      % column-vector of retrieve costs
end
if(nargin < 6) 
    s_j  = [  1, 1.5,  2,  3, 100]';      % column-vector of store costs
end
if(nargin < 5) 
    c_j  = [ 15,  30, 45, 60, 300000]';   % column-vector of storage capacities
end
if(nargin < 4) 
    a_it = [35 35 35; ...   % fixed arrival of product i at time t
            35 35 35; ...
            10 10 25];  
end
if(nargin < 3) 
    mean_d_it = [29, 19, 45; ... % mean demand of product i at time t
                 10, 47, 37; ...
                  6,  7, 20];
end
if(nargin < 2) 
    z_UB = 1;
end
if(nargin < 1) 
    z_LB = -1;
end

% DATA
M = size(a_it, 1);  % number of products
N = length(c_j)  ;  % number of storage classes
T = size(a_it, 2);  % number of time periods

% start a model
h = rome_model('Linearrule Warehouse Model');

% Define primitive uncertainties
z = rome_rand_model_var(M, T);
rome_constraint(z >= z_LB);
rome_constraint(z <= z_UB);

% Define recourse variables

% num pallets of product i assigned to storage class j in period t (after observing z_(t-1))
v_ijt = rome_empty_var(M, N, T); 
for tt = 1:T
    v_ijt(:, :, tt) = rome_linearrule(M, N, z(:, 1:tt-1));
end

% num pallets of product i retrieved from storage class j in period t (after observing z_t)
w_ijt = rome_empty_var(M, N, T); 
for tt = 1:T
    w_ijt(:, :, tt) = rome_linearrule(M, N, z(:, 1:tt));
end
% num pallets of product i in storage class j at start of period t (after observing t-1)
x_ijt = rome_empty_var(M, N, T+1); 
for tt = 1:T+1
    x_ijt(:, :, tt) = rome_linearrule(M, N, z(:, 1:tt-1));
end

d_it = mean_d_it + z; % uncertain demand vector

% Define Constraints
% Goods Supply Constraint Set
rome_constraint(squeeze(sum(v_ijt, 2)) == a_it);

% Goods Demand Constraint Set
rome_constraint(squeeze(sum(w_ijt, 2)) == d_it);

% Goods Carry Forward Constraint Set
for tt = 1:T
    q = x_ijt(:, :, tt) + v_ijt(:, :, tt) - w_ijt(:, :, tt);
    rome_constraint(x_ijt(:, :, tt+1) == q);
end

% No Initial Inventory Constraint Set
rome_constraint(x_ijt(:, :, 1) == 0);

% No Exceed Capacity Constraint Set
C_jt = repmat(c_j, 1, T);   % expanded matrix of storage capacities
rome_constraint(squeeze(sum(x_ijt(:, :, 1:T) + v_ijt, 1)) <= C_jt);

% Non-negativity constraints
rome_constraint(v_ijt >= 0);
rome_constraint(w_ijt >= 0);
rome_constraint(x_ijt >= 0);

% Cost Objective
S_ijt = repmat(s_j', [M, 1, T]);
R_ijt = repmat(r_j', [M, 1, T]);
g = S_ijt .* strip_rand(v_ijt) + R_ijt .* strip_rand(w_ijt);
g = sum(g(:));
rome_minimize(g);

% Solve
h.solve;

% return output
V = linearpart(h.eval(v_ijt));
W = linearpart(h.eval(w_ijt));
X = linearpart(h.eval(x_ijt));
obj_val = h.objective;


% ROME: Copyright (C) 2009 by Joel Goh and Melvyn Sim
% See the file COPYING.txt for full copyright information.