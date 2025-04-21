function generate_iq(scenario_file, output_dir, output_name, desired_samp_rate, run_seconds)
    % Generate baseband samples from a set of scenario splines.
    %
    % Parameters:
    % scenario_file: Path to a `scenario.json` file.
    % output_dir: Path to a directory which will contain the IQ file and metadata.
    % output_name: IQ file and metadata will be named output_name.iq and output_name.xml
    % desired_samp_rate: Desired sample rate in samples / sec.  System will warn if 
    %     this is below recommended rate based on the signals being generated.
    % run_seconds: Number of seconds of signal data to produce. Requesting more
    %     signal data than is present in the provided simenv will cause
    %     oosiggen to crash.
	
	% NOTICE
	% The Homeland Security Act of 2002 (Section 305 of PL 107-296, as codified in 6 U.S.C. 185),
	% herein referred to as the “Act,” authorizes the Secretary of the U.S. Department of 
	% Homeland Security (DHS), acting through the DHS Under Secretary for Science and Technology, 
	% to establish one or more federally funded research and development centers (FFRDCs) 
	% to provide independent analysis of homeland security issues. MITRE Corporation operates 
	% the Homeland Security Systems Engineering and Development Institute (HSSEDI) as an FFRDC 
	% for DHS S&T under contract 70RSAT20D00000001. 

	% The HSSEDI FFRDC provides the government with the necessary systems engineering and 
	% development expertise to conduct complex acquisition planning and development; concept 
	% exploration, experimentation and evaluation; information technology, communications 
	% and cyber security processes, standards, methodologies and protocols; systems 
	% architecture and integration; quality and performance review, best practices and 
	% performance measures and metrics; and independent test and evaluation activities. 
	% The HSSEDI FFRDC also works with and supports other federal, state, local, tribal, 
	% public and private sector organizations that make up the homeland security enterprise. 
	% The HSSEDI FFRDC’s research is undertaken by mutual consent with DHS and is 
	% organized as a set of discrete tasks. This report presents the results of research 
	% and analysis conducted under:

	% Task Order 70RSAT20FR0000062
	% DHS S&T Next Generation Resilient PNT
	% The results presented in this report do not necessarily reflect official DHS opinion or policy. 

	% Approved for public release, Case Number 23-4096 / 70RSAT23FR-067-13

    validateattributes(scenario_file, {'char', 'string'}, {'scalartext'});
    validateattributes(output_dir, {'char', 'string'}, {'scalartext'});
    validateattributes(output_name, {'char', 'string'}, {'scalartext'});
    validateattributes(desired_samp_rate, {'numeric'}, {'scalar'});
    validateattributes(run_seconds, {'numeric'}, {'scalar'});

    CHUNK_SIZE = 0.05;
    FIXED_POINT = true;
    FULL_SCALE_POWER_DBW = -115.0; % Only used for fixed point

    tic;
    restore_core_value = maxNumCompThreads('automatic');

    [local_dir, ~, ~] = fileparts(mfilename('fullpath'));
    addpath([local_dir, filesep, 'oosiggen']);
    addpath([local_dir, filesep, 'oosiggen', filesep, 'gps']);
    addpath([local_dir, filesep, 'oosiggen', filesep, 'galileo']);
    addpath([local_dir, filesep, 'tools']);

    [simenv_path, ~, ~] = fileparts(scenario_file);
    fprintf('Loading path [%s]\n', scenario_file);
    scenario_def = jsondecode(fileread(scenario_file));

    signals_filename = scenario_def.antennas.signals;
    signals_def = jsondecode(fileread([simenv_path, filesep, signals_filename]));
    if ~iscell(signals_def)
        signals_def = num2cell(signals_def);
    end

    sig_gen_v = {};
    composite_sample_rate = 0.0;
    for i = 1:numel(signals_def)
        signal = signals_def{i};
        [sig_gen, sample_rate] = make_sig_gen(signal, simenv_path);
        composite_sample_rate = max(composite_sample_rate, sample_rate);
        sig_gen_v = [sig_gen_v, sig_gen];
    end
    if desired_samp_rate < composite_sample_rate
        reply = input(sprintf(['Warning: desired sample rate is lower '...
            'than recommended rate of %f sps. Use recommended rate? (Y)/N:  '],...
            composite_sample_rate), 's');
        if strcmpi('N', reply)
            composite_sample_rate = desired_samp_rate;
        end
    else
        composite_sample_rate = desired_samp_rate;
    end

    fprintf('Setting sample rate to [%f] sps.\n', composite_sample_rate);
    if composite_sample_rate <= 0.0
        error('Error: Sample rate must be strictly positive.\n');
    end

    comp_sig_gen = CompositeSignalGenerator(composite_sample_rate);
    for i=1:numel(sig_gen_v)
        comp_sig_gen.addSignalGenerator(sig_gen_v{i});
    end

    noise_ppoly = readPiecewisePolynomialBinary( ...
        [simenv_path, filesep , scenario_def.default_noise_density_profile]);

    fprintf('Creating output directory and metadata...\n');
    mkdir(output_dir);
    output_filename = [output_name '.iq'];
    output_file = [output_dir, filesep, output_filename];
    metadata_file = [output_dir, filesep, output_name '.xml'];


    if FIXED_POINT
        scale_factor = (2^15 - 1) / 10^(FULL_SCALE_POWER_DBW/20);
        out_dtype_name = 'int16';
        out_dtype = @int16;
        make_ion_xml(output_filename, sprintf('%f', composite_sample_rate),...
            'int16', metadata_file);
    else
        scale_factor = 1.0;
        out_dtype_name = 'single';
        out_dtype = @single;
        make_ion_xml(output_filename, sprintf('%f', composite_sample_rate),...
            'float', metadata_file);
    end
    chunks_per_second = round(1 ./ CHUNK_SIZE);
    chunks_per_minute = round(60 ./ CHUNK_SIZE);
    minute = 0;
    t = 0;
    i = 0;
    fid = fopen(output_file, 'w');
    fprintf('Writing to "%s"...\n0', output_file);
    while t < run_seconds
        i = i + 1;
        if mod(i, chunks_per_second) == 0
            fprintf('.')
            if mod(i, chunks_per_minute) == 0
                minute = minute + 1;
                fprintf('\n%d', minute);
            end
        end
        [time_vector, data] = comp_sig_gen.getSamples(CHUNK_SIZE);
        n_samples = numel(data);
        noise_power_v = ppval(noise_ppoly, time_vector);
        noise_std_v = sqrt(noise_power_v .* (composite_sample_rate / 2));
        noise_buffer = noise_std_v .* ...
            (randn(n_samples, 1) + 1j * randn(n_samples, 1));
        data = data + noise_buffer;
        t = time_vector(end);
        data_iq = zeros(1, 2*n_samples, out_dtype_name);
        data = data * scale_factor;
        data_iq(1:2:end) = out_dtype(real(data));
        data_iq(2:2:end) = out_dtype(imag(data));
        fwrite(fid, data_iq, out_dtype_name);
    end
    fprintf('done.\n');
    fclose(fid);

    maxNumCompThreads(restore_core_value);
    toc

end
