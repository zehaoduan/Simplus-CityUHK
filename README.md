# Simplus-CityUHK (14 Nov 2026)

This is a MATLAB power system modal analysis program forked from the work by Professor Yue Zhu, Professor Yunjie Gu, and Professor Yitong Li. The toolbox builds a descriptor state-space model of the network in `input.json`, runs a power flow, computes the system poles, and optionally does participation analysis. All program I/O is pretty-printed JSON.

Checked on this machine on 14 Nov 2026 with MATLAB R2026b (`26.2.0.3386108`). The binary is `/home/zehao/.local/bin/matlab`, which is `/usr/local/R2026b/bin/matlab`. The whole run of the checked-in `input.json` took about 27 seconds and exited 0.

## Run the pole calculation

From this directory:

```bash
matlab -batch "run('main.m')"
```

`main.m` is the customer entry point. It clears the workspace, sets `UserData = 'input.json'`, and calls `SimplusGT.Toolbox.Main`. That call is a script, not a function: `+SimplusGT/+Toolbox/Main.m` has no `function` line, so it executes in the caller workspace. `UserData` must already exist there. `Main.m` is not given arguments.

`Main.m` locates itself with `mfilename('fullpath')`, walks up three directories (`+Toolbox` → `+SimplusGT` → this repo), and `cd`s there before reading the netlist. A relative `input.json` is correct after that `cd`. Put this repo on the MATLAB path before the call if the process did not start here (`addpath` of the repo root). The current directory is on the path after `cd`.

Headless `-batch` is enough for the checked-in case. Simulink creation and the pole/admittance plots are off in `input.json`, so there is no display requirement.

`matlab -batch "run('main.m')"` proves the toolbox runs. It prints `Stable!` or `Warning: Unstable!`, then `End: run successfully.` Poles are written to `input_results.json` next to the netlist, and also stay in the variable `pole_sys` in that same workspace. To inspect them in the workspace, post-process in the same script, before MATLAB exits:

```matlab
cd('/home/zehao/gaojiaoshe/Simplus-CityUHK');
addpath(pwd);
UserData = 'input.json';
SimplusGT.Toolbox.Main();   % script; leaves pole_sys in this workspace

p = pole_sys(:);
pp = p(imag(p) >= 0);
band = pp(abs(imag(pp) - 150) <= 10);
[~, ord] = sort(abs(real(band)));
z = band(ord(1));           % nearest the imaginary axis inside the band
fprintf('%.12e %+.12ej Hz\n', real(z), imag(z));
```

When stdout is redirected to a file, MATLAB block-buffers it. Judge success from the process exit, or from a `diary` file, not from a partial tail while the process is still running. A finished log contains `End: run successfully.`

The comment at the top of `+SimplusGT/+Toolbox/Main.m` says to use `Main_Customer.m`. That file is not in this repo. Use root `main.m`.

## What the run does

Order inside `SimplusGT.Toolbox.Main`:

1. Read `input.json` (`basic`, `advance`, `buses`, `lines`, `apparatuses`).
2. Power flow. Algorithm 2 is Newton-Raphson. Algorithm 1 is Gauss-Seidel. A DC area (`buses[].ac_or_dc` equal to 2) forces Gauss-Seidel.
3. Build the line admittance, each apparatus model, and the whole-system descriptor model `GsysDSS`.
4. Reject the model if it is improper (more zeros than poles). This case printed `Proper!` and built the minimum realization `GminSS`.
5. Poles and the stability test.
6. Optional Simulink model `mymodel_v1`. Skipped when the flag is 0, and also forced off when `N_Bus >= 150`.
7. Optional pole map and admittance Bode plot.
8. Optional participation analysis (`SimplusGT.Modal.ModalInitialise`).

Stability test, as coded:

```matlab
pole_sys = pole(GsysDSS)/2/pi;
% unstable if any real(pole_sys) > 1e-8
```

`pole_sys` is in hertz, not rad/s. Both the real part (damping) and the imaginary part (oscillation frequency) are in Hz. The pole-map axes are labeled that way. The underlying eigenvalue in rad/s is `pole_sys * 2 * pi`. The conjugate pair is the positive-imaginary pole and its negative-imaginary twin. Report the positive-frequency one.

## `input.json`

Pretty-printed JSON with named fields. Top-level keys: `notes` (ignored by the program), `basic`, `advance`, `buses`, `lines`, `apparatuses`. Infinity in line data is the string `"inf"`. An interlink apparatus uses `"bus": [3, 2]`. Omitted apparatus parameters keep the toolbox defaults. Every field, apparatus code, and parameter default is listed in [help.md](help.md).

`basic`:

| Field | Setting | Checked-in value |
| --- | --- | --- |
| `sampling_frequency_Hz` | Sampling frequency (Hz) | 6000 |
| `base_frequency_Hz` | Base frequency (Hz) | 60 |
| `base_power_VA` | Base power (VA) | 1 |
| `base_voltage_V` | Base voltage (V) | 1 |

`advance`:

| Field | Setting | Checked-in value |
| --- | --- | --- |
| `discretization_method` | Discretization method | 2 |
| `linearization_times` | Linearization times | 1 |
| `discretization_damping_flag` | Discretization damping flag | 1 |
| `direct_feedthrough` | Direct feedthrough | 0 |
| `power_flow_algorithm` | Power flow algorithm (1 GS, 2 NR) | 2 |
| `create_simulink_model` | Create Simulink model | 0 |
| `plot_pole_map` | Plot pole map | 0 |
| `plot_admittance` | Plot admittance | 0 |
| `print_output` | Print power-flow and port strings | 0 |
| `modal_analysis` | Participation / modal analysis | 0 |

