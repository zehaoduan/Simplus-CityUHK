function WriteResults(filename, UserData, proper, stable, ListPowerFlow, pole_sys)
% Write power-flow and pole results already computed by Main.

R = struct();
R.input = char(UserData);
R.proper = logical(proper);
R.stable = logical(stable);

pf = struct('bus', {}, 'P', {}, 'Q', {}, 'V', {}, 'angle', {}, 'omega', {});
for i = 1:size(ListPowerFlow, 1)
    pf(i).bus = ListPowerFlow(i, 1);
    pf(i).P = ListPowerFlow(i, 2);
    pf(i).Q = ListPowerFlow(i, 3);
    pf(i).V = ListPowerFlow(i, 4);
    pf(i).angle = ListPowerFlow(i, 5);
    pf(i).omega = ListPowerFlow(i, 6);
end
R.power_flow = pf;

p = struct('real', {}, 'imag', {});
ps = pole_sys(:);
for i = 1:numel(ps)
    p(i).real = real(ps(i));
    p(i).imag = imag(ps(i));
end
R.poles_Hz = p;

SimplusGT.IO.WriteJson(filename, R);
fprintf('Results written to:\n%s\n', filename);
end
