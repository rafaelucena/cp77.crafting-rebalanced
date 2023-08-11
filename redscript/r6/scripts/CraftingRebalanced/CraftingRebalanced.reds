// Version v1.61.2.0
module CraftingRebalanced

// CRAFTING SYSTEM SETTINGS | PARAMETERS
@addMethod(RPGManager)
public static func IsCraftingRebalancedEnabled() -> Bool = true;

// UPGRADING SECTION | UPGRADE SECTION
@addMethod(RPGManager)
public static func GetWeaponUpgradingDivider() -> Float = 1.0;

@addMethod(RPGManager)
public static func GetClothingUpgradingDivider() -> Float = 4.0;

// DISASSEMBLING SECTION | DISASSEMBLE SECTION
@addMethod(RPGManager)
public static func GetWeaponDisassemblingDivider() -> Float = 4.0;

@addMethod(RPGManager)
public static func GetClothingDisassemblingDivider() -> Float = 16.0;

// CRAFTING SECTION | CRAFT SECTION
@addMethod(RPGManager)
public static func GetWeaponCraftingDivider() -> Float = 2.0;

@addMethod(RPGManager)
public static func GetClothingCraftingDivider() -> Float = 8.0;

@addField(CraftingSystem)
public let itemTypeWeaponIconicCraftingDivider: Float = 1.00;

@addField(CraftingSystem)
public let itemTypeClothingIconicCraftingDivider: Float = 4.00;

/*
  DO NOT SET ANY OF THE PARAMETERS ABOVE TO ZERO.
*/

// RPG MANAGER STUFF | HELPERS
@addMethod(RPGManager)
public final static func GetItemLevel(itemData: wref<gameItemData>) -> Float {
  if itemData.HasStatData(gamedataStatType.ItemLevel) {
    return itemData.GetStatValueByType(gamedataStatType.ItemLevel) / 10.00;
  }

  return 0.00;
}

@addMethod(RPGManager)
public final static func GetPlayerLevel(target: ref<GameObject>) -> Float {
  let statSys: ref<StatsSystem> = GameInstance.GetStatsSystem(target.GetGame());
  let player: wref<GameObject> = GameInstance.GetPlayerSystem(target.GetGame()).GetLocalPlayerControlledGameObject();

  return statSys.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Level);
}

// CRAFTING SYSTEM STUFF
// UPGRADING SECTION | UPGRADE SECTION
@wrapMethod(CraftingSystem)
public final const func GetItemFinalUpgradeCost(itemData: wref<gameItemData>) -> array<IngredientData> {
  if !RPGManager.IsCraftingRebalancedEnabled() {
    return wrappedMethod(itemData);
  }

  return this.GetItemFinalUpgradeCostRebalanced(itemData);
}

@addMethod(CraftingSystem)
public final const func GetItemFinalUpgradeCostRebalanced(itemData: wref<gameItemData>) -> array<IngredientData> {
  let i: Int32;
  let ingredients: array<IngredientData>;
  let tempStat: Float;
  let tempQuantity: Float;
  let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGameInstance());
  let itemLevel: Float = RPGManager.GetItemLevel(itemData);
  let itemTypeDivider: Float = 1.00;

  itemLevel += 1.00;
  if RPGManager.IsItemWeapon(itemData.GetID()) {
    itemTypeDivider = RPGManager.GetWeaponUpgradingDivider();
  } else {
    if RPGManager.IsItemClothing(itemData.GetID()) {
      itemTypeDivider = RPGManager.GetClothingUpgradingDivider();
    }
  }

  ingredients = this.GetItemBaseUpgradeCost(itemData.GetItemType(), RPGManager.GetItemQuality(itemData));
  tempStat = statsSystem.GetStatValue(Cast<StatsObjectID>(this.m_playerCraftBook.GetOwner().GetEntityID()), gamedataStatType.UpgradingCostReduction);
  i = 0;
  while i < ArraySize(ingredients) {
    tempQuantity = Cast<Float>(ingredients[i].quantity) * itemLevel;
    ingredients[i].quantity = RoundMath(tempQuantity / itemTypeDivider);
    if (ingredients[i].quantity <= 0) {
      ingredients[i].quantity = 1;
    }

    ingredients[i].baseQuantity = ingredients[i].quantity;

    if tempStat > 0.00 {
      ingredients[i].quantity = Cast<Int32>(Cast<Float>(ingredients[i].quantity) * (1.00 - tempStat));
    };
    i += 1;
  };

  return ingredients;
}

// DISASSEMBLING SECTION | DISASSEMBLE SECTION
@wrapMethod(CraftingSystem)
public final const func GetDisassemblyResultItems(target: wref<GameObject>, itemID: ItemID, amount: Int32, out restoredAttachments: array<ItemAttachments>, opt calledFromUI: Bool) -> array<IngredientData> {
  if !RPGManager.IsCraftingRebalancedEnabled() {
    return wrappedMethod(target, itemID, amount, restoredAttachments, calledFromUI);
  }

  if (RPGManager.IsItemWeapon(itemID) || RPGManager.IsItemClothing(itemID)) {
    return this.GetDisassemblyResultItemsRebalanced(target, itemID, amount, restoredAttachments, calledFromUI);
  }

  return wrappedMethod(target, itemID, amount, restoredAttachments, calledFromUI);
}

