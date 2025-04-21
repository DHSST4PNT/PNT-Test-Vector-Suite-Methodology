classdef DataSymbolGenerator < handle
%%
% @brief An abstract class that generates data symbols.
%
% New data symbol generators should inherit from this class and implement
% the getNextSymbol() function.
%
% @copyright Copyright &copy; 2013 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)
    
    properties(SetAccess = private)
        symbol_period; % The symbol period (in sec).
    end
    
    methods (Access = public)
        function obj = DataSymbolGenerator(symbol_period)
        %%
        % @brief Create a new instance.
        %
        % @par Usage
        % obj = DataSymbolGenerator(symbol_period)
        %
        % @param[in] symbol_period The symbol period (in sec).
        %
        % @param[out] obj The created object.
            validateattributes(symbol_period, {'numeric', 'scalar'}, {'>', 0});
            obj.symbol_period = symbol_period;
        end
    end
        
    methods (Abstract)
        symbol = getNextSymbol(obj)
        %%
        % @brief Get the next data symbol.
        %
        % Data symbols can be complex and should have maximal unit magnitude,
        % although this condition is not enforced.
        %
        % @par Usage
        % symbol = obj.getNextSymbol()
        %
        % @param[in] obj The class instance.
        %
        % @param[out] symbol The data symbol.
    end
end
