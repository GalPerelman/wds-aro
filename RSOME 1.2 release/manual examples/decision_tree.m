w = tree(1).decision(2, 2, 'B');               % Binary decisions w for stage 1
x = tree(2:3).decision(2, 1);                  % Decision x for stage 2 and 3
y = tree(3:4).decision(2, 3);                  % Decision y for stage 3 and 4

model.append(w(:, 1) + x.stage(2) == 0);       % w at stage 1 and x at stage 2
model.append(x.stage(3) <= y(:, 1).stage(3));  % x at stage 3 and y at stage 3