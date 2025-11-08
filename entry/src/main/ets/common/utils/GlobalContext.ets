/**
 * 全局上下文工具类
 * 用于在应用中传递全局数据
 */
export class GlobalContext {
  private constructor() {}

  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();

  /**
   * 获取GlobalContext实例
   */
  public static getContext(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  /**
   * 获取对象
   */
  public getObject(value: string): Object | undefined {
    return this._objects.get(value);
  }

  /**
   * 设置对象
   */
  public setObject(key: string, objectClass: Object): void {
    this._objects.set(key, objectClass);
  }
}
