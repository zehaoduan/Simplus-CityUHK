function [AutoSelResult] = WriteModalConfig(N_Bus, N_Apparatus, ApparatusType, ApparatusBus, ApparatusStateStr, ...
    ZbusStateStr, GminSS, GsysDSS, AutoSel, Fbase, filename)
% Write states, apparatuses, and axes for the user to select in JSON.
% Auto-select tests are the same as the former Excel writer.
% Author: Yue Zhu

AutoSelResult = 0;

%% State-PF
[GsysSS, IndexSS] = SimplusGT.dss2ss(GsysDSS);
[~, D] = eig(GsysSS.A);
D = D / (2 * pi);
Mode = diag(D);
ModeNum = length(Mode);

states = struct('component', {}, 'state', {}, 'select', {});
si = 0;
StateCount = 0;
for k = 1:N_Apparatus
    if ApparatusType{k} <= 89
        ApparatusName = strcat('Apparatus', num2str(ApparatusBus{k}));
        StateName = ApparatusStateStr{k};
        StateNum = length(ApparatusStateStr{k});
        for j = 1:StateNum
            StateCount = StateCount + 1;
            if ismember(StateCount, IndexSS)
                si = si + 1;
                states(si).component = ApparatusName;
                if iscell(StateName)
                    states(si).state = StateName{j};
                else
                    states(si).state = StateName(j);
                end
                states(si).select = 1;
            end
        end
    else
    end
end

for i = 1:length(ZbusStateStr)
    StateCount = StateCount + 1;
    if ismember(StateCount, IndexSS)
        si = si + 1;
        states(si).component = 'Line';
        if iscell(ZbusStateStr)
            states(si).state = ZbusStateStr{i};
        else
            states(si).state = ZbusStateStr(i);
        end
        states(si).select = 0;
    end
end

modes_state = struct('name', {}, 'real', {}, 'imag', {}, 'select', {});
index = 2;
SmodeSel1 = abs(real(Mode(1)));
IndexSel1 = 2;
SmodeSel2 = abs(real(Mode(2)));
IndexSel2 = 3;
for i = 1:ModeNum
    ModeName = strcat('Mode', num2str(i));
    modes_state(i).name = ModeName;
    modes_state(i).real = real(Mode(i));
    modes_state(i).imag = imag(Mode(i));
    if AutoSel == 1 && i >= 3
        if abs(imag(Mode(i))) < 100
            if abs(abs(imag(Mode(i))) - 0) >= 0.1
                if abs(abs(imag(Mode(i))) - Fbase) >= 1
                    if abs(real(Mode(i))) < SmodeSel1 || SmodeSel1 == 0
                        SmodeSel2 = SmodeSel1;
                        IndexSel2 = IndexSel1;
                        SmodeSel1 = abs(real(Mode(i)));
                        IndexSel1 = index;
                    elseif abs(real(Mode(i))) > SmodeSel1 && abs(real(Mode(i))) < SmodeSel2 ...
                            || SmodeSel2 == 0 || abs(abs(imag(Mode(i))) - Fbase) <= 1
                        SmodeSel2 = abs(real(Mode(i)));
                        IndexSel2 = index;
                    end
                end
            end
        end
    end
    modes_state(i).select = 0;
    index = index + 1;
end
if IndexSel1 ~= 2 && IndexSel2 ~= 3
    AutoSelResult = 1;
    modes_state(IndexSel1 - 1).select = 1;
    modes_state(IndexSel2 - 1).select = 1;
elseif AutoSel == 1
    AutoSelResult = 0;
    error('Mode Auto-Selection failed. Please open the ModalConfig JSON file to select the mode manually.')
else
end

%% Impedance-PF
[~, D] = eig(GminSS.A);
D = D / (2 * pi);
Mode = diag(D);
ModeNum = length(Mode);

