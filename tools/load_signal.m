function signal = load_signal(signal_def, simenv_path)
    % Load the peicewise polynomial components of a signal definition.
    %
    % Parameters:
    % signal_def: A struct containing a scenario signal definition, which
    %     includes file names for piecewise polynomial fields.
    % simenv_path: The path to the directory which contains the needed
    %     piecewise polynomial files.
    %
    % Returns: An equivalent struct to `signal_def`, but with the piecewise
    %     polynomial file names replaced with loaded piecewise polynomials.
    %     Other fields are passed through verbatim.

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
	
    verbatim_fields = { ...
        'comment', 'system', 'signal_params', 'has_data', 'fc', ...
        'carrier_phase', 'tx_id', 'signal_options'};
    bin_file_fields = { ...
        'autocorr_function', 'pseudorange_profile', 'doppler_profile', ...
        'signal_power_profile', 'data_symbols_real', 'data_symbols_imag', ...
        'noise_power_density_profile'};

    signal = struct();
    for i=1:numel(verbatim_fields)
        verbatim_field = verbatim_fields{i};
        signal.(verbatim_field) = signal_def.(verbatim_field);
    end
    for i=1:numel(bin_file_fields)
        bin_file_field = bin_file_fields{i};
        piecewise = readPiecewisePolynomialBinary( ...
            [simenv_path, '/', signal_def.(bin_file_field)]);
        signal.(bin_file_field) = piecewise;
    end
end
