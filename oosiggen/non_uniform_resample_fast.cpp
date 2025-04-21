/**************************************************************************//**
 * @brief      Non-uniform resampling algorithm.
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
#include "mex.h"

/**
 * @brief The standard MEX gateway function.
 *
 * @par MATLAB Usage
 * y_i = nonUniformResampleFast(x, y, x_i)
 *
 * @par MATLAB Arguments
 * - <c>prhs[0]</c>: The input vector, @c x, which represents the reference
 *   x-axis locations. Must be a real column vector of doubles.
 * - <c>prhs[1]</c>: The input vector, @c y, which represents the reference
 *   y-axis values. Must be a real or complex column vector of doubles.
 * - <c>prhs[2]</c>: The input vector, <c>x_i</c>, which represents the desired
 *   x-axis locations to resample the reference function at. Must be a real
 *   column vector of doubles.
 *
 * - <c>plhs[0]</c>: The output vector, <c>y_i</c>, which represents the
 *   reference function resampled at the desired locations (<c>x_i</c>). This
 *   will be the same size as <c>x_i</c>.
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

    const size_t x_length = mxGetM(prhs[0]);
    if (prhs[0] == NULL || !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
        (mxGetNumberOfElements(prhs[0]) != x_length))
    {
        mexErrMsgTxt("x must be a real column array of doubles.");
    }

    const size_t y_length = mxGetM(prhs[1]);
    if (prhs[1] == NULL || !mxIsDouble(prhs[1]) ||
        (mxGetNumberOfElements(prhs[1]) != y_length))
    {
        mexErrMsgTxt("y must be a column array of doubles.");
    }
    if (x_length != y_length)
    {
        mexPrintf("x_length = %u.\n", x_length);
        mexPrintf("y_length = %u.\n", y_length);
        mexErrMsgTxt("x length does not match y length.");
    }
    const bool is_complex = mxIsComplex(prhs[1]);

    const size_t xi_length = mxGetM(prhs[2]);
    if (prhs[2] == NULL || !mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) ||
        (mxGetNumberOfElements(prhs[2]) != xi_length))
    {
        mexErrMsgTxt("xi must be a real column array of doubles.");
    }

    // Create pointers to input data.
    double *x = static_cast<double*>(mxGetPr(prhs[0]));
    double *y_r = static_cast<double*>(mxGetPr(prhs[1]));
    double *y_i = NULL;
    if (is_complex)
    {
        y_i = static_cast<double*>(mxGetPi(prhs[1]));
    }
    
    else 
    {
        y_i = (double*)mxMalloc(x_length * sizeof(double));
    }
    double *xi = static_cast<double*>(mxGetPr(prhs[2]));

    // Allocate output matrix, get real/imag pointers.
    plhs[0] = mxCreateDoubleMatrix(static_cast<mwSize>(xi_length), 1,
                                   is_complex ? mxCOMPLEX : mxREAL);
    if (plhs[0] == NULL)
    {
        mexErrMsgTxt("Could not allocate output array.");
    }
    double *yi_r = static_cast<double*>(mxGetPr(plhs[0]));
    double *yi_i = NULL;
    if (is_complex)
    {
        yi_i = static_cast<double*>(mxGetPi(plhs[0]));
    }
    else
    {
       yi_i = (double*)mxMalloc(xi_length * sizeof(double));
    }   

    // Resample.
    size_t ref_idx = 0;
    for (size_t resamp_idx = 0; resamp_idx < xi_length; ++resamp_idx)
    {
        // Find the sample to copy for the current output (corresponds to the
        // largest x position value that is less than or equal to the current
        // sample position xi).
        //
        // This loop will exit when the first point has been reached that fails
        // the criteria, so the ref_idx will need to be decremented by one. If
        // the loop exits with ref_idx = 0, that means no points meet the
        // criteria.
        while(ref_idx < x_length && x[ref_idx] <= xi[resamp_idx])
        {
            ref_idx++;
        }

        // If there is no reference sample behind the current resample point,
        // set output to zero.
        if (ref_idx == 0)
        {
            yi_r[resamp_idx] = 0.0;
            yi_i[resamp_idx] = 0.0;
            continue;
        }

        ref_idx--;

        // Copy the sample into the output vector.
        yi_r[resamp_idx] = y_r[ref_idx];
        yi_i[resamp_idx] = y_i[ref_idx];
    }
    if(!is_complex)
    {
        mxFree(yi_i);
        mxFree(y_i);
    }
}

