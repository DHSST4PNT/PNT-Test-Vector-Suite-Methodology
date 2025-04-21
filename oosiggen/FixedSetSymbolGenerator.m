classdef FixedSetSymbolGenerator < DataSymbolGenerator
%%
% @brief A class to parse out data symbols from a fixed set.
%
%
% @copyright Copyright &copy; 2013 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)

    properties (Access = private)
        symbols; % The fixed array of symbols.
        num_symbols; % The number of symbols in @c symbols.
        symbol_idx; % The one-indexed current symbol index.
    end

    methods (Access = public)
        function obj = FixedSetSymbolGenerator(symbol_period, symbols)
        %%
        % @brief Create a new instance.
        %
        % @par Usage
        % obj = FixedSetSymbolGenerator(symbol_period, symbols)
        %
        % @param[in] symbol_period The symbol period (in sec).
        % @param[in] symbols The vector of data symbols. When the vector of
        %            data symbols has been exhausted, ones will be returned for
        %            subsequent calls to getNextSymbol().
            validateattributes(symbol_period, {'numeric'}, ...
                               {'real', 'positive'});
            obj = obj@DataSymbolGenerator(symbol_period);
            
            validateattributes(symbols, {'numeric'}, {'vector'});
            obj.symbols = symbols;
            
            obj.num_symbols = numel(symbols);
            obj.symbol_idx = 1;
        end
        
        function symbol = getNextSymbol(obj)
        %%
        % @brief Get the next data symbol.
        %
        % @par Usage
        % symbol = obj.getNextSymbol()
        %
        % @param[in] obj The class instance.
        %
        % @param[out] symbol The data symbol.
            
            if (obj.symbol_idx > obj.num_symbols)
                symbol = 1;
            else
                symbol = obj.symbols(obj.symbol_idx);
                obj.symbol_idx = obj.symbol_idx + 1;
            end
        end
    end
end