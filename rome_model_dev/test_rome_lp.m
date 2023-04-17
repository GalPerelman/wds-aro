% EX_SIMPLE_LP .m
% Script file for solving a simple Linear Program .
clc

rome_begin ; % Set up ROME Environment
h = rome_model ('Simple LP'); % Create Rome Model
h.Solver = 'MOSEK';
newvar x y; % Set up modeling variables

% set up objective function
rome_maximize (12 * x + 15 * y);

% input constraints
rome_constraint (x + 2* y <= 40) ;
rome_constraint (4* x + 3* y <= 120) ;
rome_constraint (x >= 0) ;
rome_constraint (y >= 0) ;
% solve and extract solution values
h.solve;
x_val = h. eval(x );
y_val = h. eval(y );

rome_end ; % Clear up ROME environment