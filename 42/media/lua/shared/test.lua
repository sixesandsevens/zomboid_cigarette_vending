CigaretteVending = CigaretteVending or {}

function CigaretteVending.inspectSprite(spriteName)
    spriteName = spriteName or CigaretteVending.WorldSprite or "cigarette_vending_ashboro_18"

    if not ISMoveableSpriteProps then
        pcall(require, "Moveables/ISMoveableSpriteProps")
    end

    local props = ISMoveableSpriteProps and ISMoveableSpriteProps.new(spriteName) or nil
    if props then
        print(
            "[CigaretteVending] moveable props",
            spriteName,
            "sprite",
            tostring(props.sprite ~= nil),
            "isMoveable",
            tostring(props.isMoveable),
            "name",
            tostring(props.name),
            "groupName",
            tostring(props.groupName)
        )
    else
        print("[CigaretteVending] moveable props unavailable", spriteName)
    end
end

CVInspectSprite = CigaretteVending.inspectSprite
