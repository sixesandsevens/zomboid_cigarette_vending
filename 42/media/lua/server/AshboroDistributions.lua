require "Items/ProceduralDistributions"
require "Items/Distributions"

ProceduralDistributions.list.AshboroCigs = {
    rolls = 4,
    items = {
        "Base.Cigarettes", 20,
        "Base.Cigarettes", 20,
        "Base.Lighter", 6,
        "Base.Matches", 8,
        "Base.Money", 4,
    },
    junk = {
        rolls = 1,
        items = {
            "Base.Cigarettes", 4,
        }
    }
}

SuburbsDistributions = SuburbsDistributions or {}
SuburbsDistributions.all = SuburbsDistributions.all or {}

SuburbsDistributions.all.AshboroCigs = {
    ignoreZombieDensity = true,
    rolls = 4,
    items = {
        "Cigarettes", 20,
        "Cigarettes", 20,
        "Lighter", 6,
        "Matches", 8,
        "Money", 4,
    },
    junk = {
        rolls = 1,
        items = {
            "Cigarettes", 4,
        }
    }
}
