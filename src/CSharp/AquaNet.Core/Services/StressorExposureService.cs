using System;
namespace AquaNet.Core.Services
{
public sealed class StressorExposureService
{
public sealed record StressorParams(double Limit, double Efficiency, double Safety);
public sealed record ExposureResult(double ReducedExposure, double AdjustedImpact, double KarmaOffsetNk);
public ExposureResult Compute(StressorParams paramsRecord, double initialExposureLevel)
{
if (paramsRecord.Efficiency < 0 || paramsRecord.Efficiency > 1 ||
paramsRecord.Safety < 0 || paramsRecord.Safety > 1 ||
paramsRecord.Limit < 0)
{
throw new ArgumentException("Parameters must be non-negative and within valid ranges.");
}
double reduction = initialExposureLevel * paramsRecord.Efficiency;
double adjustedImpact = reduction * paramsRecord.Safety - paramsRecord.Limit * 0.05;
double karmaOffsetNk = adjustedImpact * 1.2;
return new ExposureResult(reduction, adjustedImpact, karmaOffsetNk);
}
}
}
