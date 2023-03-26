n  = 150;                                % Number of stocks 
p  = 1.15+ 0.05/150*(1:n)';              % Mean return
sigma = 0.05/450*sqrt(2*(1:n)'*n*(n+1)); % Deviation
Gamma = 3;

model=rsome('portfolio');           % create a model

x=model.decision(n);                % decisions as fraction of investment

z=model.random(n);                  % random deviations from the expected returns

P = model.ambiguity;                % Ambiguity set of the AROMA model
P.suppset(norm(z, Inf) <= 1, ...
          norm(z, 1) <= Gamma);     % Uncertainty set of z
model.with(P);                      % The ambiguity set of model is P

r = p + sigma.*z;                   % random return of stocks
model.max(r'*x)                     % define objective
model.append(sum(x)==1);               % constraint of x
model.append(x>=0);                    % bound of x

model.solve;                        % solve the problem
