import { create } from "zustand";

type TOrder = {
  name: string;
  value: number;
  description: string;
  photoURL: string;
  quantity: number;
};

type Store = {
  order: TOrder[];
  addOrder: (product: Omit<TOrder, "quantity">) => void;
  removeOrder: (productName: string) => void;
  deleteOrder: (productName: string) => void;
};

export const useStore = create<Store>()((set) => ({
  order: [],
  addOrder: (product) =>
    set((state) => {
      const existing = state.order.find((p) => p.name === product.name);

      if (existing) {
        return {
          order: state.order.map((p) =>
            p.name === product.name ? { ...p, quantity: p.quantity + 1 } : p
          ),
        };
      }

      return { order: [...state.order, { ...product, quantity: 1 }] };
    }),

  removeOrder: (productName) =>
    set((state) => {
      return {
        order: state.order
          .map((p) =>
            p.name === productName ? { ...p, quantity: p.quantity - 1 } : p
          )
          .filter((p) => p.quantity > 0),
      };
    }),
  deleteOrder: (productName) =>
    set((state) => ({
      order: state.order.filter((p) => p.name !== productName),
    })),
}));
