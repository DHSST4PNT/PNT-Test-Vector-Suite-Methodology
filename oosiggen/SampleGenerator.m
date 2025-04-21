classdef SampleGenerator < handle
%%
% @brief An abstract class that generates sequences of samples.
%
% New sample generators should inherit from this class and implement the
% getSamples() and advance() functions. Examples of subclasses may include a
% chip generator for a BPSK signal, a sub-chip generator for a BOC signal, or a
% noise source that generated random samples.
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
        sampling_rate; % The sampling rate (in samples/sec).
        % If true, use last-neighbor interpolation when resampling this
        % generator's samples to another rate.
        use_neighbor_interp;
    end
    
    methods (Access = public)
        function obj = SampleGenerator(sampling_rate, use_neighbor_interp)
        %%
        % @brief Create a new instance of a sample generator.
        %
        % @par Usage
        % obj = SampleGenerator(sampling_rate)
        %
        % @param[in] sampling_rate The sampling rate (in samples/sec).
        % @param[in] use_neighbor_interp If true, instruct upstream signal
        %            compositor (CompositeSignalGenerator) to use last-neighbor 
        %            sample-and-hold interpolation when resampling this
        %            generator's samples (otherwise, use cubic). Cubic
        %            interpolation may be appropriate for continuous signals
        %            such as sinusoids, but not for signals such as GNSS
        %            chipping signals.
        %
        % @param[out] obj The created object.
            validateattributes(sampling_rate, {'numeric'}, {'scalar', '>', 0});
            obj.sampling_rate = sampling_rate;
            validateattributes(use_neighbor_interp, {'logical'}, {'scalar'});
            obj.use_neighbor_interp = use_neighbor_interp;
        end
    end
    
    methods (Abstract)
        samples = getSamples(obj, num_samples)
        %%
        % @brief Get a set of samples.
        %
        % Calling this function returns the next @c num_samples samples, and
        % advances the internal sample generator state by that number of
        % samples.
        %
        % @par Usage
        % chips = obj.getSamples(num_samples)
        %
        % @param[in] obj The class instance.
        % @param[in] num_samples The number of samples to return; must be an
        %            integer > 0.
        %
        % @param[out] samples The array of samples.
    end

    methods (Access = public)
        function sampling_rate = getSamplingRate(obj)
        %%
        % @brief Get the sampling rate for this generator.
        %
        % @par Usage
        % sampling_rate = obj.getSamplingRate()
        %
        % @param[out] sampling_rate The sampling rate (in samples/sec).
            sampling_rate = obj.sampling_rate;
        end
    end
end