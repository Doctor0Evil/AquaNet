using System;
namespace AquaNet.Core.Services
{
public sealed class PurificationEfficiencyService
{
public sealed record PurificationParams(double Efficiency, double MarineSafety, double EnergyUseKwhPerM3);
public sealed record EfficiencyResult(double ReducedPollutant, double AdjustedImpact, double KarmaOffsetNk);
public EfficiencyResult Compute(PurificationParams paramsRecord, double initialPollutantLoad)
{
if (paramsRecord.Efficiency < 0 || paramsRecord.Efficiency > 1 ||
paramsRecord.MarineSafety < 0 || paramsRecord.MarineSafety > 1 ||
paramsRecord.EnergyUseKwhPerM3 < 0)
{
throw new ArgumentException("Parameters must be non-negative and within valid ranges.");
}
double reduction = initialPollutantLoad * paramsRecord.Efficiency;
double adjustedImpact = reduction * paramsRecord.MarineSafety - paramsRecord.EnergyUseKwhPerM3 * 0.1;
double karmaOffsetNk = adjustedImpact * 1.5;
return new EfficiencyResult(reduction, adjustedImpact, karmaOffsetNk);
}
}
}
