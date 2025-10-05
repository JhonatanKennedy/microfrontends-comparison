import { createBrowserRouter } from "react-router";

export const router = createBrowserRouter([
  {
    path: "/",
    lazy: async () => {
      const Home = await import("homeApp/Home");
      return { Component: Home.default };
    },
  },
  {
    path: "/checkout",
    lazy: async () => {
      const Checkout = await import("checkoutApp/Checkout");
      return { Component: Checkout.default };
    },
  },
]);
