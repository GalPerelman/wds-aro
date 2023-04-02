classdef utils
    methods(Static)

        function mat = get_mat_for_value_canges(n, valid_idx)
            mat = eye(n);
            [rows, cols] = meshgrid(1:n-1, 1:n-1); 
            rows_vals = diag(rows) + 1;
            cols_vals = diag(cols);
            mat(sub2ind([n,n], rows_vals, cols_vals)) = -1;
            mat(1, 1) = 0;

            mask = zeros(n, 1);
            mask(valid_idx) = 1;
            mat = mat .* mask;
        end

        function const_idx = get_constant_tariff_periods(tariff)
            diffs = circshift(tariff, 1) - tariff;
            const_idx = zeros(size(diffs));
            const_idx(diffs~=0) = 1;
            const_idx = cumsum(const_idx) + 1;
        end
        
    end
end

