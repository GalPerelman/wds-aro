% net = build_net('data');
% % net.combs = net.read_combs_from_file('data\tariffs.csv');
% net.data_folder = 'data';
% unique(net.fsp.facility)

% tank_inflows = sim.net.fsp(sim.net.fsp.in == 1, :)
% max_inflows = groupsummary(tank_inflows(:, ["facility", "flow"]), "facility", "max")
% total_max_inflow = sum(table2array(max_inflows(:, 'max_flow')))
% static_min_vol = sim.net.tanks{1, "min_vol"}

% facilities = unique(sim.net.fsp.facility);
% faility_combs = sim.net.fsp(sim.net.fsp.facility == facilities(i), :);
        % n_combs = height(faility_combs);

% power = sim.net.fsp{:, "power"}'
% a = [(power * x)', sim.data{:, "tariff"}, (power * x)' .* sim.data{:, "tariff"}]
% sum(a)