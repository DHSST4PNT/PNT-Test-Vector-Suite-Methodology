classdef GPSL5CodeGenerator < RepeatingSampleGenerator
%%
% @brief A class that generates GPS L5 I or Q chips.
%
%
% @copyright Copyright &copy; 2023 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No.
% FA8702-16-C-0001, and is subject to the Rights in Noncommercial Computer
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)

    properties (SetAccess = private)
        prn; % The pseudorandom number (PRN).
    end

    methods (Access = public)
        function obj = GPSL5CodeGenerator(prn, component)
        %%
        % @brief Create a new instance of a GPS L5 code generator.
        %
        % @par Usage
        % obj = GPSL5CodeGenerator(prn)
        %
        % The resulting samples reflect the L5 I/Q chipping sequence modulated
        % with the appropriate secondary code.
        %
        % @param[in] prn The GPS pseudorandom number (PRN).
        % @param[in] component The component, 'I' or 'Q' for in-phase or quadrature, respectively
        %
        % @param[out] obj The created object.
        
            % pre-generated struct array with elements prn, i_code, q_code. i_code and q_code are
            % 10230-element arrays containing the 1/0-valued PRN sequences for the data and pilot
            % components, respectively, for L5
            % also contains nh_i and nh_q arrays with I and Q Neuman-Hofman sequences
            code_table = 'l5_code_table.mat';
            if ~exist(code_table, 'file')
                error(['Cannot find L5 PRN code table ' code_table '\n'])
            end

            load(code_table)
            code_idx = find([l5_code_table.prn]==prn,1);
            if isempty(code_idx)
                error(['Code sequence for PRN ' prn ' not present in table ' code_table '\n']);
            end
            if lower(component) == 'i'
                chips = l5_code_table(code_idx).i_code;  
                secondary_code = nh_i(:);
            elseif lower(component) == 'q'
                chips = l5_code_table(code_idx).q_code;
                secondary_code = nh_q(:);
            else
                error('Component must be either I or Q')
            end
            
            CHIPPING_RATE = 10.23e6;
            
            % Apply the Neuman-Hofman secondary code and convert to +/- 1
            upsampled_secondary_code = kron(secondary_code, ones(numel(chips), 1));
            modulated_chips = bitxor(repmat(chips, numel(secondary_code), 1), ...
                              upsampled_secondary_code) * 2 - 1;
            obj = obj@RepeatingSampleGenerator(modulated_chips, 1, CHIPPING_RATE, true);

            obj.prn = prn;
        end
    end
end
