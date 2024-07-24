
export class CommonUtil {
  /**
   * Split array
   *
   * @param colls collections
   * @param size  The size of result array
   * @return List
   */
  split<T>(colls: Array<T>, size: number): Array<Array<T>> {
    if (colls.length === 0) {
      return [];
    }
    if (size <= 0) {
      throw new Error('The size must > 0');
    }

    let rets: Array<Array<T>> = [];
    let items: Array<T> = [];

    for (let coll of colls) {
      items.push(coll);
      if (size == items.length) {
        rets.push(items);
        items = [];
      }
    }
    if (0 != items.length) {
      rets.push(items);
    }
    return rets;
  }
}

let commonUtil = new CommonUtil()

export default commonUtil as CommonUtil