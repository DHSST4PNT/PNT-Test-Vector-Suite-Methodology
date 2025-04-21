classdef GalileoE1OSCodeGenerator < RepeatingSampleGenerator
%%
% @brief A class that generates Galileo E1C/B chips.
%
%
% @copyright Copyright &copy; 2023 The %MITRE Corporation
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
        function obj = GalileoE1OSCodeGenerator(prn, component)
        %%
        % @brief Create a new instance of a Galileo E1 C/B code generator. Note that this does not
        % currently implement the CBOC component, codes are output as BOC(1,1) only
        %
        % @par Usage
        % obj = GalileoE1OSCodeGenerator(prn, component)
        %
        % @param[in] prn The Galileo pseudorandom number (PRN).
        % @param[in] component The component, 'c' for  pilot (E1C) or 'b' for data (E1B), in a string.
        %
        % @param[out] obj The created object.
        
            % pre-generated struct array with elements prn, b_code, c_code.  b_code and c_code are
            % 4092-element arrays containing the 1/0-valued PRN sequences for the data and pilot
            % components, respectively, for E1C/B
            % also contains e1os_overlay_code with the E1C overlay sequence
            code_table_filename = 'e1os_code_table.mat';
            if ~exist(code_table_filename, 'file')
                error(['Cannot find E1OS PRN code table ' code_table_filename '\n'])
            end

            code_table = load(code_table_filename);
            code_idx = find([code_table.e1_code_table.prn]==prn,1);
            if isempty(code_idx)
                error([ ...
                    'Code sequence for PRN ' prn ' not present in table ' ...
                    code_table_filename '\n']);
            end
            
            if component == 'b'
                chips = code_table.e1_code_table(code_idx).b_code;
            elseif component == 'c'
                chips = code_table.e1_code_table(code_idx).c_code;
                secondary_code = code_table.e1_overlay_code;
                % Apply the pilot overlay code 
                upsampled_secondary_code = kron(secondary_code, ones(numel(chips), 1));
                chips = bitxor(repmat(chips, numel(secondary_code), 1), upsampled_secondary_code);
            else
                error('Component not c (pilot) or b (data)');
            end

            % Compute BOC(1,1) samples from chips, scale [0/1] to [-1/1].
            samples = (binToBOC(chips', 1, 1)') * 2 - 1;
            CHIPPING_RATE = 2 * 1.023e6; % BOC conversion has the effect of doubling chipping rate
            obj = obj@RepeatingSampleGenerator(samples, 1, CHIPPING_RATE, true);

            obj.prn = prn;
        end
    end
end
