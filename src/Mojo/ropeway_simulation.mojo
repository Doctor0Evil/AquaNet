struct RopewayConfig:
var span_m: Float64
var avg_load_kg: Float64
var trip_time_s: Float64
var elevation_diff_m: Float64
var cable_efficiency: Float64
var motor_efficiency: Float64
var flywheel_roundtrip_eff: Float64
var renewable_fraction: Float64
fn init(inout self, span_m: Float64, avg_load_kg: Float64, trip_time_s: Float64, elevation_diff_m: Float64, cable_efficiency: Float64, motor_efficiency: Float64, flywheel_roundtrip_eff: Float64, renewable_fraction: Float64):
self.span_m = span_m
self.avg_load_kg = avg_load_kg
self.trip_time_s = trip_time_s
self.elevation_diff_m = elevation_diff_m
self.cable_efficiency = cable_efficiency
self.motor_efficiency = motor_efficiency
self.flywheel_roundtrip_eff = flywheel_roundtrip_eff
self.renewable_fraction = renewable_fraction
struct RopewayResult:
var mech_energy_j: Float64
var elec_energy_j: Float64
var elec_energy_kwh: Float64
var ton_km: Float64
var kwh_per_ton_km: Float64
var co2_diesel_kg: Float64
var co2_elec_kg: Float64
var co2_avoided_kg: Float64
var eco_score_0_10: Float64
alias G = 9.80665
fn simulate_trip(cfg: RopewayConfig) -> RopewayResult:
var r = RopewayResult(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
var mass_ton = cfg.avg_load_kg / 1000.0
var distance_km = cfg.span_m / 1000.0
r.ton_km = mass_ton * distance_km
var v_avg = cfg.span_m / cfg.trip_time_s
var drag_coeff = 0.8
var area_m2 = 3.0
var rho_air = 1.225
var f_drag = 0.5 * rho_air * drag_coeff * area_m2 * v_avg * v_avg
var e_drag = f_drag * cfg.span_m
var e_lift = cfg.avg_load_kg * G * cfg.elevation_diff_m
if cfg.elevation_diff_m < 0.0:
e_lift = 0.0
r.mech_energy_j = (e_drag + e_lift) / cfg.cable_efficiency
var eff_chain = cfg.motor_efficiency * cfg.flywheel_roundtrip_eff
r.elec_energy_j = r.mech_energy_j / eff_chain
r.elec_energy_kwh = r.elec_energy_j / 3.6e6
if r.ton_km > 0.0:
r.kwh_per_ton_km = r.elec_energy_kwh / r.ton_km
var diesel_kwh_per_ton_km = 0.6
var co2_diesel_kg_per_kwh = 0.27
r.co2_diesel_kg = diesel_kwh_per_ton_km * r.ton_km * co2_diesel_kg_per_kwh
var grid_co2_kg_per_kwh = 0.15
var renewable_co2_kg_per_kwh = 0.02
var eff_co2_kwh = cfg.renewable_fraction * renewable_co2_kg_per_kwh + (1.0 - cfg.renewable_fraction) * grid_co2_kg_per_kwh
r.co2_elec_kg = r.elec_energy_kwh * eff_co2_kwh
r.co2_avoided_kg = r.co2_diesel_kg - r.co2_elec_kg
var perf = max(0.0, 1.0 - r.kwh_per_ton_km / 1.0)
var avoid_norm = min(1.0, max(0.0, r.co2_avoided_kg / 10.0))
r.eco_score_0_10 = 10.0 * 0.6 * perf + 10.0 * 0.4 * avoid_norm
return r
fn main():
var cfg = RopewayConfig(1200.0, 40000.0, 600.0, 2.0, 0.95, 0.93, 0.9, 0.85)
var res = simulate_trip(cfg)
print("Eco score: ", res.eco_score_0_10, " / 10")
