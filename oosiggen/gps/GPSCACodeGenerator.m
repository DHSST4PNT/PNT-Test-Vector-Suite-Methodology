classdef GPSCACodeGenerator < RepeatingSampleGenerator
    %%
    % @brief A class that generates GPS C/A chips.
    %
    %
    % @copyright Copyright &copy; 2013 The %MITRE Corporation
    %
    % @par Notice
    % This software was produced for the U.S. Government under Contract No.
    % FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer
    % Software and Noncommercial Computer Software Documentation Clause
    % (DFARS) 252.227-7014 (JUN 1995)
    
    properties (SetAccess = private)
        prn; % The pseudorandom number (PRN).
    end
    
    methods (Access = public)
        function obj = GPSCACodeGenerator(prn)
            %%
            % @brief Create a new instance of a GPA C/A code generator.
            %
            % @par Usage
            % obj = GPSCACodeGenerator(prn)
            %
            % @param[in] prn The GPS pseudorandom number (PRN).
            %
            % @param[out] obj The created object.
            
            % pre-generated struct array with elements "prn" and "code".  The "code" arrays are 
            % 1023-element arrays containing the +/-1-valued PRN sequences for the GPS L1 C/A code            
            code_table = 'ca_code_table.mat';
            
            if ~exist(code_table, 'file')
                error(['Cannot find CA PRN code table ' code_table '\n'])
            end
            
            load(code_table)
            code_idx = find([ca_code_table.prn]==prn,1);
            if isempty(code_idx)
                error(['Code sequence for PRN ' prn ' not present in table ' code_table '\n']);
            end
            
            chips = (ca_code_table(code_idx).code) * 2 - 1;
            
            CHIPPING_RATE = 1.023e6;
            obj = obj@RepeatingSampleGenerator(chips, 1, CHIPPING_RATE, true);
            
            obj.prn = prn;
        end
    end
end
