% This function re-arranges the netlist data of apparatuses.

% Author(s): Yitong Li, Yunjie Gu

%% Notes
%
% The apparatus model is in load convention.
%
% The apparautus bus index, type index, and parameters are saved in three
% different cells. The reason of doing this is that, the number of
% apparatuses might not be same to the number of buses, when the power
% system has interlink apparatuses. In this case, the interlink apparatus
% will have two bus indice.
%
% "app" means apparatus.

function [AppBusCell,AppTypeCell,ParaCell,N_App] = RearrangeListApparatus(Apparatus,W0,ListBus)

%% Rearrange data
% Notes:
% This section will convert the JSON apparatus list to AppBusCell
% and AppTypeCell, i.e., array type to cell type.

if isstruct(Apparatus)
    Apparatus = num2cell(Apparatus(:));
end
N_App = numel(Apparatus);
N_AppFile = N_App;
ColumnMax_Apparatus = 0;

% Get the apparatus bus and type in cell form
for n = 1:N_App
    rec = Apparatus{n};
    bus = rec.bus;
    if ischar(bus) || isstring(bus)
        AppBusCell{n} = str2num(char(bus));
    else
        bus = double(bus);
        if numel(bus) == 1
            AppBusCell{n} = bus;
        else
            AppBusCell{n} = bus(:).';
        end
    end
    if numel(AppBusCell{n}) > 1
        [~,~,AreaType]= SimplusGT.Toolbox.CheckBus(AppBusCell{n}(1),ListBus);
        
        % Notes:
        % If the first bus is dc bus, then swap. This ensures the first one
        % is ac bus.
        if AreaType == 2 
            [AppBusCell{n}(1),AppBusCell{n}(2)] = deal(AppBusCell{n}(2),AppBusCell{n}(1));
        end
    end
    AppTypeCell{n} = rec.type;
    if isfield(rec, 'parameters') && isstruct(rec.parameters)
        ColumnMax_Apparatus = max(ColumnMax_Apparatus, numel(fieldnames(rec.parameters)));
    end
end

% Add floating bus
N_Bus = length(ListBus(:,1));
for m = 1:N_Bus
    BusIndex = ListBus(m,1);
    ExistApparatus = SimplusGT.CellFind(AppBusCell,BusIndex);
    if isempty(ExistApparatus)
        % The bus has no apparatus, i.e., an ac or dc floating bus.
        N_App = N_App+1;
        AppBusCell{N_App} = BusIndex;   % Add a new bus index
        [~,~,AreaType] = SimplusGT.Toolbox.CheckBus(BusIndex,ListBus);  % Check if an ac or dc bus
        if AreaType == 1
            AppTypeCell{N_App} = 100;       % Ac floating bus
        elseif AreaType == 2
            AppTypeCell{N_App} = 1100;      % Dc floating bus
        else
            error(['Error: Error AreaType.']);
        end
    else
        % The bus has an apparatus already, no need to do anything then.
    end
end

% Error check
if (ColumnMax_Apparatus>50)
    error(['Error: Apparatus data overflow.']); 
end

[~,ModeBus] = SimplusGT.CellMode(AppBusCell);
if ModeBus~=1
    error(['Error: For each bus, one and only one apparatus has to be connected.']);
end

%% Default AC apparatus data
% ======================================
% Synchronous generator
% ======================================
Para0000.J  = 3.5;
Para0000.D  = 1;
Para0000.wL = 0.05;
Para0000.R  = 0.01;
Para0000.w0 = W0;

% ======================================
% Grid-following VSI (PLL-controlled)
% ======================================
% Dc link
Para0010.V_dc       = 2.5;
Para0010.C_dc       = 1.25;         % 2*0.1*Para0010.V_dc^2;
Para0010.f_v_dc     = 5;            % (Hz) bandwidth, vdc

% Ac filter
Para0010.wLf        = 0.03;
Para0010.R          = 0.01;

% PLL
Para0010.f_pll      = 5;            % (Hz) bandwidth, PLL
Para0010.f_tau_pll  = 300;          % (Hz) bandwidth, PLL low pass filter

% Current loop
Para0010.f_i_dq     = 600;      	% (Hz) bandwidth, idq
Para0010.w0         = W0;
Para0010.Sbase      = 1;

