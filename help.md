# How to fill `input.json`

This is the field reference for a Simplus netlist. `main.m` sets `UserData = 'input.json'` and `SimplusGT.Toolbox.Main` reads that file. The same schema is used by every example under `Examples/`.

The program reads five top-level keys: `basic`, `advance`, `buses`, `lines`, `apparatuses`. A `notes` object may sit beside them. The program does not read `notes`.

Names in this document are the names the JSON must use. They are case-sensitive: `J` is read, `j` is ignored. A parameter you leave out keeps the default listed below. A parameter name that is not in that type's default list is stored and then ignored, so a typo keeps the default and does not raise an error.

Working files to copy from:

| File | What it contains |
| --- | --- |
| `input.json` | 68-bus NETS-NYPS case. IEEE lines. Apparatus types 18, 33, 35, and 100 |
| `Examples/AcPowerSystem/SingleApparatusInfiniteBus/SgInfiniteBus.json` | Synchronous machine (type 0) on an infinite bus |
| `Examples/AcPowerSystem/SingleApparatusInfiniteBus/GflInverterInfiniteBus.json` | Grid-following inverter (type 11) and a shunt capacitor |
| `Examples/AcPowerSystem/SingleApparatusInfiniteBus/GfmInverterInfiniteBus.json` | Grid-forming inverter (type 20) |
| `Examples/DcPowerSystem/SingleMachineInfiniteBus/GfdBuckInfiniteBus.json` | DC buck (type 1010) on a DC infinite bus |
| `Examples/HybridPowerSystem/Hybrid_test_v1.json` | AC machine, interlink (type 2001), DC buck |
| `Examples/AcPowerSystem/IEEE_14Bus/IEEE_14Bus.json` | IEEE network, simple synchronous machines |

## Contents

