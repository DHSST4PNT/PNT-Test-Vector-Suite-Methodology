classdef (Sealed = true) ReferenceSignalGenerator < handle
%%
% @brief A class that generates signal samples, optionally modulated with data
%        symbols from a DataSymbolGenerator.
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
        sample_generator; % The sample generator.
        data_symbol_generator; % The data symbol generator (optional).
        use_data; % Flag; true if using a data symbol generator.
        sampling_rate; % The sampling rate of the output (in samples/sec).
        % If true, use last-neighbor interpolation when resampling this
        % generator's samples to another rate. Controlled by the member
        % SampleGenerator.
        use_neighbor_interp;
    end
    
    properties (Access = private)
        sample_index; % Zero-indexed sample pointer.
        segment_length; % The fixed segment length (in samples/chips).
        segment; % Current segment buffer.
    end
    
    methods (Access = public)
        function obj = ReferenceSignalGenerator(sample_generator, varargin)
        %%     
        % @brief Create a new instance of the signal generator.
        %
        % @par Usage
        % obj = ReferenceSignalGenerator(sample_generator)
        % obj = ReferenceSignalGenerator(sample_generator, 
        %                                data_symbol_generator) 
        %
        % @param[in] sample_generator An instance of the SampleGenerator class
        %            that generates data samples, such as BPSK chips, BOC
        %            subchips, noise samples or a sampled complex exponential.
        % @param[in] symbol_generator The data symbol generator. If not
        %            specified, data symbols will not be used.
        %
        % @param[out] obj The object that was created.
            if nargin == 1
                obj.use_data = false;
            elseif nargin == 2
                obj.use_data = true; 
                sym_gen = varargin{1};
                validateattributes(sym_gen, {'DataSymbolGenerator'}, {});
                obj.data_symbol_generator = sym_gen;
            else
                error('Incorrect number of input arguments.');
            end
                           
            validateattributes(sample_generator, {'SampleGenerator'}, {});    
            obj.sample_generator = sample_generator;
            obj.use_neighbor_interp = sample_generator.use_neighbor_interp;
            obj.sampling_rate = obj.sample_generator.sampling_rate;
            
            % Determine the segment size of the data generated internally.
            if obj.use_data
                % If using data, always generate one data symbols' worth of
                % data at a time.
                obj.segment_length = ...
                    round(obj.data_symbol_generator.symbol_period * ...
                          obj.sample_generator.sampling_rate);
            else
                % If not using data, choose 20 msec as a reasonable amount of
                % data to generate at once.
                obj.segment_length = ...
                    round(20e-3 * obj.sample_generator.sampling_rate);
            end
            if (obj.segment_length < 0)
                error('Computed a segment length of less than 1 sample.');
            end
            
            % Start at end so first request results in initialization of
            % segment (looks like the "last" buffer had been exhausted).
            obj.sample_index = obj.segment_length;     
        end

        function samples = getSamples(obj, duration)
        %%
        % @brief Get data samples for a specified duration of time.
        %
        % @note
        % The output "duration" will be rounded down to the nearest sample
        % period, as only an integer number of samples can be returned. The
        % public, read-only sampling_rate property can be used with the length
        % of the @c samples output to determine the true duration of the
        % returned data.
        %
        % @par Usage
        % samples = obj.getSamples(duration)
        %
        % @param[in] obj The instance of the class.
        % @param[in] duration The length of time to generate samples for (in
        %            sec).
        %
        % @param[out] samples The array of data samples.
            
            % Compute number of samples.
            num_samples = floor(duration * obj.sample_generator.sampling_rate);
            if (num_samples == 0)
                samples = [];
                return;
            end
            samples = zeros(num_samples, 1);
            
            % Generate output data. Do this by grabbing one segment at a time
            % and generating new segments as necessary to generate the full
            % requested output.
            samples_left_to_gen = num_samples;
            start_idx = 1;
            while (samples_left_to_gen > 0)
                
                % Generate a new segment if the previous one has been exhausted.
                if  obj.sample_index == obj.segment_length
                    obj.getNextSegment();
                    obj.sample_index = 0;
                end
                
                % Grab the next piece to put into the output buffer.
                samples_left_in_buffer = obj.segment_length - ...
                                         obj.sample_index;
                if (samples_left_to_gen <= samples_left_in_buffer) % Partial.
                    stop_idx = start_idx + samples_left_to_gen - 1;
                    samples(start_idx:stop_idx) = ...
                        obj.segment((obj.sample_index + 1) : ...
                                    (obj.sample_index + samples_left_to_gen));
                    obj.sample_index = obj.sample_index + ...
                                       samples_left_to_gen;
                    break;
                else % Grab full segment.
                    stop_idx = start_idx + samples_left_in_buffer - 1;
                    samples(start_idx:stop_idx) = ...
                        obj.segment((obj.sample_index + 1) : ...
                                    (obj.sample_index + ...
                                     samples_left_in_buffer));
                                 
                    samples_left_to_gen = samples_left_to_gen - ...
                                          samples_left_in_buffer;
                                      
                    % Will advance sample_index to segment_length - 1, which
                    % will force a refresh of the current sample buffer at the
                    % next iteration of this while loop.
                    obj.sample_index = obj.sample_index + ...
                                       samples_left_in_buffer;
                    start_idx = stop_idx + 1;
                end
            end
        end
    end
    
    methods (Access = private)
        function getNextSegment(obj)
        %%
        % @brief Populate the next segment of data.
        %
        % The amount of data generated at each call is set by
        % <c>obj.segment_length</c>, and populates <c>obj.segment</c>. If
        % a data symbol generator is present, the data is modulated by the
        % next data symbol.
        %
        % @param[in] obj The class instance.
            obj.segment = obj.sample_generator.getSamples(obj.segment_length);
            if obj.use_data
                obj.segment = obj.segment * ...
                              obj.data_symbol_generator.getNextSymbol();
            end
        end
    
    end
end