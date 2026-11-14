function data = ReadUserData(filename)
% Load a netlist JSON file and build the numeric tables the toolbox uses.
% Does not run power flow or build models.

S = SimplusGT.IO.ReadJson(filename);

if ~isfield(S, 'basic') || ~isfield(S, 'advance') ...
        || ~isfield(S, 'buses') || ~isfield(S, 'lines') ...
        || ~isfield(S, 'apparatuses')
    error('JSON netlist %s is missing a required top-level field (basic, advance, buses, lines, apparatuses).', filename);
end

data.ListBasic = zeros(4, 1);
data.ListBasic(1) = SimplusGT.IO.FromJsonValue(S.basic.sampling_frequency_Hz);
data.ListBasic(2) = SimplusGT.IO.FromJsonValue(S.basic.base_frequency_Hz);
data.ListBasic(3) = SimplusGT.IO.FromJsonValue(S.basic.base_power_VA);
data.ListBasic(4) = SimplusGT.IO.FromJsonValue(S.basic.base_voltage_V);

adv = S.advance;
data.ListAdvance = zeros(10, 1);
data.ListAdvance(1) = SimplusGT.IO.FromJsonValue(adv.discretization_method);
data.ListAdvance(2) = SimplusGT.IO.FromJsonValue(adv.linearization_times);
data.ListAdvance(3) = SimplusGT.IO.FromJsonValue(adv.discretization_damping_flag);
data.ListAdvance(4) = SimplusGT.IO.FromJsonValue(adv.direct_feedthrough);
data.ListAdvance(5) = SimplusGT.IO.FromJsonValue(adv.power_flow_algorithm);
data.ListAdvance(6) = SimplusGT.IO.FromJsonValue(adv.create_simulink_model);
data.ListAdvance(7) = SimplusGT.IO.FromJsonValue(adv.plot_pole_map);
data.ListAdvance(8) = SimplusGT.IO.FromJsonValue(adv.plot_admittance);
data.ListAdvance(9) = SimplusGT.IO.FromJsonValue(adv.print_output);
data.ListAdvance(10) = SimplusGT.IO.FromJsonValue(adv.modal_analysis);

busC = SimplusGT.IO.AsCell(S.buses);
nBus = numel(busC);
data.ListBus = zeros(nBus, 12);
for i = 1:nBus
    b = busC{i};
    data.ListBus(i, 1)  = SimplusGT.IO.FromJsonValue(b.bus);
    data.ListBus(i, 2)  = SimplusGT.IO.FromJsonValue(b.type);
    data.ListBus(i, 3)  = SimplusGT.IO.FromJsonValue(b.Vsp_pu);
    data.ListBus(i, 4)  = SimplusGT.IO.FromJsonValue(b.theta_rad);
    data.ListBus(i, 5)  = SimplusGT.IO.FromJsonValue(b.PGi_pu);
    data.ListBus(i, 6)  = SimplusGT.IO.FromJsonValue(b.QGi_pu);
    data.ListBus(i, 7)  = SimplusGT.IO.FromJsonValue(b.PLi_pu);
    data.ListBus(i, 8)  = SimplusGT.IO.FromJsonValue(b.QLi_pu);
    data.ListBus(i, 9)  = SimplusGT.IO.FromJsonValue(b.Qmin_pu);
    data.ListBus(i, 10) = SimplusGT.IO.FromJsonValue(b.Qmax_pu);
    data.ListBus(i, 11) = SimplusGT.IO.FromJsonValue(b.area);
    data.ListBus(i, 12) = SimplusGT.IO.FromJsonValue(b.ac_or_dc);
end

if ~isfield(S.lines, 'form')
    error('JSON netlist lines.form must be "ieee" or "toolbox".');
end
data.LineForm = lower(strtrim(char(S.lines.form)));
if ~(strcmp(data.LineForm, 'ieee') || strcmp(data.LineForm, 'toolbox'))
    error('JSON netlist lines.form must be "ieee" or "toolbox", got %s.', data.LineForm);
end

if isfield(S.lines, 'branches')
    branches = S.lines.branches;
else
    branches = [];
end
M = BranchesToMatrix(branches, data.LineForm);
if strcmp(data.LineForm, 'ieee')
    data.ListLineIEEE = M;
    data.ListLine = zeros(0, 7);
else
    data.ListLine = M;
    data.ListLineIEEE = zeros(0, 7);
end

appC = SimplusGT.IO.AsCell(S.apparatuses);
data.Apparatus = cell(numel(appC), 1);
for i = 1:numel(appC)
    a = appC{i};
    rec.bus = a.bus;
    rec.type = SimplusGT.IO.FromJsonValue(a.type);
    if isfield(a, 'parameters') && ~isempty(a.parameters) && isstruct(a.parameters)
        rec.parameters = a.parameters;
    else
        rec.parameters = struct();
    end
    data.Apparatus{i} = rec;
end
end

function M = BranchesToMatrix(branches, form)
C = SimplusGT.IO.AsCell(branches);
n = numel(C);
M = zeros(n, 7);
for i = 1:n
    b = C{i};
    M(i, 1) = SimplusGT.IO.FromJsonValue(b.from);
    M(i, 2) = SimplusGT.IO.FromJsonValue(b.to);
    M(i, 3) = SimplusGT.IO.FromJsonValue(b.R_pu);
    if strcmp(form, 'ieee')
        M(i, 4) = SimplusGT.IO.FromJsonValue(b.X_pu);
        M(i, 5) = SimplusGT.IO.FromJsonValue(b.B_pu);
    else
        M(i, 4) = SimplusGT.IO.FromJsonValue(b.wL_pu);
        M(i, 5) = SimplusGT.IO.FromJsonValue(b.wC_pu);
    end
    M(i, 6) = SimplusGT.IO.FromJsonValue(b.G_pu);
    M(i, 7) = SimplusGT.IO.FromJsonValue(b.turns_ratio);
end
end
