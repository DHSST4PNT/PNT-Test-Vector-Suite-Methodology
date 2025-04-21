classdef (Sealed = true) CompositeSignalGenerator < handle
%%
% @brief A class for generating composite signals.
%
% This class contains one or more signal generators(SignalGenerator). It
% sums the signals from all the signal generators together after their 
% outputs have been interpolated to a common axis.
%
% @copyright Copyright &copy; 2013 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)

    properties (SetAccess = private)
        signal_generators; % Cell array of signal generators.
        % A map from the signal generator indices to their Frequency-Division
        % Multiple-Access (FDMA) frequencies (in Hz).
        signal_generator_fdma_offsets;
        % A map from the signal generator indices to the current FDMA carrier 
        % phase (in rad).
        signal_generator_fdma_carrier_phases;
        % Cell array of data buffers for each signal generator.
        signal_data_buffers;
        % Cell array of time axis buffers for each signal generator
        signal_time_axis_buffers;
        sampling_rate; % The sampling rate (in samples/sec).
        sampling_rate_high; % The high sampling rate (in samples/sec).
        sample_counter_hr; % The current sample (in terms of oversampling rate).
        ds_filter_b; % The downsampling FIR filter coefficients (see filter()).
        ds_filter_order; % The order of the downsampling FIR filter.
        ds_filter_state; % The downsampling filter state (see filter()).
        ds_filter_delay; % Group delay of downsampling filter in seconds.
        ds_filter_alpha; % The alpha parameter for downsampling filter design.
        oversample_ratio; % Oversampling ratio; must be a positive integer.
        using_oversampling; % True if using oversampling (ratio ~= 1).
    end
    
    methods (Access = public)
        function obj = CompositeSignalGenerator(sampling_rate, ...
                                                oversample_ratio, ...
                                                filter_order, ...
                                                filter_alpha)
        %%
        % @brief Create a composite signal generator instance.
        %
        % @par Usage
        % obj = CompositeSignalGenerator(sampling_rate)
        % obj = CompositeSignalGenerator(sampling_rate, oversample_ratio)
        % obj = CompositeSignalGenerator(sampling_rate, oversample_ratio, ...
        %                                filter_order)
        % obj = CompositeSignalGenerator(sampling_rate, oversample_ratio, ...
        %                                filter_order, filter_alpha)
        %
        % @param[in] sampling_rate The sampling rate to generate data at (in
        %            samples/sec).
        % @param[in] oversample_ratio The internal oversampling ratio.
        %            Internally, samples will be generated at
        %            <c>sampling_rate * oversampling_ratio</c>, low-pass
        %            filtered, and downsampled to the desired @c sampling_rate.
        %            Must be a positive integer. Default value is 4.
        % @param[in] filter_order The order of the downsampling FIR filter. If
        %            oversampling is being used (<c>oversample_ratio ~= 1</c>),
        %            then a low-pass FIR filter will be designed with this
        %            order and a normalized cutoff at
        %            <c>1.0 / oversample_ratio</c>. The oversampled composite
        %            signal will be filtered with this anti-aliasing filter
        %            before downsampling. The filter coefficients can be
        %            accessed via the read-only @c ds_filter_b member. Must be
        %            a positive integer. Default value is 60.
        % @param[in] filter_alpha The scalar value to use when designing the
        %            low-pass FIR downsampling filter. The filter will be
        %            designed as a call to
        %            <c>fir1(filter_order, filter_alpha / oversample_ratio)</c>.
        %            The @c filter_alpha must be a scalar in the range (0, 1].
        %            Default value is 1.0. Decreasing this value will reduce
        %            aliasing noise that gets folded in at the downsampling step
        %            but reducing it too much can filter out the desired signal.
        %            The ratio <c>filter_alpha / oversample_ratio</c> represents
        %            the normalized cutoff frequency, where a value of 1.0
        %            corresponds to the Nyquist rate. See the documentation for
        %            fir1() for more information.
        %
        % @param[out] obj The created instance.
            obj.sampling_rate = sampling_rate;
            validateattributes(obj.sampling_rate, {'numeric'}, ...
                               {'scalar', 'positive'});
            obj.signal_generators = {};
            obj.signal_data_buffers = {};
            obj.sample_counter_hr = uint64(0);
            if nargin == 1
                obj.oversample_ratio = 4;
                obj.ds_filter_order = 60;
                obj.ds_filter_alpha = 1;
            elseif nargin == 2
                obj.oversample_ratio = oversample_ratio;
                obj.ds_filter_order = 60;
                obj.ds_filter_alpha = 1;
            elseif nargin == 3
                obj.oversample_ratio = oversample_ratio;
                obj.ds_filter_order = filter_order;
                obj.ds_filter_alpha = 1;
            elseif nargin == 4
                obj.oversample_ratio = oversample_ratio;
                obj.ds_filter_order = filter_order;
                obj.ds_filter_alpha = filter_alpha;
            else
                error('Incorrect number of input arguments (%u).', nargin);
            end
            validateattributes(obj.oversample_ratio, {'numeric'}, ...
                               {'scalar', 'integer', 'positive'});
            obj.sampling_rate_high = obj.sampling_rate * obj.oversample_ratio;
            obj.using_oversampling = obj.oversample_ratio ~= 1;
            
            % Design downsampling filter.
            validateattributes(obj.ds_filter_order, {'numeric'}, ...
                               {'scalar', 'integer', 'positive'});
            validateattributes(obj.ds_filter_alpha, {'numeric'}, ...
                               {'scalar', '>', 0, '<=', 1});
            if obj.using_oversampling
                obj.ds_filter_b = fir1(obj.ds_filter_order, ...
                                       obj.ds_filter_alpha / ...
                                       obj.oversample_ratio);
                obj.ds_filter_state = zeros(obj.ds_filter_order, 1);
                obj.ds_filter_delay = mean(grpdelay(obj.ds_filter_b)) / ...
                                      (obj.oversample_ratio * obj.sampling_rate);
            end
            
            % Instantiate map object (double->double). This maps the signal
            % generator index to the FDMA offset (in Hz) for that signal
            % generator.
            obj.signal_generator_fdma_offsets = ...
                containers.Map('KeyType', 'double', 'ValueType', 'double');
            
            % Instantiate map object (double->double). This maps the signal
            % generator index to the current FDMA carrier phase (in rad).
            obj.signal_generator_fdma_carrier_phases = ...
                containers.Map('KeyType', 'double', 'ValueType', 'double');
        end
        
        function [time_vector, samples] = getSamples(obj, duration)
        %%
        % @brief Get data samples for a specified duration of time,
        %        including power, Doppler, and time dilation effects.
        %
        % @note
        % The output "duration" will be rounded down to the nearest sample
        % period, as only an integer number of samples can be returned.
        %
        % @parm Usage
        % [time_vector, samples] = obj.getSamples(duration)
        %
        % @param[in] obj The instance of the class.
        % @param[in] duration The length of time to generate samples for (in
        %            sec).
        %
        % @param[out] time_vector The true time associated with each sample
        %             returned in @c samples (in sec).
        % @param[out] samples The sampled output data (linear amplitude).
        
            % Determine common time axis.
            num_samples_hr = floor(duration * obj.sampling_rate_high);
            if num_samples_hr < 1
                error(['Number of samples is less than one. ' ...
                       '[num_samples = ' ...
                       num2str(num_samples_hr) ...
                       ', duration = ' num2str(duration)...
                       ', sampling_rate_high = ' ...
                       num2str(obj.sampling_rate_high) '.']);
            end
            time_vector_hr = ...
                double(obj.sample_counter_hr:(obj.sample_counter_hr + ...
                                              num_samples_hr - 1)).' / ...
                obj.sampling_rate_high;

            % Update sample counters.
            obj.sample_counter_hr = obj.sample_counter_hr + num_samples_hr;

            % Compute summation of all signals. Since signal data can be warped
            % due to time dilation, the time axes returned for each
            % SignalGenerator may be different. Before interpolating and adding
            % each signal into the composite output, ensure that the data
            % vectors for each signal generator cover the entire time output
            % (@c time_min, @c time_max).
            time_min = time_vector_hr(1);
            time_max = time_vector_hr(end);
            samples_hr = zeros(num_samples_hr, 1);
            for sig_idx = 1:numel(obj.signal_generators)
                
                % Trim off old, unneeded data from current buffer.
                remove_idx = obj.signal_time_axis_buffers{sig_idx} < time_min;
                obj.signal_time_axis_buffers{sig_idx}(remove_idx) = [];
                obj.signal_data_buffers{sig_idx}(remove_idx) = [];
                
                % Add samples until the signal time axis buffer covers at least
                % to the end of the true time axis.
                done_generating_cur_signal = ...
                    numel(obj.signal_time_axis_buffers{sig_idx}) > 0 && ...
                    obj.signal_time_axis_buffers{sig_idx}(end) >= time_max;
                while (~done_generating_cur_signal)
                    
                    % Add new data to buffers.
                    [new_times, new_samples, stream_ended] = ...
                        obj.signal_generators{sig_idx}.getSamples(duration);
                    if obj.using_oversampling
                        % If using oversampling subtract the filter delay from
                        % the sample times so that the output times correspond
                        % to the expected input observables times.
                        new_times = new_times - obj.ds_filter_delay;
                    end
                    obj.signal_time_axis_buffers{sig_idx} = ...
                        [obj.signal_time_axis_buffers{sig_idx}; new_times];
                    obj.signal_data_buffers{sig_idx} = ...
                        [obj.signal_data_buffers{sig_idx}; new_samples];
                    
                    % Check that the time axis is monotonically increasing;
                    % if it isn't, something is wrong and we may be waiting in
                    % this loop forever for the time to increase.
                    %
                    % This can happen, for example, if the user specifies a
                    % signal time spline (in SignalGenerator) that is not
                    % defined over the interval that is currently being
                    % generated.
                    if ~all(diff(obj.signal_time_axis_buffers{sig_idx}) > 0)
                        error(['Signal time axis is not monotonically ' ...
                               'increasing; exiting to prevent possible ' ...
                               'infinite loop. Consider checking the ' ...
                               'signal time spline for proper definition ' ...
                               'over the desired duration.']);
                    end
                    
                    % Check if enough data has been generated for current
                    % result.
                    done_generating_cur_signal = ...
                        stream_ended || ...
                        obj.signal_time_axis_buffers{sig_idx}(end) >= time_max;
                end
                
                % Interpolate current signal to common time axis.
                if obj.signal_generators{sig_idx}.use_neighbor_interp
                    cur_samples_hr = nonUniformResampleFast( ...
                        obj.signal_time_axis_buffers{sig_idx}, ...
                        obj.signal_data_buffers{sig_idx}, time_vector_hr);
                else
                    cur_samples_hr = interp1( ...
                        obj.signal_time_axis_buffers{sig_idx}, ...
                        obj.signal_data_buffers{sig_idx}, time_vector_hr, ...
                        'pchip');
                end
                
                % Apply FDMA offset.
                fdma_offset = obj.signal_generator_fdma_offsets(sig_idx);
                if (fdma_offset ~= 0)
                    cur_carrier_phase = ...
                        obj.signal_generator_fdma_carrier_phases(sig_idx);
                    t_rel = time_vector_hr - time_vector_hr(1);
                    carrier_phases = cur_carrier_phase + ...
                                     2 * pi * t_rel * fdma_offset;
                    cur_samples_hr = cur_samples_hr .* exp(1i * carrier_phases);
                    obj.signal_generator_fdma_carrier_phases(sig_idx) = ...
                        carrier_phases(end);
                end
                
                % Add current signal's samples to the running composite.
                samples_hr = samples_hr + cur_samples_hr;
            end
            
            % If using oversampling, apply the anti-aliasing filter to the
            % oversampled data, downsample and return. Otherwise just return
            % the time/samples as-is.
            if obj.using_oversampling
                % Anti-aliasing filter (before downsampling).
                [samples_hr_filt, obj.ds_filter_state] = ...
                    filter(obj.ds_filter_b, 1, samples_hr, obj.ds_filter_state);                
                % Downsample.
                time_vector = time_vector_hr(1:obj.oversample_ratio:end);
                samples = samples_hr_filt(1:obj.oversample_ratio:end);
            else
                time_vector = time_vector_hr;
                samples = samples_hr;
            end
        end

        function addSignalGenerator(obj, signal_generator, varargin)
        %%
        % @brief Add a signal generator to the set of signal generators.
        %
        % @par Usage
        % obj.addSignalGenerator(signal_generator)
        % obj.addSignalGenerator(signal_generator, fdma_offset)
        %
        % @param[in] obj The instance of the class.
        % @param[in] signal_generator An object that generates signal data; can
        %            be an instance of a SampleGenerator, 
        %            ReferenceSignalGenerator instance, or SignalGenerator.
        % @param[in] fdma_offset The Frequency-Division Multiple-Access (FDMA)
        %            offset for this signal generator (in Hz). Defaults to
        %            zero.
            if isa(signal_generator, 'SampleGenerator')
                new_signal_generator = ...
                    SignalGenerator(ReferenceSignalGenerator(signal_generator));
            elseif isa(signal_generator, 'ReferenceSignalGenerator')
                new_signal_generator = SignalGenerator(signal_generator);
            elseif isa(signal_generator, 'SignalGenerator') 
                new_signal_generator = signal_generator;
            else
                error(['signal_generator must an instance of a ' ...
                       'SampleGenerator, ReferenceSignalGenerator or a ' ...
                       'SignalGenerator.']);
            end
            obj.signal_generators{end + 1} = new_signal_generator;
            obj.signal_data_buffers{end + 1} = [];
            obj.signal_time_axis_buffers{end + 1} = [];
            
            % Store the FDMA offset for this signal generator.
            signal_generator_index = numel(obj.signal_generators);
            if nargin <= 2
                fdma_offset = 0;
            else
                fdma_offset = varargin{1};
            end
            validateattributes(fdma_offset, {'numeric'}, {'scalar'});
            obj.signal_generator_fdma_offsets(...
                signal_generator_index) = fdma_offset;
            obj.signal_generator_fdma_carrier_phases(...
                signal_generator_index) = 0;
        end
    end
end
