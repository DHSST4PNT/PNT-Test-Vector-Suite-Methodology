classdef GPSL1CCodeGenerator < RepeatingSampleGenerator
%%
% @brief A class that generates GPS L1C chips.
%
%
% @copyright Copyright &copy; 2017 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No.
% FA8702-17-C-0001, and is subject to the Rights in Noncommercial Computer
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)

    properties (SetAccess = private)
        prn; % The pseudorandom number (PRN).
    end

    methods (Access = public)
        function obj = GPSL1CCodeGenerator(prn, component)
        %%
        % @brief Create a new instance of a GPA L1C code generator. Note that this does not
        % currently implement the TMBOC component, codes are output as BOC(1,1) only
        %
        % @par Usage
        % obj = GPSL1CCodeGenerator(prn, component)
        %
        % @param[in] prn The GPS pseudorandom number (PRN).
        % @param[in] component The component, 'p' for  pilot or 'd' for data, in a string.
        %
        % @param[out] obj The created object.
        
            % pre-generated struct array with elements prn, d_code, p_code.  d_code and p_code are
            % 10230-element arrays containing the 1/0-valued PRN sequences for the data and pilot
            % components, respectively, for L1C
            % also contains l1c_overlay_table with the L1Cp overlay sequences
            code_table = 'l1c_code_table.mat';
            if ~exist(code_table, 'file')
                error(['Cannot find L1C PRN code table ' code_table '\n'])
            end

            load(code_table)
            code_idx = find([l1c_code_table.prn]==prn,1);
            if isempty(code_idx)
                error(['Code sequence for PRN ' prn ' not present in table ' code_table '\n']);
            end
            
            if lower(component) == 'd'
                chips = l1c_code_table(code_idx).d_code;
            elseif lower(component) == 'p'
                chips = l1c_code_table(code_idx).p_code;
                secondary_code = l1c_overlay_table(code_idx).p_overlay;
                % Apply the piot overlay code 
                upsampled_secondary_code = kron(secondary_code, ones(numel(chips), 1));
                chips = bitxor(repmat(chips, numel(secondary_code), 1), upsampled_secondary_code);
            else
                error('Component not (p)ilot or (d)ata');
            end

            % Compute BOC(1,1) samples from chips, scale [0/1] to [-1/1].
            samples = (binToBOC(chips', 1, 1)') * 2 - 1;
            CHIPPING_RATE = 1.023e6;
            SUB_CHIP_RATE = CHIPPING_RATE * 2;
            obj = obj@RepeatingSampleGenerator(samples, 1, SUB_CHIP_RATE, true);

            obj.prn = prn;
        end
    end
end
