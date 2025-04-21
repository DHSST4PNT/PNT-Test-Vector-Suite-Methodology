%%
% @brief Performs nearest-lower-neighbor interpolation over non-uniformly spaced
%        input and output grids.
%
% @note
% All inputs must be column vectors.
%
% @note
% This is a MATLAB stub to provide "help" support; this function is implemented
% as a MEX function that must be compiled with make.m. See the library
% documentation for more information about this process.
%
% @par Usage
% y_i = nonUniformResampleFast(x, y, x_i)
%
% @param[in] x The x-axis of the source data vector. Must be a real column
%            vector.
% @param[in] y The source data vector. Must be a real or complex column vector.
% @param[in] x_i The x-axis of the desired resampled data. Must be a real
%            column vector.
%
% @param[out] y_i The resampled data vector, where the data in @c y has been
%             sampled at the x-axis points defined by @c x_i.
%
% @par Example
% x = [0 3 7 16 24]';
% y = (50:54)';
% x_i = (0:5:25)';
% nonUniformResampleFast(x, y, x_i) = [50 51 52 52 53 54]
%
%
% @copyright Copyright &copy; 2013 The %MITRE Corporation
%
% @par Notice
% This software was produced for the U.S. Government under Contract No. 
% FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer 
% Software and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)