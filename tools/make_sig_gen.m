function [sig_gen_v, sample_rate] = make_sig_gen(signal_def, simenv_path)
    % Make an OOsiggen signal generator given a scenario signal definition.
    %
    % Parameters:
    % signal_def: Scenario signal definition struct (including file names for
    %     the piecewise polynomial fields).
    % simenv_path: Path to the enclising directory for the scenario.
    %
    % Returns:
    % sig_gen_v: A cell array of signal generators. The length of the cell
    %     array will be zero if the given signal definition is not supported.
    %     The length will be greater than one for signals which have multiple
    %     components (such as a pilot and data channel).
    % sample_rate: A recommended minimum sampling rate for this signal.

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

    if strcmp(signal_def.system, 'GPS') && strcmp(signal_def.name, 'L1CA')
        has_data_channel = true;
        has_pilot_channel = false;
        data_codegen_func = @GPSCACodeGenerator;
        prn_field_name = 'prn';
        sample_rate = 4.0e6;
    elseif strcmp(signal_def.system, 'Galileo') && strcmp(signal_def.name, 'E1OS')
        % note that the E1OS signal generator produces only a BOC(1,1) signal and does not contain
        % the CBOC component
        has_data_channel = true;
        has_pilot_channel = true;
        data_codegen_func = @(prn) GalileoE1OSCodeGenerator(prn, 'b');
        pilot_codegen_func = @(prn) GalileoE1OSCodeGenerator(prn, 'c');
        prn_field_name = 'prn';
        sample_rate = 8.0e6;
    else
        % System and/or signal not supported
        sig_gen_v = [];
        sample_rate = 0;
        warning('Unsupported signal or system found in %s; omitting.\n', simenv_path)
        return
    end

    signal_loaded = load_signal(signal_def, simenv_path);
    data_symbols = ( ...
        signal_loaded.data_symbols_real.coefs + ...
        signal_loaded.data_symbols_imag.coefs .* 1j);
    data_rate = signal_loaded.signal_params.data_rate;
    data_period = 1 ./ data_rate;
    symbol_gen = FixedSetSymbolGenerator(data_period, data_symbols);
    time_spline = convertToSignalTimeSpline(signal_loaded.pseudorange_profile);

    prn = signal_loaded.signal_params.(prn_field_name);
    sig_gen_v = {};

    if has_data_channel
        data_codegen = data_codegen_func(prn);
        data_ref_gen = ReferenceSignalGenerator(data_codegen, symbol_gen);
        data_sig_gen = SignalGenerator( ...
            data_ref_gen, signal_loaded.signal_power_profile, ...
            signal_loaded.doppler_profile, signal_loaded.carrier_phase, ...
            time_spline);
        sig_gen_v{end + 1} = data_sig_gen;
    end
    if has_pilot_channel
        pilot_codegen = pilot_codegen_func(prn);
        pilot_ref_gen = ReferenceSignalGenerator(pilot_codegen);
        pilot_sig_gen = SignalGenerator( ...
            pilot_ref_gen, signal_loaded.signal_power_profile, ...
            signal_loaded.doppler_profile, signal_loaded.carrier_phase, ...
            time_spline);
        sig_gen_v{end + 1} = pilot_sig_gen;
    end
end
