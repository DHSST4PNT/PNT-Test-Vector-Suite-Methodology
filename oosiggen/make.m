
disp('Compiling nonUniformResampleFast...');
mex('-output', 'nonUniformResampleFast', '-DMEX', ...
    'non_uniform_resample_fast.cpp');

disp('Compiling ppvalFastCore...');
mex('-output', 'ppvalFastCore', '-DMEX', 'ppval_fast_core.cpp');
