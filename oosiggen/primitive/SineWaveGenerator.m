classdef SineWaveGenerator < SampleGenerator
%%
% @brief A class that generates samples from a sine wave.
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
        frequency; % The frequency (in Hz).
    end
    
    properties (Access = private)
        sample_counter; % The current sample.
    end
    
    methods (Access = public)
        function obj = SineWaveGenerator(sampling_rate, frequency)
        %%
        % @brief Create a new instance of a sine wave generator.
        %
        % @par Usage
        % obj = SineWaveGenerator(sampling_rate, frequency)
        %
        % @param[in] sampling_rate The sampling rate (in samples/sec).
        % @param[in] frequency The sine wave frequency (in Hz).
        %
        % @param[out] obj The created object.
            obj = obj@SampleGenerator(sampling_rate, false);
            obj.frequency = frequency;
            obj.sample_counter = uint64(0);
            validateattributes(obj.frequency, {'scalar', 'numeric'}, {});
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
            
            current_time_vector = ...
                double(obj.sample_counter:(obj.sample_counter + ...
                                           num_samples - 1)) / ...
                obj.sampling_rate;
            samples = sin(2 * pi * obj.frequency * current_time_vector);
            obj.sample_counter = obj.sample_counter + num_samples;
        end
    end
end
