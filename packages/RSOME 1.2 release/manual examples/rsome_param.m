model = rsome;				   		   % Create an RSOME model

model.Param.solver = 'gurobi';		   % Change the solver to be Gurobi
model.Param.solver = 'cplex';		   % Change the solver to be CPLEX

model.Param.display = 0;	           % Disable the display of solution status
model.Param.display = 1;	           % Enable the display of solution status

model.Param.mipgap = 1e-3;	           % Set the MIP gap to be 1e-3
