require "Items/ProceduralDistributions"
require "Items/Distributions"

local ashboroCigsDistribution = {
    ignoreZombieDensity = true,
    rolls = 4,
    items = {
        "CigarettePack", 20,
        "CigarettePack", 20,
        "Lighter", 6,
        "Matches", 8,
        "Money", 4,
    },
    junk = {
        rolls = 1,
        items = {
            "CigarettePack", 4,
        }
    }
}

ProceduralDistributions.list.AshboroCigs = {
    rolls = 4,
    items = {
        "Base.CigarettePack", 20,
        "Base.CigarettePack", 20,
        "Base.Lighter", 6,
        "Base.Matches", 8,
        "Base.Money", 4,
    },
    junk = {
        rolls = 1,
        items = {
            "Base.CigarettePack", 4,
        }
    }
}

local ashboroDistributionAddon = {
    all = {
        AshboroCigs = ashboroCigsDistribution,
    }
}

table.insert(Distributions, ashboroDistributionAddon)

local function addOne(container, fullType)
    if container and fullType then
        container:AddItem(fullType)
    end
end

local function fillAshboroCigsFallback(roomName, containerType, container)
    if containerType ~= "AshboroCigs" or not container then
        return
    end

    if container:getItems() and container:getItems():size() > 0 then
        return
    end

    local cigaretteCount = 1 + ZombRand(4)
    for _ = 1, cigaretteCount do
        addOne(container, "Base.CigarettePack")
    end

    if ZombRand(100) < 35 then
        addOne(container, "Base.Lighter")
    end

    if ZombRand(100) < 45 then
        addOne(container, "Base.Matches")
    end

    if ZombRand(100) < 20 then
        addOne(container, "Base.Money")
    end
end

Events.OnFillContainer.Add(fillAshboroCigsFallback)