@addMethod(CraftingSystem)
public final const func GetDisassemblyResultItemsRebalanced(target: wref<GameObject>, itemID: ItemID, amount: Int32, out restoredAttachments: array<ItemAttachments>, opt calledFromUI: Bool) -> array<IngredientData> {
  let finalResult: array<IngredientData>;
  let i: Int32;
  let ingredients: array<wref<RecipeElement_Record>>;
  let itemData: wref<gameItemData>;
  let itemQual: gamedataQuality;
  let j: Int32;
  let outResult: array<IngredientData>;
  let itemTypeDivider: Float = 1.00;
  let tempQuantity: Float;
  let itemLevel: Float = 1.00;

  itemData = GameInstance.GetTransactionSystem(this.GetGameInstance()).GetItemData(target, itemID);
  itemLevel = RPGManager.GetItemLevel(itemData);
  itemQual = RPGManager.GetItemQuality(itemData);

  if RPGManager.IsItemWeapon(itemID) {
    itemTypeDivider = RPGManager.GetWeaponDisassemblingDivider();
  } else {
    if RPGManager.IsItemClothing(itemID) {
      itemTypeDivider = RPGManager.GetClothingDisassemblingDivider();
    }
  }

  if itemLevel <= 0.00 {
    itemLevel = 1.00;
  };

  i = 0;
  while i < amount {
    ArrayClear(outResult);
    outResult = this.GetItemBaseUpgradeCost(itemData.GetItemType(), itemQual);

    j = 0;
    while j < ArraySize(outResult) {
      tempQuantity = Cast<Float>(outResult[j].quantity) * itemLevel;
      outResult[j].quantity = RoundMath(tempQuantity / itemTypeDivider);
      if (outResult[j].quantity <= 0) {
        outResult[j].quantity = 1;
      }

      j += 1;
    };

    this.ProcessDisassemblingPerks(outResult, itemData, restoredAttachments, calledFromUI);
    this.MergeIngredients(outResult, finalResult);
    i += 1;
  };

  return finalResult;
}

// CRAFTING SECTION | CRAFT SECTION
@wrapMethod(CraftingSystem)
public final const func GetItemCraftingCost(record: wref<Item_Record>, craftingData: array<wref<RecipeElement_Record>>) -> array<IngredientData> {
  if !RPGManager.IsCraftingRebalancedEnabled() {
    return wrappedMethod(record, craftingData);
  }

  if Equals(record.ItemCategory().Name(), n"Weapon") || Equals(record.ItemCategory().Name(), n"Clothing") {
    return this.GetItemCraftingCostRebalanced(record, craftingData);
  };

  return wrappedMethod(record, craftingData);
}

@addMethod(CraftingSystem)
public final const func GetItemCraftingCostRebalanced(record: wref<Item_Record>, craftingData: array<wref<RecipeElement_Record>>) -> array<IngredientData> {
    let ingredient: ItemID;
    let itemData: wref<gameItemData>;
    let baseIngredients: array<IngredientData>;
    let modifiedQuantity: Int32;
    let tempStat: Float;
    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGameInstance());
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.GetGameInstance());
    let i: Int32 = 0;
    let itemLevel: Float = 0.00;
    let playerLevel: Float = RPGManager.GetPlayerLevel(this.m_playerCraftBook.GetOwner());
    let levelDifferential: Float = 1.00;
    let itemTypeDivider: Float = 1.00;
    let isItemIconic: Bool = false;

    i = 0;
    while i < ArraySize(craftingData) {
      ArrayPush(baseIngredients, this.CreateIngredientData(craftingData[i]));

      ingredient = ItemID.CreateQuery(baseIngredients[i].id.GetID());
      if RPGManager.IsItemWeapon(ingredient) || RPGManager.IsItemClothing(ingredient) {
        isItemIconic = true;
        itemData = transactionSystem.GetItemData(this.m_playerCraftBook.GetOwner(), ingredient);
        if IsDefined(itemData) {
          itemLevel = RPGManager.GetItemLevel(itemData);
        };
      };
      i += 1;
    };

    levelDifferential = playerLevel - itemLevel - 1.00;
    if (levelDifferential <= 0.00) {
      levelDifferential = 1.00;
    };

    if Equals(record.ItemCategory().Name(), n"Weapon") {
        itemTypeDivider = RPGManager.GetWeaponCraftingDivider();

        if isItemIconic {
          itemTypeDivider = this.itemTypeWeaponIconicCraftingDivider;
        }
    } else {
      if Equals(record.ItemCategory().Name(), n"Clothing") {
        itemTypeDivider = RPGManager.GetClothingCraftingDivider();

        if isItemIconic {
          itemTypeDivider = this.itemTypeClothingIconicCraftingDivider;
        };
      };
    };

    tempStat = statsSystem.GetStatValue(Cast<StatsObjectID>(this.m_playerCraftBook.GetOwner().GetEntityID()), gamedataStatType.CraftingCostReduction);
    i = 0;
    while i < ArraySize(baseIngredients) {
      ingredient = ItemID.CreateQuery(baseIngredients[i].id.GetID());
      if !RPGManager.IsItemWeapon(ingredient) && !RPGManager.IsItemClothing(ingredient) {
        modifiedQuantity = CeilF((Cast<Float>(baseIngredients[i].quantity) * levelDifferential) / itemTypeDivider);
        if (modifiedQuantity <= 0) {
          modifiedQuantity = 1;
        }

        baseIngredients[i].quantity = modifiedQuantity;
        baseIngredients[i].baseQuantity = modifiedQuantity;

        if tempStat > 0.00 {
          modifiedQuantity = CeilF(Cast<Float>(baseIngredients[i].quantity) * (1.00 - tempStat));
          baseIngredients[i].quantity = modifiedQuantity;
        };
      };

      i += 1;
    };

    return baseIngredients;
}

// Um salve pra galera do grupo de pessoas pobres com computadores ruins :D