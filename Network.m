classdef Network
   properties
      data_folder
      fsp
      vsp
      demands
      tanks
   end
   
   methods
      function obj = init(obj, data_folder)
        obj.data_folder = data_folder;
        obj.fsp = obj.read_data_from_file(fullfile(data_folder, 'fsp.csv'));
        obj.fsp.facility = string(obj.fsp.facility);
        
        obj.tanks = obj.read_data_from_file(fullfile(data_folder, 'tanks.csv'));
        obj.tanks.demand = string(obj.tanks.demand);
        
      end

      function data = read_data_from_file(obj, file_path)
        data = readtable(file_path);
        
      end

   end

   methods(Static)
       function mat = get_cumulative_mat(T, multiplier)
           % multiplier can be flow direction 1 or -1
           mat = tril(ones(T, T)) * multiplier;
       end

   end
end


