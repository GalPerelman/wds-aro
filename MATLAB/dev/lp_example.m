model = rsome('LP Exmaple'); % Create an RSOME model named "LP Example"
model.Param.solver = 'gurobi';

x = model.decision; % Create a decision variable x
y = model.decision; % Create a decision variable y

model.max(3*x + 4*y); % Define the objective function

model.append(2.5*x + y <= 20); % Add the 1st constraint
model.append(x + 2*y <= 16); % Add the 2nd constraint
model.append(abs(y) <= 4); % Add the 3rd constraint

model.solve; % Solve the problem
Obj = model.get % Get the objective value
X = x.get % Get the optimal solution of x
Y = y.get