layer12 = struct('component', {}, 'select', {});
li = 0;
for k = 1:N_Apparatus
    if ApparatusType{k} <= 89
        li = li + 1;
        layer12(li).component = strcat('Apparatus', num2str(ApparatusBus{k}));
        layer12(li).select = 1;
    else
    end
end

bode_axes = struct('axis', {}, 'select', {});
bode_axes(1).axis = 'd-d';
if AutoSel == 1
    bode_axes(1).select = 1;
else
    bode_axes(1).select = 0;
end
bode_axes(2).axis = 'd-q';
bode_axes(2).select = 0;
bode_axes(3).axis = 'q-d';
bode_axes(3).select = 0;
bode_axes(4).axis = 'q-q';
bode_axes(4).select = 0;

modes_imp = struct('name', {}, 'real', {}, 'imag', {}, 'select', {});
index = 3;
SmodeSel1 = abs(real(Mode(1)));
IndexSel1 = 3;
SmodeSel2 = abs(real(Mode(2)));
IndexSel2 = 4;
for i = 1:ModeNum
    modes_imp(i).name = strcat('Mode', num2str(i));
    modes_imp(i).real = real(Mode(i));
    modes_imp(i).imag = imag(Mode(i));
    if AutoSel == 1 && i >= 3
        if abs(imag(Mode(i))) < 100
            if abs(abs(imag(Mode(i))) - 0) >= 0.1
                if abs(abs(imag(Mode(i))) - Fbase) >= 1
                    if abs(real(Mode(i))) < SmodeSel1 || SmodeSel1 == 0 || abs(abs(imag(Mode(i))) - Fbase) <= 1
                        SmodeSel2 = SmodeSel1;
                        IndexSel2 = IndexSel1;
                        SmodeSel1 = abs(real(Mode(i)));
                        IndexSel1 = index;
                    elseif abs(real(Mode(i))) > SmodeSel1 && abs(real(Mode(i))) < SmodeSel2 ...
                            || SmodeSel2 == 0 || abs(abs(imag(Mode(i))) - Fbase) <= 1
                        SmodeSel2 = abs(real(Mode(i)));
                        IndexSel2 = index;
                    end
                end
            end
        end
    end
    modes_imp(i).select = 0;
    index = index + 1;
end
if AutoSel == 1 && IndexSel1 ~= 2 && IndexSel2 ~= 3
    AutoSelResult = 1;
    modes_imp(IndexSel1 - 2).select = 1;
    modes_imp(IndexSel2 - 2).select = 1;
elseif AutoSel == 1
    AutoSelResult = 0;
    error('Mode Auto-Selection failed. Please open the ModalConfig JSON file to select the mode manually.')
else
end

layer3 = struct('component', {}, 'select', {});
li = 0;
IndexSel = 1;
for k = 1:N_Apparatus
    if ApparatusType{k} <= 89
        li = li + 1;
        layer3(li).component = strcat('Apparatus', num2str(ApparatusBus{k}));
        if AutoSel == 1 && IndexSel == 1
            layer3(li).select = 1;
            IndexSel = IndexSel + 1;
        else
            layer3(li).select = 0;
        end
    else
    end
end

Cfg = struct();
Cfg.state_pf.states = states;
Cfg.state_pf.modes = modes_state;
Cfg.impedance_pf.layer12_components = layer12;
Cfg.impedance_pf.bode_axes = bode_axes;
Cfg.impedance_pf.modes = modes_imp;
Cfg.impedance_pf.layer3_components = layer3;
Cfg.enabling.state_pf = 1;
Cfg.enabling.bodeplot = 1;
Cfg.enabling.impedance_pf_layer12 = 1;
Cfg.enabling.impedance_pf_layer3 = 1;
Cfg.enabling.whole_system_sensitivity = 1;

if exist(filename, 'file')
    delete(filename);
    if exist(filename, 'file')
        error('Could not replace %s. Close the file if it is open.', filename);
    end
end
SimplusGT.IO.WriteJson(filename, Cfg);
end
