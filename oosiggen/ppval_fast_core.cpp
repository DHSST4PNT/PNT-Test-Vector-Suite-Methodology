/**************************************************************************//**
 * @brief      Faster C++ implementation of MATLAB's ppval() function.
 *
 * @author     
 *
 * @date       Created 2013/6/7
 *
 * @file
 * @copyright  Copyright &copy; 2013 The %MITRE Corporation
 * @par Notice
 * This software was produced for the U.S. Government under Contract No.
 * FA8702-13-C-0001, and is subject to the Rights in Noncommercial Computer
 * Software and Noncommercial Computer Software Documentation Clause
 * (DFARS) 252.227-7014 (JUN 1995)
 *****************************************************************************/
#include <algorithm> // For lower_bound().

#include "mex.h"

/**
 * @brief The standard MEX gateway function.
 *
 * @par MATLAB Usage
 * v = ppvalFastCore(breaks, coefs, xx)
 *
 * @par MATLAB Arguments
 * - <c>prhs[0]</c>: The input vector, @c breaks, which represents the x-axis
 *   fencepost locations defining the piecewise polynomial. Must be a real
 *   column vector of doubles, of length @c N.
 * - <c>prhs[1]</c>: The input matrix, @c coefs, which represents the sets of
 *   polynomial coefficients for each bin (between successive fenceposts in
 *   @c breaks). The dimensions are (@c N - 1) x @c O, where @c O is the order
 *   of the polynomials.
 * - <c>prhs[2]</c>: The input vector, @c xx, which represents the desired
 *   x-axis locations to evaluate the piecewise polynomial at.
 *
 * - <c>plhs[0]</c>: The output vector, @c v, which contains the values of the
 *   piecewise polynomial (defined by @c breaks and @x coefs) evaluated at the
 *   desired x-axis locations (@c xx). This will be the same size as @c xx.
 *
 * @param nlhs The number of left-hand-side arguments.
 * @param plhs The left-hand-side arguments.
 * @param nrhs The number of right-hand-side arguments.
 * @param prhs The right-hand-side arguments.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    // Input argument checks.
    if (nrhs != 3)
    {
        mexErrMsgTxt("Incorrect number of input arguments (three required).");
    }

    const size_t num_breaks = mxGetN(prhs[0]);
    if (prhs[0] == NULL || !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
        (mxGetNumberOfElements(prhs[0]) != num_breaks))
    {
        mexErrMsgTxt("breaks must be a real row array of doubles.");
    }

    const size_t num_polynomials = mxGetM(prhs[1]);
    const size_t order = mxGetN(prhs[1]);
    if (prhs[1] == NULL || !mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) ||
        (mxGetNumberOfElements(prhs[1]) != num_polynomials * order))
    {
        mexErrMsgTxt("coefs must be a real matrix of doubles.");
    }

    if (num_polynomials != num_breaks - 1)
    {
        mexErrMsgTxt("Number of polynomials is not consistent with number "
                     "of breaks.");
    }

    const size_t num_values = mxGetM(prhs[2]);
    if (prhs[2] == NULL || !mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) ||
        (mxGetNumberOfElements(prhs[2]) != num_values))
    {
        mexErrMsgTxt("xx must be a real column array of doubles.");
    }

    // Create pointers to input data.
    double *breaks = static_cast<double*>(mxGetPr(prhs[0]));
    double *coefs = static_cast<double*>(mxGetPr(prhs[1]));
    double *xx = static_cast<double*>(mxGetPr(prhs[2]));

    // Allocate output matrix, get real/imag pointers.
    plhs[0] = mxCreateDoubleMatrix(static_cast<mwSize>(num_values), 1, mxREAL);
    if (plhs[0] == NULL)
    {
        mexErrMsgTxt("Could not allocate output array.");
    }
    double *v = static_cast<double*>(mxGetPr(plhs[0]));

    // Evaluate each input value.
    for (size_t out_idx = 0; out_idx < num_values; ++out_idx)
    {
        const double x = xx[out_idx];

        // Find the correct bin using binary search algorithm.
        size_t lookup_idx;
        if (x <= breaks[0])
        {
            // Value is before first bin, so use the first bin.
            lookup_idx = 0;
        }
        else if (x > breaks[num_breaks - 1])
        {
            // Value is after last bin, so use last bin.
            lookup_idx = num_breaks - 1;
        }
        else
        {
            double *it = std::lower_bound(&breaks[0], &breaks[num_breaks], x);
            lookup_idx = it - &breaks[0] - 1;
        }

        // Evaluate polynomial.
        const double delta_x = x - breaks[lookup_idx];
        v[out_idx] = coefs[lookup_idx];
        for (size_t coef_idx = 1; coef_idx < order; ++coef_idx)
        {
            v[out_idx] = delta_x * v[out_idx] +
                         coefs[lookup_idx + coef_idx * num_polynomials];
        }
    }
}

