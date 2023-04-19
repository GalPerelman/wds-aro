model = rsome;                  % Create an AROMA model

z = model.random(4);            % Random variables z

S = 8;                          % Number of scenarios
P = model.ambiguity(S);         % Create an ambiguity set with 8 scenarios
model.with(P);                  % The ambiguity set of the model is P

tree = P.tree(4);               % Create a scenario tree with 4 stages
tree(3).mergechild({1:2, 3:4, ...
                    5:7, 8});   % Merge stage 4 events to form stage 3 event set
tree(2).mergechild({1:2, 3:4}); % Merge stage 3 events to form stage 2 event set 
tree(1).mergechild({1:2});      % Merge stage 2 events to form stage 1 event set
                                    
tree.plot;                      % Visualize the scenario tree