% ======================================
% Grid-forming VSI (Droop-Controlled)
% ======================================
Para0020.wLf    =0.05;
Para0020.Rf     =0.05/5;
Para0020.wCf    =0.02;
Para0020.wLc    =0.01;
Para0020.Rc     =0.01/5;
Para0020.Xov    =0.01;
Para0020.Dw     =0.05;
Para0020.fdroop =5;    % (Hz) droop control bandwidth
Para0020.fvdq   =300;   % (Hz) vdc bandwidth
Para0020.fidq   =600;   % current control bandwidth
%Para0020.w0     = W0;
Para0020.Sbase = 1;

% ======================================
% Synchronous generato ----- Full Model
% ======================================
Para0030.X=0.0125;
Para0030.R=0;
Para0030.Xd=0.1; %synchronous reactance in d axis
Para0030.Xd1=0.031; %transient reactance
Para0030.Xd2=0.025; %subtransient reactance
Para0030.Td1=10.2; %d-axis open circuit transient time constant
Para0030.Td2=0.05; %d-axis open circuit sub-transient time constant
Para0030.Xq=0.069;
Para0030.Xq1=0.0416667;
Para0030.Xq2=0.025;
Para0030.Tq1=1.5;
Para0030.Tq2=0.035;
Para0030.H=42;
Para0030.D=0;
Para0030.TR=0.01;
Para0030.KA=1;
Para0030.TA=0.02;
Para0030.VRmax=10;
Para0030.VRmin=-10;
Para0030.KE=1;
Para0030.TE=0.785;
Para0030.E1=3.9267;
Para0030.SE1=0.07;
Para0030.E2=5.2356;
Para0030.SE2=0.91;
Para0030.KF=0.03;
Para0030.TF=1;
Para0030.KP=200;
Para0030.KI=50;
Para0030.KD=50;
Para0030.TD=0.01;
Para0030.KPSS=20;
Para0030.TW=15;
Para0030.T11=0.15;
Para0030.T12=0.04;
Para0030.T21=0.15;
Para0030.T22=0.04;
Para0030.T31=0.15;
Para0030.T32=0.04;
Para0030.VSSmax=0.2;
Para0030.VSSmin=-0.05;
Para0030.Rgov=0.05;
Para0030.T1gov=0.1;
Para0030.T2gov=1.6;
Para0030.T3gov=10;
Para0030.Dtgov=0.2;

% ======================================
% Synchronous generato ----- Full Model ---- Cyprus Model
% ======================================
Para0040.Sbase_SM=1;
Para0040.X=0.0125;
Para0040.R=0;
Para0040.Xd=0.1; %synchronous reactance in d axis
Para0040.Xd1=0.031; %transient reactance
Para0040.Xd2=0.025; %subtransient reactance
Para0040.Td1=10.2; %d-axis open circuit transient time constant
Para0040.Td2=0.05; %d-axis open circuit sub-transient time constant
Para0040.Xq=0.069;
Para0040.Xq1=0.0416667;
Para0040.Xq2=0.025;
Para0040.Tq1=1.5;
Para0040.Tq2=0.035;
Para0040.H=42;
Para0040.D=0;
Para0040.Dpu=0;
Para0040.SG10=1;
Para0040.SG12=1;
%AVR
Para0040.Tr=0;
Para0040.Ka=50;
Para0040.Ta=0.06;
Para0040.Vrmax=1;
Para0040.Vrmin=-1;
Para0040.Ke=-0.0465;
Para0040.Te=0.520;
Para0040.Kf=0.0832;
Para0040.Tf=1.0;
Para0040.E1=3.24;
Para0040.SEE1=0.072;
Para0040.E2=4.320;
Para0040.SEE2=0.2821;
%PSS
Para0040.T1=5;
Para0040.T2=0.6;
Para0040.T3=3;
Para0040.T4=0.5;
Para0040.Tw=10;
Para0040.Kpss=1;
Para0040.Vpssmin=-0.2;
Para0040.Vpssmax=0.2;
%Governor
Para0040.Rgov=0.011;
Para0040.T1gov=0.1;
Para0040.T2gov=0;
Para0040.T3gov=0.3;
Para0040.T4gov=0.05;
Para0040.T5gov=10;
Para0040.Fgov=0.25;
Para0040.Pmax_gov=1;
Para0040.w0 = W0;


% ======================================
% Ac infinite bus (short-circuit in small-signal)
% ======================================
Para0090 = [];