`lines.form` is `"ieee"` for the checked-in case. The run prints `Warning: Line data in IEEE form is enabled, which over-writes the original line data.` IEEE branches use `R_pu`, `X_pu`, `B_pu`, `G_pu`, `turns_ratio`. Toolbox form uses `R_pu`, `wL_pu`, `wC_pu`, `G_pu`, `turns_ratio`.

Example netlists under `Examples/` are the same JSON schema (`IEEE_14Bus.json`, `SgInfiniteBus.json`, hybrid cases, and so on). Historical `.xlsx` copies remain in those folders; the program does not read them.

The checked-in case is the 68-bus full-model family (`ApparatusModelCreate.m` calls types 30–39 "full models for 68 bus"). Bus numbers in the line list reach 68. Apparatus codes used in this file:

| Code | Model |
| --- | --- |
| 18 | Grid-following VSI, old dq model (`GridFollowingVSI_old`) |
| 33 | 8th-order synchronous machine plus governor (`SynchronousMachineFull_SM_GOV`) |
| 35 | 8th-order synchronous machine plus AVR, PSS, and governor (`SynchronousMachineFull_SMAVRPSSGOV`) |
| 100 | AC floating bus, inserted for any bus with no apparatus row |

`buses[].ac_or_dc` is 1 on the rows inspected, so there is no DC area. Power flow stays Newton-Raphson, and the DC-area block on participation analysis does not apply. `advance.modal_analysis` is 0, so `Main.m` skips `SimplusGT.Modal.ModalInitialise` after the pole calculation.

## Verified pole result (14 Nov 2026)

The run printed `Proper!`, `Stable!`, the Simulink and plot warnings, and `Warning: The modal (participation) analysis is disabled or the power system has a dc area.` Then `End: run successfully.`

- 1300 poles.
- None with real part above `1e-8` Hz. Largest real part was `2.119163e-13` Hz.
- No pole with imaginary part inside 5 Hz of 150 Hz.

Positive-frequency poles with `|imag - 150| <= 10` Hz, closest to the imaginary axis first:

| Real (Hz) | Imag (Hz) | Distance of imag to 150 Hz | Damping ratio |
| --- | --- | --- | --- |
| -41.47569091111 | 140.8781423409 | 9.1219 | 0.28242 |
| -77.12229497811 | 155.3263926315 | 5.3264 | 0.44472 |
| -92.80735055352 | 157.4332240436 | 7.4332 | 0.50783 |

The pole near 150 Hz that lies closest to the imaginary axis is

**-41.47569091111 + j140.8781423409 Hz**

(conjugate **-41.47569091111 − j140.8781423409 Hz**). In rad/s that is **-260.599 + j885.163**. Damping ratio `ζ = -real / abs(pole) = 0.2824`.

The pole whose frequency is nearest 150 Hz is a different mode: **-77.12229497811 + j155.3263926315 Hz**. Use the first one when the question is "closest to the imaginary axis" inside the 150 Hz neighborhood. The same selection is: positive imaginary part, `|imag - 150| <= 10`, then smallest `|real|`.

A wider ±20 Hz window also contains -35.89811161352 + j132.7684205427 Hz, which is closer to the axis but 17.2 Hz away from 150 Hz. It is outside the 10 Hz neighborhood used above.

## Participation analysis

`advance.modal_analysis` is 0 in the checked-in `input.json` (`ListAdvance(10)`). `Main.m` calls `SimplusGT.Modal.ModalInitialise` when that flag is 1 and `ListBus(:,12)` has no DC marker (`2`). The modal routines pull `ApparatusType`, `GminSS`, `GsysDSS`, and related names with `evalin('base', ...)`. Run `Main` from the base workspace (a script under `matlab -batch`, as above). A function wrapper hides those variables from `evalin('base')` and the modal stage will fail.

`ModalInitialise.m` writes `ModalConfig_<name>.json` under `Examples/ParticipationAnalysis/`. The folder must stay; its own README says the toolbox stores participation output there. For `input.json` the file is `Examples/ParticipationAnalysis/ModalConfig_input.json`. `SimplusGT.Modal.ConfigPath` builds that path with `fullfile`, so the same call works on Windows, Mac, and Linux.

The config is pretty-printed JSON with named lists (`state_pf`, `impedance_pf`, `enabling`) and the same 0/1 select flags as before. `MdAutoSel` is 0, so this step does not run the participation calculation. It writes the file, prints the path, and returns. Select modes in that file, save it, then run `SimplusGT.Modal.ModalAnalysis` from the base workspace. With `MdAutoSel = 1` the existing code would auto-select modes and call `ModalAnalysis`. Default is 0. After `ModalAnalysis` runs, results are written to `<stem>_modal.json` next to the netlist.

Under `matlab -batch`, the config file is not opened in a GUI. An interactive session opens it with `winopen` on Windows, `open` on Mac, and `xdg-open` on Linux when a display is set.

## Messages that are normal for this input

- `Line data in IEEE form is enabled, which over-writes the original line data.`
- `Warning: The auto creation of simulink model is disabled.`
- `Warning: The default plot of pole map is disabled.`
- `Warning: The default plot of admittance spectrum is disabled.`
- With `modal_analysis` set to 0, `Warning: The modal (participation) analysis is disabled or the power system has a dc area.` With it set to 1, that warning is absent and the run writes `ModalConfig_input.json`.

`Stable!` together with `End: run successfully.` is the success signature for the pole run.
