function [AxisSel, ApparatusSel12, ModeSel, ApparatusSel3, StateSel_DSS, ModeSel_DSS, ...
    StatePFEnable, BodeEnable, Layer12Enable, Layer3Enable, SensEnable] = ...
    ReadModalConfig(filename, N_Apparatus, ApparatusType, GminSS)
% Read modal-analysis selections from JSON.
% Output arguments match the former ExcelRead + EnablingRead.

S = SimplusGT.IO.ReadJson(filename);

StateSel_DSS = 0;
ModeSel_DSS = 0;
SelIndex1 = 1;
SelIndex2 = 1;

stateC = SimplusGT.IO.AsCell(S.state_pf.states);
for Count = 1:numel(stateC)
    if SimplusGT.IO.FromJsonValue(stateC{Count}.select) == 1
        StateSel_DSS(SelIndex1) = Count;
        SelIndex1 = SelIndex1 + 1;
    end
end
modeStateC = SimplusGT.IO.AsCell(S.state_pf.modes);
for Count = 1:numel(modeStateC)
    if SimplusGT.IO.FromJsonValue(modeStateC{Count}.select) == 1
        ModeSel_DSS(SelIndex2) = Count;
        SelIndex2 = SelIndex2 + 1;
    end
end

axisC = SimplusGT.IO.AsCell(S.impedance_pf.bode_axes);
SelIndex = 1;
AxisSel = 0;
for ax = 1:min(4, numel(axisC))
    if SimplusGT.IO.FromJsonValue(axisC{ax}.select) == 1
        AxisSel(SelIndex) = ax;
        SelIndex = SelIndex + 1;
    end
end

layer12C = SimplusGT.IO.AsCell(S.impedance_pf.layer12_components);
SelIndex = 1;
ApparatusSel12 = 0;
ApparatusIndex = 1;
for k = 1:N_Apparatus
    if ApparatusType{k} <= 89
        sel = 0;
        if ApparatusIndex <= numel(layer12C)
            sel = SimplusGT.IO.FromJsonValue(layer12C{ApparatusIndex}.select);
        end
        if sel == 1
            ApparatusSel12(SelIndex) = k;
            SelIndex = SelIndex + 1;
        end
        ApparatusIndex = ApparatusIndex + 1;
    else
    end
end

ModeNum = length(GminSS.A);
modeImpC = SimplusGT.IO.AsCell(S.impedance_pf.modes);
SelIndex = 1;
ModeSel = 0;
for i = 1:ModeNum
    if i <= numel(modeImpC) && SimplusGT.IO.FromJsonValue(modeImpC{i}.select) == 1
        ModeSel(SelIndex) = i;
        SelIndex = SelIndex + 1;
    end
end

layer3C = SimplusGT.IO.AsCell(S.impedance_pf.layer3_components);
SelIndex = 1;
ApparatusSel3 = 0;
ApparatusIndex = 1;
for k = 1:N_Apparatus
    if ApparatusType{k} <= 89
        sel = 0;
        if ApparatusIndex <= numel(layer3C)
            sel = SimplusGT.IO.FromJsonValue(layer3C{ApparatusIndex}.select);
        end
        if sel == 1
            ApparatusSel3(SelIndex) = k;
            SelIndex = SelIndex + 1;
        end
        ApparatusIndex = ApparatusIndex + 1;
    else
    end
end

en = S.enabling;
StatePFEnable = SimplusGT.IO.FromJsonValue(en.state_pf);
BodeEnable = SimplusGT.IO.FromJsonValue(en.bodeplot);
Layer12Enable = SimplusGT.IO.FromJsonValue(en.impedance_pf_layer12);
Layer3Enable = SimplusGT.IO.FromJsonValue(en.impedance_pf_layer3);
SensEnable = SimplusGT.IO.FromJsonValue(en.whole_system_sensitivity);

if StatePFEnable == 0 && BodeEnable == 0 && Layer12Enable == 0 ...
        && Layer3Enable == 0 && SensEnable == 0
    error('Please enable at least one function of participation analysis.')
end
end
