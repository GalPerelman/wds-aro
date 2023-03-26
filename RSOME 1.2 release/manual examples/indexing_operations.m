model = rsome;                      % Create an RSOME model;

x = model.decision(5, 6);           % Define a 5*6 decision variable matrix
y = model.decision(3);              % Define a 3*1 decision variable matrix
z = model.decision(5);              % Define a 5*1 decision variable matrix

model.append(x >= 0);               % Each element of x is nonnegative
model.append(x >= zeros(5,6));      % Same as above
model.append(3*x(1, 5) <= 10);      % Element of x in row 1, column 5
model.append(x(1, :) <= x(5, :));   % The 1st row of x is no larger than the 5th
model.append(x(8) <= 2);            % Element of x in row 3 and column 2

A = ones(5, 5);                     % A is a 5*5 matrix  
b = ones(5, 1);                     % b is a 5*1 vector
c = rand(3, 1);                     % c is a 3*1 vector  
model.append(A*z + b >= 0);         % Matrix multiplication A*x
model.append(sum(z) - y'*c == 1);   % Transpose of y, sum of each element of x
model.append(c.*y <= 2)             % Element-wise multiplication c.*y
 