function signal_time_spline = convertToSignalTimeSpline(pseudorange_spline)
%%
% @brief Convert a pseudorange spline to a signal time spline.
%
% True time = t
% Pseudorange profile, in m as a function of true time = p(t)
% Speed of light = C (299792458 m/s)
% Signal time = ts
%
% p(t) = C * (t - ts)
% =>
% ts = t - p(t) / C
%
% The output spline represents true time as a function of signal time:
% t(st)
%
% @par Usage
% signal_time_spline = convertToSignalTimeSpline(pseudorange_spline)
%
% @param[in] pseudorange_spline The pseudorange spline (as m vs true time in
%            sec).
%
% @param[out] signal_time_spline The output spline, which expresses true time 
%             as a function of signal time (in sec vs sec).
%
%
% @copyright Copyright &copy; 2013 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)

C = 299792458;
MIN_TIME_RESOLUTION = 0.1;
breaks = pseudorange_spline.breaks;
existing_region_widths = diff(breaks);

% Generate sample points, which should at a minimum match the density of the
% fencepost points in the pseudorange spline, but may need to be supplemented
% if the pseudorange spline has wide regions
if max(existing_region_widths) <= MIN_TIME_RESOLUTION
    % Breaks already meet or exceed the desired density everywhere
    true_time = breaks;
else
    linear_sample = breaks(1):MIN_TIME_RESOLUTION:breaks(end);
    if min(existing_region_widths) >= MIN_TIME_RESOLUTION
        % All breaks are too wide, so resample the whole thing
        true_time = linear_sample;
        if true_time(end) ~= breaks(end) % Ensure final value is not dropped
            true_time(end + 1) = breaks(end);
        end
    else
        % Hybrid approach: include both linear samples and fenceposts
        true_time = sort(unique([breaks, linear_sample]));
    end
end
signal_time = true_time - ppval(pseudorange_spline, true_time) / C;

% Note that this spline inverts `X` and `Y` relative to the input (it is
% effectively a polynomial inversion). This is why the conversion from
% pseudorange to time cannot be done analytically, thus requiring this sampling
% and numeric re-generation of the spline.
signal_time_spline = spline(signal_time, true_time);