- [Shape of the file](#shape-of-the-file)
- [Values, defaults, and names](#values-defaults-and-names)
- [basic](#basic)
- [advance](#advance)
- [buses](#buses)
- [lines](#lines)
- [apparatuses](#apparatuses)
- [Simple synchronous machine (0, 1)](#simple-synchronous-machine-0-1)
- [Grid-following VSI (10, 11, 17, 18, 19)](#grid-following-vsi-10-11-17-18-19)
- [Grid-forming VSI (20, 28)](#grid-forming-vsi-20-28)
- [Full synchronous machine (30-35, 38, 39)](#full-synchronous-machine-30-35-38-39)
- [Cyprus full machine (41, 42)](#cyprus-full-machine-41-42)
- [Infinite and floating buses](#infinite-and-floating-buses)
- [DC buck (1010, 1011)](#dc-buck-1010-1011)
- [AC-DC interlink (2000, 2001)](#ac-dc-interlink-2000-2001)
- [Codes that fail](#codes-that-fail)
- [Small examples](#small-examples)
- [Errors you will see](#errors-you-will-see)

## Shape of the file

```json
{
  "basic": {
    "sampling_frequency_Hz": 10000,
    "base_frequency_Hz": 50,
    "base_power_VA": 100e6,
    "base_voltage_V": 230e3
  },
  "advance": {
    "discretization_method": 2,
    "linearization_times": 1,
    "discretization_damping_flag": 1,
    "direct_feedthrough": 0,
    "power_flow_algorithm": 2,
    "create_simulink_model": 0,
    "plot_pole_map": 0,
    "plot_admittance": 0,
    "print_output": 1,
    "modal_analysis": 0
  },
  "buses": [],
  "lines": { "form": "toolbox", "branches": [] },
  "apparatuses": []
}
```

`basic`, `advance`, and every bus and branch object must contain every field listed in the sections below. A missing field stops in MATLAB with "Reference to non-existent field". Apparatus `parameters` is the one optional object.

Order of work when you build a case:

1. Choose the system bases in `basic`. Every per-unit number in the file is on those bases, except the Cyprus machine, which has its own `Sbase_SM`.
2. Set `advance`. For a pole study of one AC network, use power-flow algorithm 2 and set the four plot/model flags to 0.
3. Number the buses `1` … `N` with no gaps. The lowest bus number in each area is the slack bus.
4. Write the lines in one form, IEEE or toolbox, for the whole file.
5. Put one apparatus on each bus that is a machine, inverter, infinite bus, or interlink. Leave a pure junction out; the program inserts a floating bus there.

## Values, defaults, and names

A field value may be:

- a number, including `1e-7` and `100e6`
- `true` or `false`, which become 1 and 0
- the strings `"inf"`, `"-inf"`, or `"nan"` in any letter case
- a numeric string such as `"0.05"`, which becomes a number
- a complex value written as `{"real": 1, "imag": 2}`

JSON has no infinity token. An open branch uses the string `"inf"`.

Apparatus parameters overlay a built-in default. Rules:

- Leave a parameter out to keep the default in the tables below.
- An empty `parameters` object, or no `parameters` key, keeps every default.
- A blank value is skipped and the default stays.
- The name must match the table, including capitals. `V_dc` and `Vdc` are different parameters on different apparatus families.
- An unknown name does not change the model.
- One `parameters` object may contain at most 50 names. The 51st is an error.
- Where a table lists `w0`, the default is `2*pi*base_frequency_Hz` from `basic`. You can override it per apparatus.

`w0` is in rad/s. Bandwidths whose names start with `f` are in Hz. The model multiplies those by `2*pi` and then builds the PI gains itself (`kp = w*L`, `ki = w^2*L/4` for a current loop, and the same shape for the voltage loop and the PLL). There is no JSON field for `kp` or `ki`.

## basic

All four fields are required. They set the per-unit system and the sample time. The checked-in `input.json` uses 6000 Hz, 60 Hz, and base power and voltage of 1, so the pu numbers in that file are already on a 1 VA, 1 V base.

| Field | Meaning |
| --- | --- |
| `sampling_frequency_Hz` | Sample rate. `Ts = 1/Fs` is stored on every apparatus and is the Simulink step. The continuous pole calculation uses the same `Ts` only inside the apparatus object. |
| `base_frequency_Hz` | Synchronous frequency in Hz. `Wbase = 2*pi*Fbase` is the default `w0` and the steady frequency used by the network. |
| `base_power_VA` | System power base in volt-amperes. Bus powers and apparatus pu data are on this base. |
| `base_voltage_V` | System voltage base in volts. Together with the power base it sets `Ibase = Sbase/Vbase` and `Zbase = Vbase/Ibase`. |

## advance

All ten fields are required. They are integers.

The pole calculation in `Main.m` reads fields 5 through 10 only. Fields 1 through 4 are copied onto the Simulink block masks when a model is created. They do not change the descriptor model `GsysDSS` or the poles.

| Field | What to write | What it does |
| --- | --- | --- |
| `discretization_method` | `1` Forward Euler, `2` Hybrid Trapezoidal, `3` Virtual Damping | Simulink discretization. Any other integer errors when the Simulink model is built. The pole script keeps the class default, which is 2. |
| `linearization_times` | `1` once, at the operating point, `2` on every simulation step | Simulink Jacobian. The pole script linearizes once. |
| `discretization_damping_flag` | `1` on, `0` off | Simulink virtual resistor that breaks the algebraic loop. |
| `direct_feedthrough` | `1` on, `0` off | Simulink direct feedthrough of the apparatus block. |
| `power_flow_algorithm` | `1` Gauss-Seidel, `2` Newton-Raphson | Any other value errors. If any bus has `ac_or_dc` equal to 2, the run forces Gauss-Seidel and prints a warning. |
| `create_simulink_model` | `1` build `mymodel_v1`, `0` skip | Forced off, with a warning, when there are 150 buses or more. |
| `plot_pole_map` | `1` plot, `0` skip | Two figures, full and zoomed. Both axes are in Hz. `pole_sys = pole(GsysDSS)/(2*pi)`. |
| `plot_admittance` | `1` plot, `0` skip | Bode magnitude of the driving-point admittance at each active apparatus bus, from 0.1 Hz to 10 kHz. |
| `print_output` | `1` print, `0` skip | Prints the power flow as `\| bus \| P \| Q \| V \| angle \| omega \|` and the port lists. P and Q in that print are in load convention: positive when power flows from the bus into the apparatus. |
| `modal_analysis` | `1` or `0` | `1` writes `Examples/ParticipationAnalysis/ModalConfig_<name>.json` and returns. The participation math stays off until you edit that file and call `SimplusGT.Modal.ModalAnalysis`. `1` is ignored, with a warning, when any bus is DC. |

Newton-Raphson in this toolbox is a single-slack solver: the mismatch drops bus 1, and bus 1 has to be the slack. Use it for one AC area. Gauss-Seidel updates every bus whose `type` is not 1, so it is the solver that honors a slack in every area. A DC area always selects Gauss-Seidel.

## buses

`buses` is an array of objects. Every object has these twelve fields.

| Field | Meaning |
| --- | --- |
| `bus` | Bus number. Use the integers `1` … `N`, once each, with no gaps. The nodal matrix is sized by the largest number, and a pure AC system looks apparatuses up by the numbers `1` … `N`. |
| `type` | AC: `1` slack, `2` PV, `3` PQ. DC: `1` voltage slack, `3` P bus. |
| `Vsp_pu` | Voltage magnitude set-point in pu. Held for slack and PV. Initial guess for PQ and for a DC P bus. |
| `theta_rad` | Voltage angle in radians. Initial guess. The slack angle stays at the value you write. Use `0` on the slack unless you want a non-zero angle reference. |
| `PGi_pu` | Active power injected into the bus by generation, source convention, pu. |
| `QGi_pu` | Reactive power injected into the bus by generation, source convention, pu. |
| `PLi_pu` | Active power drawn from the bus by a load, load convention, pu. Must be ≥ 0. |
| `QLi_pu` | Reactive power drawn from the bus by a load, load convention, pu. Positive QLi is an inductive load. |
| `Qmin_pu` | Lower reactive-power limit of a PV bus, pu. |
| `Qmax_pu` | Upper reactive-power limit of a PV bus, pu. |
| `area` | Area index. Use `1` … `N_area` with no gaps. |
| `ac_or_dc` | `1` AC, `2` DC. |

Net scheduled injection is `PGi_pu - PLi_pu` and `QGi_pu - QLi_pu`. A generator is a positive `PGi_pu`. A load is a positive `PLi_pu`. You can put both on the same bus.

After the power flow, the load is moved onto the network as a shunt. The apparatus model then sees the power that flows from the bus into the apparatus. For a generator that power is negative. You do not write that sign yourself. You write `PGi_pu` positive.

### Bus type

AC:

| `type` | Name | What is fixed | What is solved |
| --- | --- | --- | --- |
| 1 | Slack | `Vsp_pu`, `theta_rad` | P and Q. The `PGi_pu` and `QGi_pu` you wrote on the slack are not held. |
| 2 | PV | `PGi_pu - PLi_pu`, `Vsp_pu` | Q and the angle. Q is checked against `Qmin_pu` and `Qmax_pu`. |
| 3 | PQ | `PGi_pu - PLi_pu`, `QGi_pu - QLi_pu` | Voltage magnitude and angle. `Vsp_pu` is only the starting guess. |

DC:

| `type` | Name | What is fixed |
| --- | --- | --- |
| 1 | Voltage slack | `Vsp_pu`. This bus covers the DC power balance. |
| 3 | P bus | `PGi_pu - PLi_pu`. Voltage is solved. |

A DC bus with `type` 2 is an error. A file that contains any DC area also rejects `type` 2 on every bus, including AC buses. The error text is `The bus type in dc network can not be 2!`. An AC/DC case that needs PV machines on the AC side cannot use `type` 2 while a DC area is present. The hybrid examples use types 1 and 3 only.

Q limits apply to PV buses.

- Gauss-Seidel: if the solved Q is outside `[Qmin_pu, Qmax_pu]`, Q is clamped and the bus is treated as PQ for the rest of the iterations.
- Newton-Raphson: on iterations 3 through 7, a PV bus whose generator Q is below `Qmin_pu` has its voltage raised by 0.01 pu, and a bus above `Qmax_pu` has its voltage lowered by 0.01 pu. The bus stays type 2.

### Areas

- Area numbers are `1`, `2`, … with no missing index. A single network uses `"area": 1` on every bus.
- Every bus in one area has the same `ac_or_dc`.
- Each area has exactly one slack (`type` 1).
- Within an area, the slack must be the lowest bus number. For a single area that means bus 1 is the slack.
- A line cannot connect an AC bus to a DC bus. The interlink apparatus is the connection between areas.

On a pure AC system whose every bus has `"area": 1`, the program sorts apparatuses into bus-number order after reading the file. The row order you wrote does not matter. If any bus has `area` of 2 or higher, or any bus is DC, the program keeps the row order and then appends floating buses for the buses you left empty.

## lines

```json
"lines": {
  "form": "ieee",
  "branches": [
    {
      "from": 1,
      "to": 2,
      "R_pu": 0.01,
      "X_pu": 0.1,
      "B_pu": 0.02,
      "G_pu": 0,
      "turns_ratio": 1
    }
  ]
}
```

`form` is `"ieee"` or `"toolbox"`. One form covers the whole file. `branches` is an array. A single branch may be one object instead of a one-element array. An empty branch list is allowed; a bus still needs an apparatus or it becomes a floating bus.

Both forms store the same seven numbers: from, to, series resistance, series reactance, shunt susceptance, shunt conductance, turns ratio. The names of the middle columns differ.

| Role | IEEE name | Toolbox name | Unit |
| --- | --- | --- | --- |
| Series resistance | `R_pu` | `R_pu` | pu |
| Series reactance ωL | `X_pu` | `wL_pu` | pu |
| Shunt susceptance ωC | `B_pu` | `wC_pu` | pu |
| Shunt conductance | `G_pu` | `G_pu` | pu |
| Off-nominal tap | `turns_ratio` | `turns_ratio` | voltage ratio |

IEEE and toolbox differ in where the shunt sits.

- Toolbox. `wL_pu` and `wC_pu` belong to that branch element. A series line usually has `"wC_pu": 0`. A shunt capacitor is its own branch with `from` equal to `to`, `R_pu` and `wL_pu` equal to `"inf"`, and `wC_pu` set to the susceptance. A shunt inductor is a self-branch with `R_pu` of 0 and `wL_pu` set to the reactance. See the capacitor self-branch in `GflInverterInfiniteBus.json`.
- IEEE. `X_pu` is the series reactance. `B_pu` and `G_pu` are the total pi-model shunt of the line. The program moves half of `B_pu` and half of `G_pu` onto each terminal as a shunt self-branch. A self-branch written in IEEE form must have `R_pu` and `X_pu` equal to `"inf"` and `turns_ratio` equal to 1.

Checks that reject a branch:

- Toolbox: infinite `R_pu` or `wL_pu` together with zero `wC_pu` and zero `G_pu` is an open circuit.
- IEEE: that same open element is deleted during the conversion, so a spare open line in IEEE form disappears. The run prints `Line data in IEEE form is enabled, which over-writes the original line data.`
- `R_pu` and the reactance both 0, or an infinite susceptance or conductance, is a short circuit.
- Negative R, X, B, or G.
- `turns_ratio` less than or equal to 0.
- A self-branch whose resistance is neither 0 nor infinite.
- `from` and `to` in different `ac_or_dc` areas.

`turns_ratio` is the from-side tap. The nodal contributions are off-diagonal `-Y/T`, from-bus diagonal `+Y/T^2`, to-bus diagonal `+Y`, with `Y` the branch admittance. If `from` is greater than `to`, the program swaps the ends, multiplies R and X by `T^2`, and replaces `T` by `1/T`, so the physical ratio is unchanged. Write the lower bus number in `from`.

On a DC branch the power flow uses `R_pu` and `G_pu` only, because the DC frequency is zero. A DC branch with `R_pu` of 0 and infinite `G_pu` is an error. Give every DC line a positive `R_pu`.

## apparatuses

`apparatuses` is an array of objects.

```json
{
  "bus": 2,
  "type": 10,
  "parameters": { "wLf": 0.05, "f_pll": 20 }
}
```

| Field | Meaning |
| --- | --- |
| `bus` | One bus number, or a two-element array for an interlink. |
| `type` | Integer code from the catalog below. |
| `parameters` | Optional object. Names depend on the type family. Omitted names keep that family's defaults. |

One apparatus connects to each bus. A second object that names the same bus is an error (`For each bus, one and only one apparatus has to be connected.`). A bus with no object gets an AC floating bus (type 100) or a DC floating bus (type 1100), chosen from `ac_or_dc`.

An interlink is the only apparatus with two buses: `"bus": [3, 2]`. The AC bus must end up first. If the first number is a DC bus, the program swaps the pair. The hybrid example writes the DC bus first and relies on that swap.

The type code selects a family by `floor(type/10)`, then a subtype inside the class. Codes in the next table run. Codes in [Codes that fail](#codes-that-fail) are rejected or point at a missing file.

| Code | Model | Parameter family |
| --- | --- | --- |
| 0 | Synchronous machine, torque swing equation | Simple machine |
| 1 | Synchronous machine, power swing equation, constant internal voltage | Simple machine |
| 10 | Grid-following VSI with dc link | Grid-following |
| 11 | Grid-following VSI, current loop and PLL, no dc link | Grid-following |
| 17 | Same as 10 for the pole calculation. Simulink forces the current bandwidth to 160 Hz after 10 s | Grid-following |
| 18 | Older grid-following VSI. This is the inverter in `input.json` | Grid-following |
| 19 | Grid-following VSI. Same poles as 10 at t = 0. Simulink rescales L, R, and C after 10 s | Grid-following |
| 20 | Grid-forming droop VSI | Grid-forming |
| 28 | Older grid-forming droop VSI | Grid-forming |
| 30 | 8th-order synchronous machine | Full machine |
| 31 | 8th-order machine plus AVR | Full machine |
| 32 | 8th-order machine plus AVR and PSS | Full machine |
| 33 | 8th-order machine plus governor | Full machine |
| 34 | 8th-order machine plus AVR and governor | Full machine |
| 35 | 8th-order machine plus AVR, PSS, and governor | Full machine |
| 38 | Type 33 with a temporary damping boost in Simulink | Full machine |
| 39 | Type 35 with a temporary damping boost in Simulink | Full machine |
| 41 | Cyprus 8th-order machine plus AVR | Cyprus |
| 42 | Cyprus 8th-order machine plus AVR, PSS, and governor | Cyprus |
| 90 | AC infinite bus. 91–99 select the same class | none |
| 100 | AC floating bus. 101–109 select the same class | none |
| 1010 | DC grid-feeding buck, current set by the power flow | Buck |
| 1011 | DC grid-feeding buck with dc-link voltage control | Buck |
| 1090 | DC infinite bus. 1091–1099 select the same class | none |
| 1100 | DC floating bus. 1101–1109 select the same class | none |
| 2000 | AC–DC interlink, AC current set by AC power | Interlink |
| 2001 | AC–DC interlink, AC current set by the dc-voltage loop | Interlink |

Every dynamic model is in load convention and admittance form: the electrical input is the bus voltage and the electrical output is the current into the apparatus. Infinite buses are the other way around (current in, voltage out) and the program swaps those ports.

## Simple synchronous machine (0, 1)

Class: `+SimplusGT/+Class/SynchronousMachine.m`.

Classical machine. States `i_d`, `i_q`, `w`, `theta`. Inputs `v_d`, `v_q`, `T_m`, `v_ex`. The q axis leads the d axis and is aligned with the field flux, which is the opposite of the Kundur convention.

`J` in the JSON is the inertia constant in seconds, the quantity `(1/2) J ω0² / Sbase`. The class converts it with `J_internal = J * 2 / w0²` because rotor speed in this model is in rad/s. `D` is converted with `D_internal = D / w0²`. `wL` and `R` are pu on the system base, and `L = wL / w0`.

| `type` | Dynamics |
| --- | --- |
| 0 | Swing equation in torque, `J dw/dt = Te - Tm - D w`, with the stator flux inside the electrical equations. This variant has more damping than type 1. |
| 1 | Swing equation in power. The internal voltage magnitude is held at `psi_f*w0`, so the flux inductance can sit outside the machine. |

| Name | Meaning | Default |
| --- | --- | --- |
| `J` | Inertia constant (s) | 3.5 |
| `D` | Damping coefficient before the `/w0²` scaling | 1 |
| `wL` | Stator reactance (pu) | 0.05 |
| `R` | Stator resistance (pu) | 0.01 |
| `w0` | Electrical base speed (rad/s) | `2*pi*base_frequency_Hz` |

`SgInfiniteBus.json` overrides `J`, `D`, `wL`, and `R` and leaves `w0` at the base.

## Grid-following VSI (10, 11, 17, 18, 19)

Classes: `GridFollowingVSI.m` for 10, 11, and 17; `GridFollowingVSI_old.m` for 18; `GridFollowingVSI_SC.m` for 19.

AC side is load convention. The DC side is source convention. The current controller is a dq PI. The PLL in the pole model is a vq-PLL (`e = v_q - ang_r`). Theta-PLL and Q-PLL exist in the source as other `switch` cases and are not selected. Current and voltage limits in `GridFollowingVSI.m` are compiled off (`EnableSaturation = 0`), so they do not affect the poles.

States for a type with a dc link: `i_d`, `i_q`, `i_d_i`, `i_q_i`, `w_pll_i`, `w`, `theta`, `v_dc`, `v_dc_i`. Type 11 stops before `v_dc`. The `_i` states are integrator states.

All five codes share one default list. A field the subtype does not read still has to be spelled correctly if you write it; a wrong spelling is ignored.

| Name | Meaning | Default | Where it is used |
| --- | --- | --- | --- |
| `V_dc` | DC-link voltage reference (pu) | 2.5 | 10, 17, 18, 19. Type 11 has no dc-link state. Type 18 does not scale this value. |
| `C_dc` | DC-link capacitance (pu) | 1.25 | 10, 17, 19. Type 18 multiplies it by `Sbase`. |
| `f_v_dc` | DC-voltage loop bandwidth (Hz) | 5 | Types that have the dc-link loop. |
| `wLf` | AC filter reactance (pu) | 0.03 | Every code. `L = wLf/w0`, except type 18, which uses `L = wLf/(w*Sbase)` with `w` from the power flow. |
| `R` | AC filter resistance (pu) | 0.01 | Every code. Type 18 divides it by `Sbase`. |
| `f_pll` | PLL bandwidth (Hz) | 5 | Every code. `kp_pll = 2*pi*f_pll`, `ki_pll = kp_pll * 2*pi*f_pll / 4`. |
| `f_tau_pll` | PLL low-pass bandwidth (Hz) | 300 | 10, 11, 17, 19. Type 18 uses 200 Hz and does not read this field. |
| `f_i_dq` | Current-loop bandwidth (Hz) | 600 | Every code. Type 17, in Simulink, replaces this with 160 Hz after 10 s. The pole calculation uses the JSON value. |
| `w0` | Base angular frequency (rad/s) | `2*pi*base_frequency_Hz` | 10, 11, 17, 19. Type 18 uses the power-flow frequency. |
| `Sbase` | Apparatus rating divided by `base_power_VA` | 1 | Type 18, scaling `C_dc`, `L`, and `R`. The other four codes do not read it. |

| `type` | DC link |
| --- | --- |
| 10 | Capacitor and voltage loop. Capacitor current is `(e_d i_d + e_q i_q - P_dc) / (v_dc C_dc)`. |
| 11 | No dc link. Current reference comes from the power flow. `V_dc`, `C_dc`, and `f_v_dc` do not enter the dynamics. |
| 17 | Same equations as 10. Simulink-only change of `f_i_dq` after 10 s. |
| 18 | DC link, vq-PLL, PLL filter fixed at 200 Hz, `Sbase` scaling as in the table. This is the inverter used throughout `input.json`. |
| 19 | Same small-signal model as 10 when the simulation time is 0, which is when the poles are computed. In Simulink, after 10 s, `wLf` and `R` are divided by 1.5 and `C_dc` is multiplied by 1.5. |

## Grid-forming VSI (20, 28)

Classes: `GridFormingVSI.m` for 20, `GridFormingVSI_old.m` for 28.

Droop-controlled inverter with an LC-L filter, a voltage loop, and a current loop. States: `i_ld`, `i_lq`, `i_ld_i`, `i_lq_i`, `v_od`, `v_oq`, `v_od_i`, `v_oq_i`, `i_od`, `i_oq`, `v_d_ref`, `w`, `theta`.

The active droop is P–ω. The Q–V droop is compiled out: type 20 takes `switch` case 3, which holds the voltage reference, and type 28 holds it as well. Virtual resistance `Rov` is 0 in the source. Those are not JSON fields.

| Name | Meaning | Default |
| --- | --- | --- |
| `wLf` | Inverter-side filter reactance (pu) | 0.05 |
| `Rf` | Inverter-side filter resistance (pu) | 0.01 |
| `wCf` | Filter capacitor susceptance (pu) | 0.02 |
| `wLc` | Grid-side reactance (pu) | 0.01 |
| `Rc` | Grid-side resistance (pu) | 0.002 |
| `Xov` | Virtual reactance in the voltage controller (pu) | 0.01 |
| `Dw` | P–ω droop gain | 0.05 |
| `fdroop` | Droop measurement bandwidth (Hz) | 5 |
| `fvdq` | Voltage-loop bandwidth (Hz) | 300 |
| `fidq` | Current-loop bandwidth (Hz) | 600 |
| `Sbase` | See the two type rows. Default 1 | 1 |

There is no `w0` field on this family.

| `type` | How `Sbase` is applied |
| --- | --- |
| 20 | The class uses the number in `Sbase` as the angular-frequency base `W0`. Inductance and capacitance are `wL/Sbase` and `wC/Sbase`. The droop gain becomes `Dw*Sbase`. The frequency reference is `Sbase + (Dw*Sbase)*(P0 - p)`. The power-flow frequency is `2*pi*base_frequency_Hz`, so a consistent equilibrium needs `"Sbase"` equal to that number. With the default `Sbase` of 1 the droop reference is 1 rad/s. |
| 28 | `Sbase` is a power base and the frequency base is the power-flow frequency. `wLf`, `Rf`, `wLc`, and `Xov` are divided by `Sbase`. `wCf`, `Rc`, and `Dw` are multiplied by `Sbase`. `Dw` is also multiplied by the power-flow frequency. The default `Sbase` of 1 leaves the pu values unchanged. `Rc` moves in the opposite direction from `Rf` when `Sbase` is not 1. |

`GfmInverterInfiniteBus.json` sets every field except `Sbase`, so type 20 there runs with `Sbase` equal to 1.

## Full synchronous machine (30-35, 38, 39)

Classes: `SynchronousMachineFull_SM.m`, `_SMAVR.m`, `_SMAVRPSS.m`, `_SM_GOV.m`, `_SMAVRGOV.m`, `_SMAVRPSSGOV.m`, `_SMGOV_FS.m`, `_SMAVRPSSGOV_FS.m`.

8th-order machine (Sauer and Pai, *Power System Dynamics and Stability*). Reactances are pu on the system base (`basic.base_power_VA`). Time constants and `H` are in seconds. This is the machine family in `input.json`: type 33 where the file has a governor only, type 35 where it has AVR, PSS, and governor.

Machine states on every code: `id`, `iq`, `w`, `theta`, `Ed1`, `Eq1`, `Psi1d`, `Psi2q`.

- `Ed1`, `Eq1`: transient voltages from the d- and q-axis flux.
- `Psi1d`, `Psi2q`: sub-transient flux from the damper windings.

Added states:

| Blocks | Extra states |
| --- | --- |
| AVR | `Efd`, `Vr`, `Rf`, `Va`, `Vx1`, `Vx2` |
| PSS | `Vss1`, `Vss2`, `Vss3`, `Vss` |
| Governor | `G2` turbine power, `G3` valve position, `T_m` mechanical torque |

Electrical inputs are `v_d` and `v_q`. The remaining inputs are whatever that code does not regulate itself: type 30 takes `T_m` and `Efd`; type 33 takes `Efd` and a torque reference; type 35 takes a torque reference and a voltage reference.

### Which code includes which blocks

| `type` | Machine | AVR | PSS | Governor | Simulink-only note |
| --- | --- | --- | --- | --- | --- |
| 30 | yes | | | | `T_m` and `Efd` are external inputs |
| 31 | yes | yes | | | `T_m` and `Vss` are external inputs |
| 32 | yes | yes | yes | | `T_m` is an external input |
| 33 | yes | | | yes | Used in `input.json` |
| 34 | yes | yes | | yes | `Vss` is an external input |
| 35 | yes | yes | yes | yes | Used in `input.json` |
| 38 | yes | | | yes | While Simulink time is in `(0, 5]` seconds, `D` is replaced by `3*H`. At time 0, and for the pole calculation, `D` is the JSON value. |
| 39 | yes | yes | yes | yes | Same temporary `D` as type 38. |

Writing an AVR parameter on a type 30 or 33 is accepted and ignored. The default struct always contains the full set, and each class reads only the indices for its own blocks.

### Machine parameters (every code 30–39)

| Name | Meaning | Default |
| --- | --- | --- |
| `X` | Armature leakage reactance (pu) | 0.0125 |
| `R` | Armature resistance (pu) | 0 |
| `Xd` | d-axis synchronous reactance (pu) | 0.1 |
| `Xd1` | d-axis transient reactance (pu) | 0.031 |
| `Xd2` | d-axis sub-transient reactance (pu) | 0.025 |
| `Td1` | d-axis open-circuit transient time constant (s) | 10.2 |
| `Td2` | d-axis open-circuit sub-transient time constant (s) | 0.05 |
| `Xq` | q-axis synchronous reactance (pu) | 0.069 |
| `Xq1` | q-axis transient reactance (pu) | 0.0416667 |
| `Xq2` | q-axis sub-transient reactance (pu) | 0.025 |
| `Tq1` | q-axis open-circuit transient time constant (s) | 1.5 |
| `Tq2` | q-axis open-circuit sub-transient time constant (s) | 0.035 |
| `H` | Inertia constant (s) | 42 |
| `D` | Damping coefficient | 0 |

`Xd`, `Xd1`, and `Xd2` must stay distinct, and the same for the q axis. The current equations divide by `Xd1 - X`, `Xd1 - Xd2`, `Xq1 - X`, and `Xq1 - Xq2`.

### AVR parameters (types 31, 32, 34, 35, 39)

The exciter is the DC4B-style block in the class: transducer `TR`, regulator `KA`/`TA`, exciter `KE`/`TE`, saturation from the two points `(E1, SE1)` and `(E2, SE2)`, rate feedback `KF`/`TF`, and a PID (`KP`, `KI`, `KD`, `TD`) on the voltage error. Names are uppercase. The Cyprus family uses different names for its exciter.

| Name | Meaning | Default |
| --- | --- | --- |
| `TR` | Voltage transducer time constant (s) | 0.01 |
| `KA` | Regulator gain | 1 |
| `TA` | Regulator time constant (s) | 0.02 |
| `VRmax` | Regulator ceiling (pu) | 10 |
| `VRmin` | Regulator floor (pu) | -10 |
| `KE` | Exciter gain | 1 |
| `TE` | Exciter time constant (s) | 0.785 |
| `E1` | Saturation voltage, first point (pu) | 3.9267 |
| `SE1` | Saturation factor at `E1` | 0.07 |
| `E2` | Saturation voltage, second point (pu) | 5.2356 |
| `SE2` | Saturation factor at `E2` | 0.91 |
| `KF` | Rate-feedback gain | 0.03 |
| `TF` | Rate-feedback time constant (s) | 1 |
| `KP` | Voltage-error proportional gain | 200 |
| `KI` | Voltage-error integral gain | 50 |
| `KD` | Voltage-error derivative gain | 50 |
| `TD` | Derivative filter time constant (s) | 0.01 |

`SE1` and `SE2` must both be positive. The class computes the saturation exponential from `log(SE1/SE2)/(E1-E2)`.

### PSS parameters (types 32, 35, 39)

Three lead-lag stages and a washout, input `Sm = (w - ws)/ws`.

| Name | Meaning | Default |
| --- | --- | --- |
| `KPSS` | PSS gain | 20 |
| `TW` | Washout time constant (s) | 15 |
| `T11` | First lead time constant (s) | 0.15 |
| `T12` | First lag time constant (s) | 0.04 |
| `T21` | Second lead time constant (s) | 0.15 |
| `T22` | Second lag time constant (s) | 0.04 |
| `T31` | Third lead time constant (s) | 0.15 |
| `T32` | Third lag time constant (s) | 0.04 |
| `VSSmax` | PSS output ceiling (pu) | 0.2 |
| `VSSmin` | PSS output floor (pu) | -0.05 |

### Governor parameters (types 33, 34, 35, 38, 39)

| Name | Meaning | Default |
| --- | --- | --- |
| `Rgov` | Droop | 0.05 |
| `T1gov` | Governor time constant (s) | 0.1 |
| `T2gov` | Turbine time constant (s) | 1.6 |
| `T3gov` | Turbine time constant (s) | 10 |
| `Dtgov` | Turbine damping | 0.2 |

The 68-bus machines in `input.json` override the machine parameters and, on type 35, the AVR and PSS. They leave the governor at these defaults. Copy that pattern: write the data you have, and leave the rest out.

## Cyprus full machine (41, 42)

Classes: `SynchronousMachineFull_Cyp_SMAVR.m` for 41, `SynchronousMachineFull_Cyp_SMAVRPSSGOV.m` for 42. The class header calls the exciter an IEEE type T1.

Same 8th-order machine, with data on the machine base. `Sbase_SM` is `S_machine / S_system`.

- Divided by `Sbase_SM`: `X`, `R`, `Xd`, `Xd1`, `Xd2`, `Xq`, `Xq1`, `Xq2`, `Rgov`.
- Multiplied by `Sbase_SM`: `H`, `D`, `Dpu`, `Pmax_gov`.
- Left as written: every time constant, the AVR gains, the PSS, `Fgov`, `SG10`, `SG12`, `w0`.

With the default `Sbase_SM` of 1 the machine base and the system base are the same.

| `type` | Blocks | States beyond the machine |
| --- | --- | --- |
| 41 | Machine and AVR | `Efd`, `V1`, `Vr`, `Vf`. Governor and PSS names are accepted and ignored. |
| 42 | Machine, AVR, PSS, and governor | Those four, plus `Vssw`, `Vss1`, `Vss`, and governor states `Ptg1`, `Ptg2`, `Ptg3`, `T_m_in`. |

### Machine and base

| Name | Meaning | Default |
| --- | --- | --- |
| `Sbase_SM` | Machine base / system base | 1 |
| `X` | Armature leakage reactance (machine pu) | 0.0125 |
| `R` | Armature resistance (machine pu) | 0 |
| `Xd` | d-axis synchronous reactance (machine pu) | 0.1 |
| `Xd1` | d-axis transient reactance (machine pu) | 0.031 |
| `Xd2` | d-axis sub-transient reactance (machine pu) | 0.025 |
| `Td1` | d-axis transient time constant (s) | 10.2 |
| `Td2` | d-axis sub-transient time constant (s) | 0.05 |
| `Xq` | q-axis synchronous reactance (machine pu) | 0.069 |
| `Xq1` | q-axis transient reactance (machine pu) | 0.0416667 |
| `Xq2` | q-axis sub-transient reactance (machine pu) | 0.025 |
| `Tq1` | q-axis transient time constant (s) | 1.5 |
| `Tq2` | q-axis sub-transient time constant (s) | 0.035 |
| `H` | Inertia constant (s, machine base) | 42 |
| `D` | Damping (machine base) | 0 |
| `Dpu` | Extra damping, scaled by `Sbase_SM` | 0 |
| `SG10` | Saturation factor at 1.0 pu voltage | 1 |
| `SG12` | Saturation factor at 1.2 pu voltage | 1 |
| `w0` | Speed base inside the model (rad/s) | `2*pi*base_frequency_Hz` |

### AVR (types 41 and 42)

These names are lowercase. `SEE1` and `SEE2` are not the `SE1` and `SE2` of types 30–39. Writing the uppercase type-35 names on a Cyprus machine does nothing.

| Name | Meaning | Default |
| --- | --- | --- |
| `Tr` | Transducer time constant (s) | 0 |
| `Ka` | Regulator gain | 50 |
| `Ta` | Regulator time constant (s) | 0.06 |
| `Vrmax` | Regulator ceiling (pu) | 1 |
| `Vrmin` | Regulator floor (pu) | -1 |
| `Ke` | Exciter constant | -0.0465 |
| `Te` | Exciter time constant (s) | 0.520 |
| `Kf` | Rate-feedback gain | 0.0832 |
| `Tf` | Rate-feedback time constant (s) | 1.0 |
| `E1` | Saturation voltage, first point (pu) | 3.24 |
| `SEE1` | Saturation factor at `E1` | 0.072 |
| `E2` | Saturation voltage, second point (pu) | 4.320 |
| `SEE2` | Saturation factor at `E2` | 0.2821 |

### PSS (type 42)

| Name | Meaning | Default |
| --- | --- | --- |
| `T1` | First lead time constant (s) | 5 |
| `T2` | First lag time constant (s) | 0.6 |
| `T3` | Second lead time constant (s) | 3 |
| `T4` | Second lag time constant (s) | 0.5 |
| `Tw` | Washout time constant (s) | 10 |
| `Kpss` | PSS gain | 1 |
| `Vpssmin` | PSS output floor (pu) | -0.2 |
| `Vpssmax` | PSS output ceiling (pu) | 0.2 |

### Governor (type 42)

| Name | Meaning | Default |
| --- | --- | --- |
| `Rgov` | Droop, then divided by `Sbase_SM` | 0.011 |
| `T1gov` | Governor time constant (s) | 0.1 |
| `T2gov` | Governor time constant (s) | 0 |
| `T3gov` | Turbine time constant (s) | 0.3 |
| `T4gov` | Turbine time constant (s) | 0.05 |
| `T5gov` | Turbine time constant (s) | 10 |
| `Fgov` | Turbine power fraction | 0.25 |
| `Pmax_gov` | Power limit, then multiplied by `Sbase_SM` | 1 |

## Infinite and floating buses

These codes take no parameters. A `parameters` object on them is ignored.

| `type` | Class | Meaning |
| --- | --- | --- |
| 90 | `InfiniteBusAc` | AC infinite bus. In the small-signal model it is a short circuit: voltage and frequency stay at the power-flow values, and current is the input. Put it on the slack bus of a single-apparatus study. Codes 91–99 build the same class. |
| 100 | `FloatingBusAc` | AC open circuit, no states. Use it on a junction, or leave the bus out of `apparatuses` and the program inserts type 100. Codes 101–109 build the same class. `IEEE_57Bus.json` writes type 100 on the load buses. |
| 1090 | `InfiniteBusDc` | DC infinite bus. Voltage fixed, current is the input. Codes 1091–1099 build the same class. |
| 1100 | `FloatingBusDc` | DC open circuit, no states. Codes 1101–1109 build the same class. Inserted automatically on a DC bus with no apparatus row. |

The class files `PassiveLoad.m`, `Inductor.m`, `SynchronousMachineStationary.m`, and `ModelTemplate.m` are not selected by any type code.

## DC buck (1010, 1011)

Class: `GridFeedingBuck.m`.

Grid-feeding buck converter. The DC grid side is load convention. The source side is source convention. Type 1010 states are `i` and `i_i`. Type 1011 adds `v_dc` and `v_dc_i`.

The parameter names have no underscore. `V_dc` from the AC inverter list does not set this model.

| Name | Meaning | Default | Where it is used |
| --- | --- | --- | --- |
| `Vdc` | DC-link voltage reference (pu) | 2 | Both. Type 1010 uses it as the fixed link voltage. |
| `Cdc` | DC-link capacitance (pu) | 0.8 | Type 1011. |
| `wL` | Output reactance (pu). `L = wL/w0` | 0.05 | Both. |
| `R` | Output resistance (pu) | 0.01 | Both. |
| `fi` | Current-loop bandwidth (Hz) | 600 | Both. |
| `fvdc` | Voltage-loop bandwidth (Hz) | 5 | Type 1011. |
| `w0` | Base angular frequency (rad/s) | `2*pi*base_frequency_Hz` | Both. |

| `type` | Current reference |
| --- | --- |
| 1010 | `P/V` from the power flow. No dc-link state. `GfdBuckInfiniteBus.json` uses this code with every parameter at the default. |
| 1011 | The dc-link voltage loop. |

## AC-DC interlink (2000, 2001)

Class: `InterlinkAcDc.m`.

The source file says the model is not ready for use. `Hybrid_test_v1.json` and `Hybrid_test_v2.json` still run types 2001 and 2000, and the description below matches those classes. The model is one three-phase voltage-source inverter, not a back-to-back converter. The AC port and the DC port are both in load convention. An inductor sits between the DC grid and the DC link so the admittance seen from the DC side stays proper.

`"bus"` is two numbers. After the automatic swap the first is the AC bus and the second is the DC bus. The apparatus occupies both buses, so neither bus has another apparatus row.

States: `i_d`, `i_q`, `i_d_i`, `i_q_i`, `w_pll_i`, `w`, `theta`, `v_dc`, `v_dc_i`, `i`. The q-axis current reference is held at the power-flow value.

| Name | Meaning | Default |
| --- | --- | --- |
| `C_dc` | DC-link capacitance (pu) | 1.6 |
| `wL_ac` | AC filter reactance (pu) | 0.05 |
| `R_ac` | AC filter resistance (pu) | 0.01 |
| `wL_dc` | Reactance between the DC link and the DC grid (pu) | 0.02 |
| `R_dc` | Resistance of that branch (pu) | 0.004 |
| `fidq` | AC current-loop bandwidth (Hz) | 600 |
| `fvdc` | DC-voltage loop bandwidth (Hz) | 5 |
| `fpll` | PLL bandwidth (Hz) | 5 |
| `w0` | Base angular frequency (rad/s) | `2*pi*base_frequency_Hz` |

The PLL low-pass inside this class is fixed at 200 Hz. There is no JSON field for it.

| `type` | d-axis current reference |
| --- | --- |
| 2000 | `P_ac / V_ac` from the power flow. The dc-voltage integrator is held at zero. |
| 2001 | The dc-voltage loop. This is the code in `Hybrid_test_v1.json`. |

## Codes that fail

| Code | What happens |
| --- | --- |
| 2–9 | The simple-machine class raises `Error.` |
| 12–16 | Dispatched to `GridFollowingInverterStationary`, which accepts only type 19, then raises `Invalid ApparatusType.` |
| 21–27, 29 | The grid-forming branch does not create an object, then raises `Error: apparatus type`. |
| 36, 37 | The full-machine branch does not create an object, then raises `Error: apparatus type`. |
| 40 | The factory calls `SynchronousMachineFull_Cyp_SM`. That file is not in the tree. |
| 43–49 | The Cyprus branch does not create an object, then raises `Error: apparatus type`. |
| 1012–1019 | `GridFeedingBuck` raises `Invalid ApparatusType.` |
| 2002–2009 | `InterlinkAcDc` raises `Invalid ApparatusType.` |
| Anything whose `floor(type/10)` is not 0, 1, 2, 3, 4, 9, 10, 101, 109, 110, or 200 | `Error: apparatus type, bus … type …` while the defaults are selected. |

## Small examples

### Synchronous machine on an infinite bus

Bus 1 is the slack and an AC infinite bus. Bus 2 is PQ with the machine power written as generation. The line is toolbox form. This is `SgInfiniteBus.json` with the advance flags shortened.

```json
{
  "bus": 1,
  "type": 90
}
```

```json
{
  "bus": 2,
  "type": 0,
  "parameters": { "J": 3.5, "D": 10, "wL": 0.3, "R": 0.003 }
}
```

Bus 2 in that file is `"type": 3` with `"PGi_pu": 0.9` and `"QGi_pu": 0.3`.

### Grid-following inverter

Type 11 needs no dc-link parameters. A shunt capacitor at bus 2 is a toolbox self-branch:

```json
{
  "from": 2,
  "to": 2,
  "R_pu": "inf",
  "wL_pu": "inf",
  "wC_pu": 0.02,
  "G_pu": 0,
  "turns_ratio": 1
}
```

```json
{
  "bus": 2,
  "type": 11,
  "parameters": {
    "V_dc": 2.5,
    "C_dc": 1.25,
    "wLf": 0.05,
    "R": 0.001,
    "f_v_dc": 10,
    "f_pll": 10,
    "f_i_dq": 250
  }
}
```

On type 11 the three dc-link numbers are stored and are not used in the dynamics. Use type 10 when the dc link should be in the model, and keep those three numbers.

### Grid-forming inverter

```json
{
  "bus": 2,
  "type": 20,
  "parameters": {
    "wLf": 0.05,
    "Rf": 0.01,
    "wCf": 0.02,
    "wLc": 0.01,
    "Rc": 0.002,
    "Xov": 0,
    "Dw": 0.05,
    "fdroop": 5,
    "fvdq": 300,
    "fidq": 600,
    "Sbase": 314.159265359
  }
}
```

`Sbase` here is `2*pi*50`, matching a `base_frequency_Hz` of 50, because type 20 uses `Sbase` as the frequency reference. Omit `Sbase` only when you intend the default of 1.

### Full machine

A type 35 with data for the machine and the AVR, leaving PSS and governor at the defaults:

```json
{
  "bus": 2,
  "type": 35,
  "parameters": {
    "X": 0.035,
    "R": 0,
    "Xd": 0.295,
    "Xd1": 0.0697,
    "Xd2": 0.05,
    "Td1": 6.56,
    "Td2": 0.05,
    "Xq": 0.282,
    "Xq1": 0.0933333,
    "Xq2": 0.05,
    "Tq1": 1.5,
    "Tq2": 0.035,
    "H": 30.2,
    "D": 0,
    "TR": 0.01,
    "KA": 1,
    "TA": 0.02,
    "VRmax": 10,
    "VRmin": -10,
    "KE": 1,
    "TE": 0.785,
    "E1": 3.9267,
    "SE1": 0.07,
    "E2": 5.2356,
    "SE2": 0.91,
    "KF": 0.03,
    "TF": 1,
    "KP": 200,
    "KI": 50,
    "KD": 50,
    "TD": 0.01
  }
}
```

### DC buck

Both buses have `"ac_or_dc": 2`. Bus 1 is `"type": 1` and type `1090`. Bus 2 is `"type": 3` with the buck power in `PGi_pu`, and:

```json
{ "bus": 2, "type": 1010 }
```

Set `"power_flow_algorithm": 1`. The program forces Gauss-Seidel anyway.

### Interlink

From `Hybrid_test_v1.json`. Bus 2 is AC, bus 3 is DC. The pair is written DC-first; the reader swaps it.

```json
{ "bus": 1, "type": 0 }
```

```json
{ "bus": [3, 2], "type": 2001 }
```

```json
{ "bus": 4, "type": 1010 }
```

Bus 1 is the AC slack, bus 3 is the DC slack. No line connects bus 2 to bus 3.

## Errors you will see

| Message | Cause |
| --- | --- |
| `missing a required top-level field (basic, advance, buses, lines, apparatuses)` | One of those five keys is absent. |
| `Reference to non-existent field` | A bus, branch, `basic`, or `advance` object is missing a required name. |
| `lines.form must be "ieee" or "toolbox"` | `form` is anything else. |
| `The total area number is different from the maximum area index.` | Area numbers skip a value, or do not start at 1. |
| `In an area, the area type has to be the same for all buses.` | One area mixes `ac_or_dc` 1 and 2. |
| `The system has no slack bus in area` | That area has no `type` 1. |
| `The first bus in each area has to be the slack bus.` | The lowest bus number in the area is not the slack. |
| `The system has more than one slack bus in area` | Two buses in the area have `type` 1. |
| `Bus N is defined multiple times.` | Two objects with the same `bus` number. |
| `is a dc bus, whose type can not be 2` or `The bus type in dc network can not be 2!` | `type` 2 on a DC bus, or `type` 2 anywhere in a file that has a DC area. |
| `For each bus, one and only one apparatus has to be connected.` | Two apparatus rows cover the same bus. An interlink counts for both of its buses. |
| `apparatus type, bus … type …` | The type code is outside every family. |
| `Error: apparatus type` | The family is known and the subtype is not assigned (21–27, 29, 36, 37, 43–49). |
| `Invalid ApparatusType.` | Subtype rejected by the class (2–9, 12–16, 1012–1019, 2002–2009). |
| `Apparatus data overflow.` or `parameter overflow` | More than 50 names in one `parameters` object. |
| `Passive load at bus … PLi can not be less than 0.` | `PLi_pu` is negative. Put generation in `PGi_pu`. |
| `Branch … is open circuit` | Toolbox branch with infinite R or X and zero shunt. |
| `Branch … is short circuit` | R and X both 0, or infinite B or G. |
| `Negative line paramters` | A line R, X, B, or G is negative. The spelling is the one in the message. |
| `Turns ratio can not be less than or equal to 0.` | `turns_ratio` ≤ 0. |
| `is a hybrid branch` | A line joins an AC bus to a DC bus. Use an interlink apparatus. |
| `is a self branch. Its R and X should be inf.` | IEEE self-branch with finite R or X. |
| `whose resistance can NOT be zero` | DC branch with `R_pu` 0 and infinite `G_pu`. |
| `Wrong setting for power flow algorithm.` | `power_flow_algorithm` is not 1 or 2. |
| `The PowerFlow does not converge` | Gauss-Seidel hit its iteration limit. Check the slack, the bases, and the pu powers. |
| `System is improper, which has more zeros than poles.` | The network-plus-apparatus model has a direct feedthrough that the realization cannot clear. A floating bus or a zero series impedance is a typical cause. |
| `Because the system has dc area(s), the Gauss-Seidel power flow method is always used.` | Warning. Algorithm 2 was requested and a DC bus is present. |
| `The modal (participation) analysis is disabled or the power system has a dc area.` | Warning. `modal_analysis` is 0, or a DC bus blocked it. |

A pole study that finishes prints `Stable!` or `Warning: Unstable!`, then `End: run successfully.` Poles are written to `input_results.json` next to the netlist. A real part above `1e-8` Hz is reported as unstable. Both parts of `pole_sys` are in Hz.
