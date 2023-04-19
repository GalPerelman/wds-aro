model = rsome;                          % Create an RSOME model
x = model.decision(8, 1);               % Define a 8*1 decision variable matrix
y = model.decision(1, 3);               % Define a 1*3 decision variable matrix

B = ones(3, 1);                         % B is a 3*1 matrix
model.append(abs(x(1:3)) <= y');        % Absolute value of x(1:3)
model.append(y(1) >= norm(x));          % Euclidean norm of x
model.append(y(2) >= norm(x, 1));       % 1-norm of x
model.append(-sumsqr(x) + 4 >= 0);      % Sum of square of vector x
model.append(x(1:3, :).^2 - B<=0);      % Element-wise square of x(1:3,:)