model = rsome('LP Exmaple');        % Create a model, named "LP Example"

x = model.decision;                 % Create a decision x for model
y = model.decision;                 % Create a decision y for model

model.max(3*x + 4*y);               % Define objective function

model.append(2.5*x + y <= 20);      % Add the 1st constraint to model
model.append(x + 2*y <= 16);        % Add the 2nd constraint to model
model.append(abs(y) <= 4);          % Add the 3rd constraint to model

model.solve;                        % Solve the problem

Obj = model.get;                    % Get the objective value
X = x.get;                          % Get solution x
Y = y.get;                          % Get solution y