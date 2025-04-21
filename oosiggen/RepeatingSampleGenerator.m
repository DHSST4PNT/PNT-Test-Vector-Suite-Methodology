classdef RepeatingSampleGenerator < SampleGenerator
%%
% @brief A helper class that repeating signals (SampleGenerators) can inherit
%        from.
%
% This class implements a wrap-around sample generation mechanism so that
% derived subclasses need only to specify their repeating sequence and sampling
% rate.
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
        samples_array; % The fixed samples array.
        current_chip_index; % The zero-indexed current @c samples_array pointer.
        samples_array_length; % The length of @c samples_array.
    end
    
    methods (Access = public)
        function obj = RepeatingSampleGenerator(samples_array, ...
                                                start_sample, ...
                                                sampling_rate, ...
                                                use_neighbor_interp)
        %%
        % @brief Create a new instance of a repeating sample generator.
        %
        % @par Usage
        % obj = RepeatingSampleGenerator(samples_array, start_sample, ...
        %                                sampling_rate, use_neighbor_interp)
        %
        % @param[in] samples_array The repeating set of samples. Must be a
        %            scalar or column vector.
        % @param[in] start_sample The starting sample index (one-indexed). Must
        %            be a scalar integer in the inclusive range 
        %            1-numel(@c samples_array).
        % @param[in] sampling_rate The sampling rate (in samples/sec). Must be
        %            a positive scalar value.
        % @param[in] use_neighbor_interp If true, instruct upstream signal
        %            compositor (CompositeSignalGenerator) to use last-neighbor 
        %            sample-and-hold interpolation when resampling this
        %            generator's samples (otherwise, use cubic). Cubic
        %            interpolation may be appropriate for "continuous" signals
        %            such as sinusoids, but not for signals such as GNSS
        %            chipping signals (square waves). Must be a scalar logical.
        %
        % @param[out] obj The created object.
            validateattributes(samples_array, {'numeric'}, {'column'});
            validateattributes(start_sample, {'numeric'}, ...
                               {'scalar', 'integer'}); % Value validated below.
            validateattributes(sampling_rate, {'numeric'}, ...
                               {'scalar', 'positive'});
            validateattributes(use_neighbor_interp, {'logical'}, {'scalar'});
            
            obj = obj@SampleGenerator(sampling_rate, use_neighbor_interp);
            
            obj.samples_array = samples_array;
            obj.samples_array_length = numel(obj.samples_array);
            if (start_sample < 1 || start_sample > obj.samples_array_length)
                error(['Invalid start_sample (' num2str(start_sample) '). '
                       'Must be 1-' num2str(obj.samples_array_length) '.']);
            end
            obj.current_chip_index = start_sample - 1; % Zero-indexed.
        end
    end
    
    methods (Sealed = true, Access = public)    
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
        % @param[in] num_samples The number of samples to return; must be an
        %            integer > 0.
        %
        % @param[out] samples The array of samples.
            num_samples = round(num_samples); % Ensure an integer.
            validateattributes(num_samples, {'scalar', 'numeric'}, {'>', 0});
            
            % Zero-indexed current_idxs.
            current_idxs = (obj.current_chip_index) : ...
                           (obj.current_chip_index + num_samples - 1);
            current_idxs = mod(current_idxs, obj.samples_array_length);
            
            samples = obj.samples_array(current_idxs + 1);
            
            obj.current_chip_index = mod(obj.current_chip_index + num_samples, ...
                                         obj.samples_array_length);
        end
        
        function advance(obj, num_samples)
        %%
        % @brief Advance the sample generator by a specified number of samples.
        %
        % @par Usage
        % obj.advance(num_samples)
        %
        % @param[in] obj The class instance.
        % @param[in] num_samples The number of samples to advance the sample
        %            generator by; must be an integer > 0.
            num_samples = round(num_samples); % Ensure an integer.
            validateattributes(num_samples, {'scalar', 'numeric'}, {'>', 0});
            obj.current_chip_index = mod(obj.current_chip_index + num_samples, ...
                                         obj.samples_array_length);
        end
    end
end
