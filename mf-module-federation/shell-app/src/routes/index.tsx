import { ComponentType, lazy, Suspense } from "react";
import {
  createBrowserRouter,
  NavigateFunction,
  Outlet,
  useNavigate,
} from "react-router";

const Home = lazy(() => import("homeApp/Home"));
const Checkout = lazy(() => import("checkoutApp/Checkout"));

// function Root() {
//   const navigate = useNavigate();

//   return (
//     <div>
//       <button onClick={() => navigate("checkout")}>teste</button>
//       <Outlet />
//     </div>
//   );
// }

// export const router = createBrowserRouter([
//   {
//     path: "/",
//     Component: Root,

//     children: [
//       {
//         index: true,
//         element: (
//           <Suspense fallback={<div>Loading...</div>}>
//             <Home />
//           </Suspense>
//         ),
//       },
//       {
//         path: "checkout",
//         element: (
//           <Suspense fallback={<div>Loading...</div>}>
//             <Checkout />
//           </Suspense>
//         ),
//       },
//     ],
//   },
// ]);

export const router = createBrowserRouter([
  {
    path: "/",
    element: (
      <Suspense fallback={<div>Loading...</div>}>
        <Home />
      </Suspense>
    ),
  },
  {
    path: "/checkout",
    element: (
      <Suspense fallback={<div>Loading...</div>}>
        <Checkout />
      </Suspense>
    ),
  },
]);
