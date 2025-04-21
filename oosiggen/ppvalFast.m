function v = ppvalFast(pp, xx)
%%
% @brief A faster version of MATLAB's ppval() function for evaluating piecewise
%        polynomials.
%
% ppval() creates a histogram with histc() as part of its implementation, which
% can lead to very large memory allocations. This is a wrapper around a MEX
% function that makes use of a binary search to locate the appropriate bin
% (polynomial coefficient set).
%
% @note
% This is a MATLAB wrapper around a core MEX function, which must must be
% compiled with make.m. See the library documentation for more information
% about this process.
%
% @param[in] pp The piecewise polynomial struct, obtained via the spline() or
%            interp1() functions.
% @param[in] xx The x-axis locations to evaluate values at. Must be a column
%            vector or scalar.
%
% @param[out] v The values of the spline evaluted at the @c xx locations. Will
%             be the same size as @xx.
%
% @par Usage
% v = ppvalFast(pp, xx)
%
%
% @copyright Copyright &copy; 2013 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)

v = ppvalFastCore(pp.breaks, pp.coefs, xx);
