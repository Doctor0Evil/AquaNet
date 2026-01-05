using System;
using System.Collections.Generic;

namespace AquaNet.Core.Services
{
    public sealed class KarmaScoringService
    {
        public sealed record RegulatoryProfile(
            double LimitPFBSngL,
            double LimitEColiMpnPer100mL,
            double LimitNitrateMgLAsN,
            double LimitPhosphateMgLAsP,
            double LimitTssMgL,
            double BenchmarkSalinityPpt,
            double BenchmarkDoMgL
        );

        public sealed record SampleMetrics(
            double PFBSngL,
            double EColiMpnPer100mL,
            double NitrateMgLAsN,
            double PhosphateMgLAsP,
            double TssMgL,
            double SalinityPpt,
            double DoMgL,
            double MicroplasticsItemsPerM3,
            double LocalEcoSensitivity0To1,
            double RecyclingMassKg,
            double WasteDivertedKg,
            double EnergySavedKWh,
            double CarbonAvoidedKgCo2e
        );

        public sealed record KarmaResult(
            double EcoImpactScore0To100,
            double AquaKarmaOffsetNk,
            IReadOnlyDictionary<string, double> Drivers
        );

        public KarmaResult Score(
            SampleMetrics sample,
            RegulatoryProfile profile
        )
        {
            if (profile.LimitPFBSngL <= 0 ||
                profile.LimitEColiMpnPer100mL <= 0 ||
                profile.LimitNitrateMgLAsN <= 0 ||
                profile.LimitPhosphateMgLAsP <= 0 ||
                profile.LimitTssMgL <= 0 ||
                profile.BenchmarkDoMgL <= 0)
            {
                throw new ArgumentException("Regulatory limits and DO benchmark must be positive.");
            }

            double exceedPFBS = Math.Max(0.0, sample.PFBSngL / profile.LimitPFBSngL - 1.0);
            double exceedEColi = Math.Max(0.0, sample.EColiMpnPer100mL / profile.LimitEColiMpnPer100mL - 1.0);
            double exceedNitrate = Math.Max(0.0, sample.NitrateMgLAsN / profile.LimitNitrateMgLAsN - 1.0);
            double exceedPhosphate = Math.Max(0.0, sample.PhosphateMgLAsP / profile.LimitPhosphateMgLAsP - 1.0);
            double exceedTss = Math.Max(0.0, sample.TssMgL / profile.LimitTssMgL - 1.0);
            double exceedSalinity = Math.Max(0.0, sample.SalinityPpt / profile.BenchmarkSalinityPpt - 1.0);
            double exceedDo = Math.Max(0.0, (profile.BenchmarkDoMgL - sample.DoMgL) / profile.BenchmarkDoMgL);

            double exceedMicroplastics = Math.Max(0.0, sample.MicroplasticsItemsPerM3 / 1000.0);

            double wToxic = 0.35;
            double wPathogen = 0.25;
            double wNutrient = 0.20;
            double wSediment = 0.10;
            double wSalinity = 0.05;
            double wMicroplastics = 0.05;

            double toxicScore = exceedPFBS;
            double pathogenScore = exceedEColi;
            double nutrientScore = 0.5 * exceedNitrate + 0.5 * exceedPhosphate;
            double sedimentScore = exceedTss;
            double salinityScore = 0.5 * exceedSalinity + 0.5 * exceedDo;
            double microplasticsScore = exceedMicroplastics;

            double combinedRisk =
                wToxic * toxicScore +
                wPathogen * pathogenScore +
                wNutrient * nutrientScore +
                wSediment * sedimentScore +
                wSalinity * salinityScore +
                wMicroplastics * microplasticsScore;

            double ecoSensitivity = Math.Clamp(sample.LocalEcoSensitivity0To1, 0.0, 1.0);
            double effectiveRisk = combinedRisk * (1.0 + 0.5 * ecoSensitivity);

            double riskScore0To100 = 100.0 * (1.0 - 1.0 / (1.0 + effectiveRisk));
            double ecoImpactScore0To100 = Math.Clamp(100.0 - riskScore0To100, 0.0, 100.0);

            double massFactor = sample.RecyclingMassKg + 0.5 * sample.WasteDivertedKg;
            double energyFactor = 0.1 * sample.EnergySavedKWh;
            double carbonFactor = 0.05 * sample.CarbonAvoidedKgCo2e;

            double positiveOffset = massFactor + energyFactor + carbonFactor;
            double normalizedPositive = Math.Log10(1.0 + positiveOffset);

            double aquaKarmaOffsetNk = ecoImpactScore0To100 * (1.0 + normalizedPositive);

            var drivers = new Dictionary<string, double>
            {
                ["exceed_PFBS"] = exceedPFBS,
                ["exceed_EColi"] = exceedEColi,
                ["exceed_Nitrate"] = exceedNitrate,
                ["exceed_Phosphate"] = exceedPhosphate,
                ["exceed_TSS"] = exceedTss,
                ["exceed_Salinity_DO"] = salinityScore,
                ["exceed_Microplastics"] = exceedMicroplastics,
                ["combined_Risk"] = combinedRisk,
                ["effective_Risk"] = effectiveRisk,
                ["EcoImpact_Score"] = ecoImpactScore0To100,
                ["Positive_Offset"] = positiveOffset,
                ["AquaKarma_Offset_nk"] = aquaKarmaOffsetNk
            };

            return new KarmaResult(ecoImpactScore0To100, aquaKarmaOffsetNk, drivers);
        }
    }
}
