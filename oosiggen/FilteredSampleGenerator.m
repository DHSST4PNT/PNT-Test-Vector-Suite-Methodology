classdef FilteredSampleGenerator < SampleGenerator
%%
% @brief A class that generates linearly filtered samples.
%
%
% @copyright Copyright &copy; 2014 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-14-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)
    
    properties (SetAccess = private)
        filter_b; % The B-coefficients of the filter.
        filter_a; % The A-coefficients of the filter.
    end
    
    properties (Access = private)
        sample_generator; % The sample generator source.
        filter_state_initialized; % True if the filter state is initialized.
        filter_state; % The current filter state.
    end
    
    methods (Access = public)
        function obj = FilteredSampleGenerator(sample_generator, filter_b, ...
                                               varargin)
        %%
        % @brief Create a new instance of a filtered sample generator.
        %
        % This class takes in a SampleGenerator as well as filter coefficients.
        % It will pull the samples from the SampleGenerator and perform the
        % filtering operation with filter().
        %
        % @par Usage
        % obj = FilteredSampleGenerator(sample_generator, filter_b)
        % obj = FilteredSampleGenerator(sample_generator, filter_b, filter_a)
        %
        % @param[in] sample_generator The source that generates the samples
        %            to be filtered. Must be an instance of a SampleGenerator.
        % @param[in] filter_b The B-coefficients of the filter (see filter());
        % @param[in] filter_a Optional. The A-coefficients of the filter
        %            (see filter()). Defaults to a scalar one.
        %
        % @param[out] obj The created object.
            obj = obj@SampleGenerator(sample_generator.sampling_rate, ...
                                      sample_generator.use_neighbor_interp);
            
            obj.sample_generator = sample_generator;
            obj.filter_b = filter_b;
            if nargin == 2
                obj.filter_a = 1;
            elseif nargin == 3
                obj.filter_a = varargin{1};
            else
                error('Invalid number of input arguments.');
            end
            validateattributes(obj.sample_generator, ...
                               {'scalar', 'SampleGenerator'}, {});
            validateattributes(obj.filter_b, {'numeric', 'vector'}, {});
            validateattributes(obj.filter_a, {'numeric', 'vector'}, {});
            obj.filter_state_initialized = false;
        end
        
        function samples = getSamples(obj, num_samples)
        %%
        % @brief Get a set of samples.
        %
        % Calling this function returns the next @c num_samples samples, and
        % advances the internal code generator state by that number of 
        % samples.
        %
        % @par Usage
        % samples = obj.getSamples(num_samples)
        %
        % @param[in] obj The class instance.
        % @param[in] num_samples The number of samples to return.
        %
        % @param[out] samples The array of samples (zeroes and ones).
            num_samples = round(num_samples); % Ensure an integer.
            validateattributes(num_samples, {'scalar', 'numeric'}, {'>', 0});
            
            if ~obj.filter_state_initialized
                [samples, obj.filter_state] = ...
                    filter(obj.filter_b, obj.filter_a, ...
                           obj.sample_generator.getSamples(num_samples));
                 obj.filter_state_initialized = true;
            else
                [samples, obj.filter_state] = ...
                    filter(obj.filter_b, obj.filter_a, ...
                           obj.sample_generator.getSamples(num_samples), ...
                           obj.filter_state);
            end
        end
    end
end