% ======================================
% Ac floating bus (open-circuit)
% ======================================
Para0100 = [];

%% Default DC apparatus data
% ======================================
% Grid-feeding buck
% ======================================
Para1010.Vdc  = 2;
Para1010.Cdc  = 0.8;
Para1010.wL   = 0.05;
Para1010.R    = 0.05/5;
Para1010.fi   = 600;
Para1010.fvdc = 5;
Para1010.w0   = W0;

% ======================================
% Dc infinite bus (short-circuit in small-signal)
% ======================================
Para1090 = [];

% ======================================
% Dc floating bus (open-circuit)
% ======================================
Para1100 = [];

%% Default hybrid apparatus data
% ======================================
% Interlink ac-dc converter
% ======================================
Para2000.C_dc   = 1.6;
Para2000.wL_ac  = 0.05;
Para2000.R_ac   = 0.01;
Para2000.wL_dc  = 0.02;
Para2000.R_dc   = 0.02/5;
Para2000.fidq   = 600;
Para2000.fvdc   = 5;
Para2000.fpll   = 5;
Para2000.w0     = W0;   

%% Re-arrange apparatus data

% Initialize the apparatus parameters by default parameters
for i = 1:N_App
    AppBus   = AppBusCell{i};
    AppType  = AppTypeCell{i};
    switch floor(AppType/10)
        % ### AC apparatuses
        case 0     
            ParaCell{i} = Para0000;     % Synchronous machine
        case 1
            ParaCell{i} = Para0010;     % Grid-following inverter
      	case 2
            ParaCell{i} = Para0020;     % Grid-forming inverter
        case 3
            ParaCell{i} = Para0030;     % Synchronous Machine full model (68-bus model)
        case 4
            ParaCell{i} = Para0040;     % Synchronous Machine full model (Cyprus model)
            % Yue's Full-Order Machine
        case 9
            ParaCell{i} = Para0090;     % Ac inifnite bus
        case 10
            ParaCell{i} = Para0100;     % Ac floating bus, i.e., no apparatus
        
        % ### DC apparatuses
        case 101
            ParaCell{i} = Para1010;     % Grid-following buck
        case 109
            ParaCell{i} = Para1090;     % Dc infinite bus
        case 110
            ParaCell{i} = Para1100;     % Ac floating bus, i.e., no apparatus
            
        % ### Hybrid ac-dc apparatuses
        case 200
            ParaCell{i} = Para2000;     % Interlinking ac-dc converter
            
        % ### Error check
        otherwise
            error(['Error: apparatus type, bus ' num2str(AppBus) ' type ' num2str(AppType) '.']);
    end
end

% Replace the default data by customized data
%
% Notes:
% JSON parameters are named fields. Only fields present in the netlist
% overlay the defaults, matching the former Excel NaN-skip behaviour.
for i = 1:N_AppFile
    rec = Apparatus{i};
    if ~isfield(rec, 'parameters') || isempty(rec.parameters) || ~isstruct(rec.parameters)
        continue
    end
    AppBus = AppBusCell{i};
    AppType = AppTypeCell{i};
    userPara = rec.parameters;
    fn = fieldnames(userPara);
    for k = 1:numel(fn)
        UserValue = SimplusGT.IO.FromJsonValue(userPara.(fn{k}));
        if isempty(UserValue)
            continue
        end
        ParaCell{i}.(fn{k}) = UserValue;
    end
    if isempty(fn)
        % no user parameters
    elseif numel(fn) > 50
        error(['Error: parameter overflow, bus ' num2str(AppBus) 'type ' num2str(AppType) '.']);
    end
end

%% The re-order can only be done here
% For a single-area pure ac system, we re-order the apparatuses 
AreaTypeCheck = find(ListBus(:,12) == 2, 1);
AreaNoCheck = find(ListBus(:,11) == 2, 1);
if isempty(AreaTypeCheck) && isempty(AreaNoCheck)
    for j = 1:N_App
        [~,AppIndex] = SimplusGT.CellFind(AppBusCell,j);
        AppBusCellNew{j}    = AppBusCell{AppIndex};
        AppTypeCellNew{j}   = AppTypeCell{AppIndex};
        ParaCellNew{j}      = ParaCell{AppIndex};
    end
    AppBusCell  = AppBusCellNew;
    AppTypeCell = AppTypeCellNew;
    ParaCell    = ParaCellNew;
end
end