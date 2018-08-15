function [AoA, AoD, z_reflection] = multiple_reflections(L, reflectors, z_tx, z_rx)
% reflectors are number of walls
EARLY_STOP = 1;

%initialize
AoA = struct('r', NaN, 'theta', NaN);
AoD = struct('r', NaN, 'theta', NaN);
z_reflection = NaN(length(reflectors), 1);

% if same reflectors exist print error
if ( ~isempty(find(diff(reflectors) == 0, 1)) )
    error('multiple_reflections:reflectors', 'consecutive reflectors cannot be the same!\n');
end

z_tx_refl = NaN(length(reflectors), 1);
% recursively reflect the Tx towards the Rx
z_tx_refl(1) = L{reflectors(1)}.reflect(z_tx);

for i=2:length(reflectors)
    % sequentially reflect Tx
    z_tx_refl(i) = L{reflectors(i)}.reflect(z_tx_refl(i-1));
end

%reflection may not be "valid" but, there might still be a path.
%only ray traced check is useful

reflection_valid = NaN(length(reflectors), 1);
% join the last Tx-image to the Rx to get the last intersection point
tmp_L = create_line(z_tx_refl(end), z_rx);
[z_reflection(end), tmp] = L{reflectors(end)}.intersect(tmp_L);
if (sum(tmp) == 2) % How many reflections to keep
    reflection_valid(end) = 1; 
else
    reflection_valid(end) = 0; %#ok<NASGU>
    if (EARLY_STOP), return; end % DONE if we want speed!
end

%will come here only if the reflection is valid
for i=length(reflectors)-1:-1:1
%    line from current reflection point to previuos tx-reflection
    tmp_L = create_line(z_tx_refl(i), z_reflection(i+1));
    [z_reflection(i), tmp] = L{reflectors(i)}.intersect(tmp_L);
if (sum(tmp) == 2)
    reflection_valid(i) = 1;
else
    reflection_valid(i) = 0;
    if (EARLY_STOP), return; end % DONE if we want speed!
end
end

%let the ray tracing begin
no_intersections = NaN(length(reflectors)+1, 1);
%tx->1st reflector
tmp_L = create_line(z_tx, z_reflection(1));
no_intersections(1) = check_intersections(tmp_L, L, reflectors(1));
if ( (no_intersections(1) == 0) && EARLY_STOP), return; end
for i=2:length(reflectors)
 %   one reflection to the next
    tmp_L = create_line(z_reflection(i-1), z_reflection(i));
    no_intersections(i) = check_intersections(tmp_L, L, reflectors(i-1:i));
    if ( (no_intersections(i) == 0) && EARLY_STOP), return; end
end
%last reflector->rx
tmp_L = create_line(z_reflection(end), z_rx);
no_intersections(end) = check_intersections(tmp_L, L, reflectors(end));
if ( (no_intersections(end) == 0) && EARLY_STOP), return; end

%finally!
%angles
tmp_L = create_line(z_tx, z_reflection(1));  % tx -> reflection
AoD.theta = tmp_L.alpha;
tmp_L = create_line(z_rx, z_reflection(end));  % reflection -> rx, note : needs coded reverse, to get the angle right
AoA.theta = tmp_L.alpha;
%distance
tmp_r = abs(z_reflection(1) - z_tx);
for i=2:length(reflectors)
    tmp_r = tmp_r + abs(z_reflection(i) - z_reflection(i-1));
end
tmp_r = tmp_r + abs(z_rx - z_reflection(end));
AoA.r = tmp_r;
AoD.r = tmp_r;

%[TBD] optimize intersections
%[TBD] trim reflectors to speed up the searches (doubt if there is much possible)
%[TBD] do reflectors contribute? intersection of reflectors (believe yes)
return


function valid = check_intersections(L, other_L, ignore_indicies)

L2check = setdiff(1:length(other_L), ignore_indicies);

tmp_v = NaN(length(other_L),1);
tmp_v(ignore_indicies) = 0;
for i=L2check
    [~, tmp] = L.intersect(other_L{i});
    tmp_v(i) = tmp(1) & tmp(2);
end
%no intersections
if (sum(tmp_v) == 0)
    valid = 1;
else
    valid = 0;
end

return
