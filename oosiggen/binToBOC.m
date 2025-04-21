function bocCode = binToBOC(binCode,m,n)

% Function:
%   bocCode = bin2boc(binCode,m,n)
%
% Usage:
%   Returns a BOC(m,n) code from a binary input, i.e.,  1->[1,0], 0->[0,1]
%       for m=n=1.
%   Each row of binCode is a single binary sequence.
%
% Inputs:           Description                                       Units
%   binCode           [S,N] Matrix of binary values                   [N/A]
%   m                 Subcarrier freq normalized to 1.023 Mcps        [N/A]
%   n                 Chipping rate normalized to 1.023 Mcps          [N/A]
% 
% Output:           Description                                       Units
%   bocCode           [S,k*N] Matrix of binary values                 [N/A]
%                       k = 2*m/n
%
% Example: 
%   bin2boc([0 0 0 0; 1 1 1 1; 1 0 1 1],1,1) = 
%     [0 1 0 1 0 1 0 1; 1 0 1 0 1 0 1 0; 1 0 0 1 1 0 1 0]
%
% NOTICE
% 
% This software was produced for the U.S. Government
% under Contract No. FA8721-10-C-0001, and is
% subject to the Rights in Noncommercial Computer Software
% and Noncommercial Computer Software Documentation Clause
% (DFARS) 252.227-7014 (JUN 1995)
% 
% Copyright 2010 The MITRE Corporation


% Input argument check
if ~isscalar(m) || ~isreal(m) || m<0
    error('m must be a real positive scalar.');
end
if ~isscalar(n) || ~isreal(n) || n<0
    error('n must be a real positive scalar.');
end

% Get k
k = 2*m/n;
if mod(m/n,1)~=0
    error('m/n must be an integer.');
end

% Generate BOC pattern
pattern = ones(k,1);
pattern(2:2:end) = -1;

% Generate BOC code
bocCode = zeros(size(binCode,1),k*size(binCode,2));
for i=1:size(binCode,1)
    bocCodei = kron(2*binCode(i,:)-1,pattern);
    bocCode(i,:) = (bocCodei(:)'+1)/2;
end


