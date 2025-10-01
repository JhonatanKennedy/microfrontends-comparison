import { TOrder } from "../business/order";
import { TProduct } from "../business/product";

export type TOrderStore = {
  order: TOrder[];
  addOrder: (product: TProduct) => void;
  removeOrder: (productName: string) => void;
  deleteOrder: (productName: string) => void;
};
