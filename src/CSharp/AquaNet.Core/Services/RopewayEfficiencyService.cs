using System;
namespace AquaNet.Core.Services
{
public sealed class RopewayEfficiencyService
{
public sealed record RopewayConfig(double SpanM, double AvgLoadKg, double TripTimeS, double ElevationDiffM, double CableEfficiency, double MotorEfficiency, double FlywheelRoundtripEff, double RenewableFraction);
public sealed record RopewayResult(double MechEnergyJ, double ElecEnergyJ, double ElecEnergyKwh, double TonKm, double KwhPerTonKm, double Co2DieselKg, double Co2ElecKg, double Co2AvoidedKg, double EcoScore0To10);
private const double G = 9.80665;
public RopewayResult SimulateTrip(RopewayConfig cfg)
{
if (cfg.SpanM <= 0 || cfg.AvgLoadKg <= 0 || cfg.TripTimeS <= 0 || cfg.CableEfficiency <= 0 || cfg.CableEfficiency > 1 ||
cfg.MotorEfficiency <= 0 || cfg.MotorEfficiency > 1 || cfg.FlywheelRoundtripEff <= 0 || cfg.FlywheelRoundtripEff > 1 ||
cfg.RenewableFraction < 0 || cfg.RenewableFraction > 1)
{
throw new ArgumentException("Parameters must be positive and within valid ranges.");
}
double massTon = cfg.AvgLoadKg / 1000.0;
double distanceKm = cfg.SpanM / 1000.0;
double tonKm = massTon * distanceKm;
double vAvg = cfg.SpanM / cfg.TripTimeS;
double dragCoeff = 0.8;
double areaM2 = 3.0;
double rhoAir = 1.225;
double fDrag = 0.5 * rhoAir * dragCoeff * areaM2 * vAvg * vAvg;
double eDrag = fDrag * cfg.SpanM;
double eLift = cfg.AvgLoadKg * G * cfg.ElevationDiffM;
if (cfg.ElevationDiffM < 0.0)
{
eLift = 0.0;
}
double mechEnergyJ = (eDrag + eLift) / cfg.CableEfficiency;
double effChain = cfg.MotorEfficiency * cfg.FlywheelRoundtripEff;
double elecEnergyJ = mechEnergyJ / effChain;
double elecEnergyKwh = elecEnergyJ / 3.6e6;
double kwhPerTonKm = (tonKm > 0.0) ? elecEnergyKwh / tonKm : 0.0;
double dieselKwhPerTonKm = 0.6;
double co2DieselKgPerKwh = 0.27;
double co2DieselKg = dieselKwhPerTonKm * tonKm * co2DieselKgPerKwh;
double gridCo2KgPerKwh = 0.15;
double renewableCo2KgPerKwh = 0.02;
double effCo2Kwh = cfg.RenewableFraction * renewableCo2KgPerKwh + (1.0 - cfg.RenewableFraction) * gridCo2KgPerKwh;
double co2ElecKg = elecEnergyKwh * effCo2Kwh;
double co2AvoidedKg = co2DieselKg - co2ElecKg;
double perf = Math.Max(0.0, 1.0 - kwhPerTonKm / 1.0);
double avoidNorm = Math.Min(1.0, Math.Max(0.0, co2AvoidedKg / 10.0));
double ecoScore0To10 = 10.0 * 0.6 * perf + 10.0 * 0.4 * avoidNorm;
return new RopewayResult(mechEnergyJ, elecEnergyJ, elecEnergyKwh, tonKm, kwhPerTonKm, co2DieselKg, co2ElecKg, co2AvoidedKg, ecoScore0To10);
}
}
}
