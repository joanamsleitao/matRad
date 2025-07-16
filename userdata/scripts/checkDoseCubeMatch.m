function success = checkDoseCubeMatch(qi, ixPTV, minGoal, maxGoal)
% Checks if current D_98 and D_2 match reference dose goals.

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