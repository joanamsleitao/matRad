function success = checkDoseCubeMatch(qi, ixPTV, minGoal, maxGoal)
% CHECKDOSECUBEMATCH - Checks if D_98 and D_2 match reference dose goals
%
% Syntax:  success = checkDoseCubeMatch(qi, ixPTV, minGoal, maxGoal)
%
% Inputs:
%   qi          - Quality indicators structure (struct)
%   ixPTV       - Index of PTV in quality indicators (integer)
%   minGoal     - Minimum acceptable D_98 value [Gy] (double)
%   maxGoal     - Maximum acceptable D_2 value [Gy] (double)
%
% Outputs:
%   success     - Whether goals were met (logical)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: analyzePlanDose

minD98 = qi(ixPTV).D_98;
maxD2  = qi(ixPTV).D_2;

success = minD98 > minGoal && maxD2 < maxGoal;

if success
    disp('We did it!!');
else
    disp('We have to do the other way :(');
    disp(['D_98 = ', num2str(minD98), ', D_2 = ', num2str(maxD2)]);
end
end