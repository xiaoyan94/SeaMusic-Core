import { common } from "@kit.AbilityKit";

export class ContextHelper {
  private static _context: common.UIAbilityContext | undefined;

  public static init(context: common.UIAbilityContext) {
    ContextHelper._context = context;
  }

  public static getContext(): common.UIAbilityContext | undefined {
    return ContextHelper._context;
  }
}