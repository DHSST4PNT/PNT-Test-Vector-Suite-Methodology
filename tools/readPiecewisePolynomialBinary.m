function piecewise_polynomial_struct = readPiecewisePolynomialBinary(filename)
%
%  Description:
%    This function will read a binary piecewise polynomial file.
%
%  Author:
%    Redacted
%
%  Usage:  
%    piecewise_polynomial_struct = readPiecewisePolynomialBinary(filename)
% 
%  Inputs               Description
%    filename           Input filename.                             [N/A]
%
%  Outputs              Description
%    piecewise_polynomial_struct Piecewise polynomial struct, same
%                       format as returned by spline().
%
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

% Constants.
MAGIC_WORD_BYTES = 1:4;
NUM_BREAKS_BYTES = 17:20;
BREAKS_START_BYTE = 21;
SIZEOF_DOUBLE = 8;
SIZEOF_UINT32 = 4;

%% Open, read, close file.
fid = fopen(filename, 'r');
if fid==-1
    error(['Could not open file: ' filename]);
end
all_data = uint8(fread(fid, inf, 'uint8')).';
fclose(fid);

% Check magic word.
magic_word = typecast(all_data(MAGIC_WORD_BYTES), 'uint32');
if ~strcmp('70537750',dec2hex(uint32(magic_word)))
    error('Invalid piecewise polynomial file, magic word did not match');
end

% Read number of breaks.
num_xrefs = typecast(all_data(NUM_BREAKS_BYTES), 'int32');
if (num_xrefs < 2)
    error('num_xrefs (%d) is less than 2', num_xrefs);
end

% Read breaks.
piecewise_polynomial_struct = struct;
raw_breaks_bytes = BREAKS_START_BYTE:(BREAKS_START_BYTE + ...
                                      SIZEOF_DOUBLE * num_xrefs - 1);
raw_breaks_data = all_data(raw_breaks_bytes);
raw_breaks_data = reshape(raw_breaks_data, SIZEOF_DOUBLE, []).';
piecewise_polynomial_struct.breaks = zeros(1, num_xrefs);
for break_idx = 1:num_xrefs % Cast to doubles.
    piecewise_polynomial_struct.breaks(break_idx) = ...
        typecast(raw_breaks_data(break_idx, :), 'double');
end

% Skip reading the address lookup table.
LOOKUP_TABLE_START_BYTE = BREAKS_START_BYTE + SIZEOF_DOUBLE * num_xrefs;

% Read each polynomial.
num_polynomials = num_xrefs - 1; % One less polynomial than breaks (fenceposts).
piecewise_polynomial_struct.coefs = zeros(num_polynomials, 1);
SPLINES_START_BYTE = LOOKUP_TABLE_START_BYTE + SIZEOF_UINT32 * num_polynomials;
cur_polynomial_start_byte = SPLINES_START_BYTE;
for polynomial_idx = 1:num_polynomials
    num_cur_polynomial_coeffs_bytes = ...
        cur_polynomial_start_byte:...
        (cur_polynomial_start_byte + SIZEOF_UINT32 - 1);
    num_cur_polynomial_ceoffs = ...
        typecast(all_data(num_cur_polynomial_coeffs_bytes), 'int32');
                                 
    % Extend the coefficients matrix if necessary. 
    if (num_cur_polynomial_ceoffs > size(piecewise_polynomial_struct.coefs, 2))
        num_new_cols = num_cur_polynomial_ceoffs - ...
                       size(piecewise_polynomial_struct.coefs, 2);
        extension = zeros(size(piecewise_polynomial_struct.coefs, 1), ...
                          num_new_cols);
        piecewise_polynomial_struct.coefs = ...
            [extension piecewise_polynomial_struct.coefs];
    end
    
    raw_cur_polynomial_coeffs_bytes = ...
        (cur_polynomial_start_byte + SIZEOF_UINT32) : ...
        (cur_polynomial_start_byte + SIZEOF_UINT32 + ...
         SIZEOF_DOUBLE * num_cur_polynomial_ceoffs - 1);
    raw_cur_polynomial_coeffs = all_data(raw_cur_polynomial_coeffs_bytes);
    raw_cur_polynomial_coeffs = ...
        reshape(raw_cur_polynomial_coeffs, SIZEOF_DOUBLE, []).';
    
    % Cast to doubles.
    cur_polynomial_coeffs = zeros(1, num_cur_polynomial_ceoffs);
    for coeff_idx = 1:num_cur_polynomial_ceoffs
        cur_polynomial_coeffs(coeff_idx) = ...
            typecast(raw_cur_polynomial_coeffs(coeff_idx, :), 'double');
    end
    
    piecewise_polynomial_struct.coefs(polynomial_idx, ...
                        (end - num_cur_polynomial_ceoffs + 1):(end)) = ...
        cur_polynomial_coeffs;
    
    cur_polynomial_start_byte = cur_polynomial_start_byte + SIZEOF_UINT32 + ...
                            num_cur_polynomial_ceoffs * SIZEOF_DOUBLE;
end

%% Fill out rest of MATLAB struct information
piecewise_polynomial_struct.form = 'pp';
piecewise_polynomial_struct.pieces = num_polynomials;
piecewise_polynomial_struct.order = size(piecewise_polynomial_struct.coefs, 2);
piecewise_polynomial_struct.dim = 1;


