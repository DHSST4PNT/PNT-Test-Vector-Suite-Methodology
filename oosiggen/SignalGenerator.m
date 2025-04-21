classdef (Sealed = true) SignalGenerator < handle
%%
% @brief A class for generating signals with power, Doppler, and time
%        dilation effects.
%
% This class contains a ReferenceSignalGenerator, which generates
% data-modulated chipping sequences (or subchip sequences, in the case of a
% binary offset carrier [BOC] signal).
%
% Power, Doppler, and time dilation effects can then be optionally be
% applied. If no power, Doppler, or time dilation profiles are specified, 
% this class acts as a pass-through for the internal ReferenceSignalGenerator.
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
        reference_signal_generator; % The reference signal generator.
        carrier_phase; % The carrier phase (in rad).
        power_spline; % The power profile vs time (as linear power vs sec).
        doppler_spline; % The Doppler profile vs time (in Hz vs sec).
        % The signal time profile vs true time (in sec vs sec).
        signal_time_spline;
        use_power_profile; % Flag, true if using power profile.
        use_doppler_profile; % Flag, true if using Doppler profile.
        use_signal_time_profile; % Flag, true if using time dilation profile.
        signal_time; % The current reference signal time (in sec).
        % If true, use last-neighbor interpolation when resampling this
        % generator's samples to another rate. Controlled by the member 
        % ReferenceSignalGenerator.
        use_neighbor_interp;
    end
    
    methods (Access = public)
        function obj = SignalGenerator(reference_signal_generator, ...
                                       power_spline, doppler_spline, ...
                                       initial_carrier_phase, ...
                                       signal_time_spline)
        %%
        % @brief Create a signal generator instance.
        %
        % A SignalGenerator is used to generate signal data. A
        % ReferenceSignalGenerator is used to generate sample/subchip/chip
        % sequences that have optionally been modulated data symbols.
        % The SignalGenerator then takes that sequence and optionally
        % applies amplitude/power scaling, Doppler shifts, and time dilation.
        %
        % The power, Doppler, and time dilation profiles are specified vs
        % true time. These profiles must be specified as piecewise
        % polynomials, in the format that is returned by the MATLAB 
        % spline() function (or interp1() by specifying the 'spline' 
        % interpolation method). They are only verified to the point that 
        % the correct struct fields are present, and then are directly 
        % passed to ppval() for evaluation.
        %
        % The convertToSignalTimeSpline() utility can be used to transform
        % a pseudorange spline (as m vs true time in sec) to a signal time
        % spline (as true time in sec vs signal time in sec).
        %
        % @note
        % The Doppler profile is only used to shift the signal frequency;
        % it has no effect on the signal's time dilation. If time dilation
        % is desired, a signal time spline must be specified separately
        % (due to code/carrier divergence, a Doppler profile does not
        % necessarily map 1:1 to time dilation).
        %
        % @par Usage
        % obj = SignalGenerator(reference_signal_generator)
        % obj = SignalGenerator(reference_signal_generator, power_spline)
        % obj = SignalGenerator(reference_signal_generator, power_spline,
        %                       doppler_spline)
        % obj = SignalGenerator(reference_signal_generator, power_spline,
        %                       doppler_spline, initial_carrier_phase)
        % obj = SignalGenerator(reference_signal_generator, power_spline,
        %                       doppler_spline, initial_carrier_phase,
        %                       signal_time_spline)
        %
        % @param[in] reference_signal_generator An instance of a
        %            ReferenceSignalGenerator that generates the code sequences
        %            (with data symbols, if applicable).
        % @param[in] power_spline A spline struct representing the linear
        %            signal power vs true time (in linear units vs sec). If
        %            not specified, the signal amplitude is not modulated.
        % @param[in] doppler_spline A spline struct representing the signal
        %            Doppler vs true time (in Hz vs sec). If not specified,
        %            the signal Doppler is not modified.
        % @param[in] initial_carrier_phase The initial carrier phase (in 
        %            rad). If not specified, the phase defaults to 0.
        % @param[in] signal_time_spline A spline struct representing the
        %            true time vs signal time (in sec vs sec). If not 
        %            specified, the signal time is not warped/dilated.
        %
        % @param[out] obj The created instance.
            obj.signal_time = 0;
            obj.carrier_phase = 0;
            obj.use_power_profile = false;
            obj.use_doppler_profile = false;
            obj.use_signal_time_profile = false;
            obj.reference_signal_generator = reference_signal_generator;
            obj.use_neighbor_interp = ...
                reference_signal_generator.use_neighbor_interp;
            if nargin == 1
            elseif nargin == 2
                obj.power_spline = power_spline;
                obj.use_power_profile = true;
            elseif nargin == 3
                obj.power_spline = power_spline;
                obj.use_power_profile = true;
                
                obj.doppler_spline = doppler_spline;
                obj.use_doppler_profile = true;
            elseif nargin == 4
                obj.power_spline = power_spline;
                obj.use_power_profile = true;
                
                obj.doppler_spline = doppler_spline;
                obj.use_doppler_profile = true;
                obj.carrier_phase = initial_carrier_phase;
            elseif nargin == 5
                obj.power_spline = power_spline;
                obj.use_power_profile = true;
                
                obj.doppler_spline = doppler_spline;
                obj.use_doppler_profile = true;
                obj.carrier_phase = initial_carrier_phase;
                
                obj.signal_time_spline = signal_time_spline;
                obj.use_signal_time_profile = true;
            else
                error('Incorrect number of input arguments.');
            end
            
            validateattributes(obj.reference_signal_generator, ...
                               {'ReferenceSignalGenerator'}, {});
            validateattributes(obj.carrier_phase, ...
                               {'numeric'}, {'scalar'});

            if obj.use_power_profile
                validateattributes(obj.power_spline, ...
                                   {'struct'}, {'scalar'});
                if ~SignalGenerator.validateSplineStructFields(obj.power_spline)
                    error('Error validating power spline.');
                end
            end
            
            if obj.use_doppler_profile
                validateattributes(obj.doppler_spline, ...
                                   {'struct'}, {'scalar'});
                if ~SignalGenerator.validateSplineStructFields(...
                       obj.doppler_spline)
                    error('Error validating Doppler spline.');
                end
            end
            
            if obj.use_signal_time_profile
                validateattributes(obj.signal_time_spline, ...
                                   {'struct'}, {'scalar'});
                if ~SignalGenerator.validateSplineStructFields(...
                    obj.doppler_spline)
                    error('Error validating time dilation spline.');
                end
            end
        end

        function [time_vector, samples, stream_ended] = getSamples(obj, duration)
        %%
        % @brief Get data samples for a specified duration of time,
        %        including power, Doppler and time dilation effects.
        %
        % @note
        % The output "duration" will be rounded down to the nearest chip
        % period, as only an integer number of samples can be returned.
        %
        % @par Usage
        % [time_vector, samples, stream_ended] = obj.getSamples(duration)
        %
        % @param[in] obj The instance of the class.
        % @param[in] duration The length of time to generate samples for (in
        %            signal time, sec).
        %
        % @param[out] time_vector The true time associated with each sample
        %             returned in @c samples (in sec). Note that the input
        %             @c duration is in terms of signal time, but due to
        %             time dilation this output vector may span less or more
        %             time than the input @c duration.
        % @param[out] samples The sampled output data (complex linear
        %             amplitude).
        % @param[out] stream_ended Set to @c true if no further samples can be
        %             generated. This can occur if using a signal time profile
        %             and the generated sample stream has exceeded the bounds
        %             over which the profile is defined.
            samples = obj.reference_signal_generator.getSamples(duration);
            ref_sample_period = ...
                1 / obj.reference_signal_generator.sampling_rate;
            reference_signal_duration = numel(samples) * ref_sample_period;
            
            % Get the signal time vector, transform via time dilation if
            % necessary to obtain true time vector.
            signal_time_vector = obj.signal_time + ...
                                 ref_sample_period * (0:(numel(samples) - 1)).';
            if (obj.use_signal_time_profile)
                % Truncate the reported samples to only samples occurring within
                % the definition of the signal time spline.
                idx = signal_time_vector < obj.signal_time_spline.breaks(end);
                stream_ended = any(~idx);
                signal_time_vector = signal_time_vector(idx);
                samples = samples(idx);
                reference_signal_duration = numel(samples) * ref_sample_period;
                
                time_vector = ppvalFast(obj.signal_time_spline, ...
                                        signal_time_vector);
            else
                time_vector = signal_time_vector;
                stream_ended = false;
            end

            if (isempty(samples))
                return;
            end
            
            % Update internal reference signal time.
            obj.signal_time = obj.signal_time + reference_signal_duration;
            
            % Apply amplitude modulation specified by power spline.
            if (obj.use_power_profile)
                samples = samples .* ...
                          sqrt(ppvalFast(obj.power_spline, time_vector));
            end
            
            % Apply Doppler shift.
            if (obj.use_doppler_profile)
                doppler = ppvalFast(obj.doppler_spline, time_vector);
                if(numel(time_vector) > 1)
                    carrier_phases = ...
                        obj.carrier_phase + ...
                        2 * pi * cumtrapz(time_vector, doppler);
                else
                    carrier_phases = ...
                        obj.carrier_phase + ...
                        2 * pi * time_vector * doppler;
                end
                samples = samples .* exp(1i * carrier_phases);
                obj.carrier_phase = mod(carrier_phases(end), 2 * pi);
            end
        end
    end
    
    methods (Static, Access = private)
        function flag = validateSplineStructFields(pp)
        %%
        % @brief Validate a spline struct by checking for the fields present.
        %
        % This function checks that an input struct contains the fields
        % populated by the spline() function (or interp1() using the spline
        % method).
        %
        % @par Usage
        % flag = validateSplineStructFields(pp)
        %
        % @note
        % This function only checks for the existence of several fields in the
        % input struct; it does not validate those fields' values.
        %
        % @param[in] pp The spline struct.
        %
        % @param[out] flag Returns true if @c pp validated.
            if ~isstruct(pp)
                flag = false;
                return;
            end
            flag = true;
            flag = flag && isfield(pp, 'breaks');
            flag = flag && isfield(pp, 'coefs');
            flag = flag && isfield(pp, 'pieces');
            flag = flag && isfield(pp, 'order');
            flag = flag && isfield(pp, 'dim');
        end
    end
end
