classdef GLONASSCACodeGenerator < RepeatingSampleGenerator
%%
% @brief A class that generates GLONASS C/A chips.
%
%
% @copyright Copyright &copy; 2023 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)

    methods (Access = public)
        function obj = GLONASSCACodeGenerator(varargin)
        %%
        % @brief Create a new instance of a GLONASS C/A code generator.
        %
        % @par Usage
        % obj = GLONASSCACodeGenerator()
        %
        %
        % @param[out] obj The created object.
            code_table = 'l1of_code_table.mat';
            
            if ~exist(code_table, 'file')
                error(['Cannot find L1OF code table ' code_table '\n'])
            end
            
            load(code_table)
            chips = l1of_code_table.code;
                        
            CHIPPING_RATE = 511e3;
            obj = obj@RepeatingSampleGenerator(chips, 1, CHIPPING_RATE, true);

        end
    end
end
