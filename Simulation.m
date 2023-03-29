classdef Simulation
    properties
        t1
        t2
        net
        elec
        demands
        data_folder
        time_range
        T
        data
        vars
    end
    
    methods
        function obj = init(obj, data_folder, t1, t2)
            obj.data_folder = data_folder;

            obj.net = Network;
            obj.net = obj.net.init(data_folder);
            obj.net.data_folder;

            obj.t1 = t1;
            obj.t2 = t2;

            obj.time_range = (t1:1:t2)';
            obj.T = length(obj.time_range);
            obj.elec = obj.read_data_from_file(fullfile(data_folder, 'tariffs.csv'));
            obj.demands = obj.read_data_from_file(fullfile(data_folder, 'demands.csv'));
            obj.data = obj.build();
            obj.vars = obj.get_vars();
        end
        
        function data = read_data_from_file(obj, file_path)
            data = readtable(file_path);
        end

        function data = build(obj)
            time = obj.time_range;
            data = table(time);
            data = join(data, obj.demands, 'Keys', 'time');
            data = join(data, obj.elec, 'Keys', 'time');
            
        end

        function vars = get_vars(obj)
            facilities = unique(obj.net.fsp.facility);
            vars = table;
            for i = 1:1:size(unique(obj.net.fsp.facility), 1)
                faility_combs = obj.net.fsp(obj.net.fsp.facility == facilities(i), :);
                n_combs = height(faility_combs);

                facility_name = repmat(facilities(i),1,n_combs*obj.T)';
                time = repmat(obj.time_range, n_combs, 1);
                vars = [vars; table(time, facility_name)];
                
            end
        end

        function total_max_inflow = get_tank_max_inflow(obj, tank_idx)
                fsp_inflows = obj.net.fsp(obj.net.fsp.in == tank_idx, :);
                max_fsp_inflows = groupsummary(fsp_inflows(:, ["facility", "flow"]), "facility", "max");
                total_max_fsp_inflow = sum(table2array(max_fsp_inflows(:, 'max_flow')));

                vsp_inflows = obj.net.vsp(obj.net.vsp.in == tank_idx, :);
                max_vsp_inflows = groupsummary(vsp_inflows(:, ["name", "max_flow"]), "name", "max");
                total_max_vsp_inflow = sum(table2array(max_vsp_inflows(:, 'max_max_flow')));
                
                total_max_inflow = total_max_fsp_inflow + total_max_vsp_inflow;
        end
        
        function demand = get_tank_demand(obj, tank_idx)
                 tank_consumer = obj.net.tanks{tank_idx, "demand"};
                 demand = table2array(obj.data(:, tank_consumer));
        end
        
        function min_vol = get_min_vol_vector(obj, tank_idx, is_dynamic)
                static_min_vol = obj.net.tanks{tank_idx, "min_vol"};
                final_vol = obj.net.tanks{tank_idx, "final_vol"};

                if is_dynamic == 0
                    min_vol = static_min_vol .* ones(obj.T, 1);
                else
                    q_max = obj.get_tank_max_inflow(tank_idx);
                    demand = obj.get_tank_demand(tank_idx);
                    dynamic_min = final_vol;
                    for t=1:1:obj.T
                        v = max(static_min_vol, dynamic_min(1) + demand(t) - q_max);
                        dynamic_min = [v; dynamic_min];
                    end
                    min_vol = dynamic_min(2:end);
                end  
        end

        function vol = get_tank_vol(obj, x_fsp, x_vsp, tank_idx)
                lhs = obj.net.tanks{tank_idx, "init_vol"};
                for i = 1:1:height(obj.net.fsp.facility)
                    if obj.net.fsp{i, "in"} == tank_idx
                        mat = obj.net.get_cumulative_mat(obj.T, 1);
                        lhs = lhs + obj.net.fsp{i, "flow"} * mat * x_fsp(i, :)';
                    elseif obj.net.fsp{i, "out"} == tank_idx
                        mat = obj.net.get_cumulative_mat(obj.T, -1);
                        lhs = lhs + obj.net.fsp{i, "flow"} * mat * x_fsp(i, :)';
                    else
                        continue
                    end
                end

                for i = 1:1:height(obj.net.vsp)
                    if obj.net.vsp{i, "in"} == tank_idx
                        mat = obj.net.get_cumulative_mat(obj.T, 1);
                        lhs = lhs + mat * x_vsp(i, :)';
                    elseif obj.net.vsp{i, "out"} == tank_idx
                        mat = obj.net.get_cumulative_mat(obj.T, -1);
                        lhs = lhs + mat * x_vsp(i, :)';
                    else
                        continue
                    end
                end

                tank_consumer = obj.net.tanks{tank_idx, "demand"};
                cum_demand = table2array(cumsum(obj.data(:, tank_consumer)));
                vol = lhs - cum_demand;
        end

        function flow = get_fsp_flow(obj, x, facility)
                facility_idx = obj.net.fsp{obj.net.fsp.facility == facility, "comb"};
                faility_flows = obj.net.fsp{obj.net.fsp.facility == facility, "flow"};
                flow = faility_flows' * x(facility_idx, :);
        end

    end
end

