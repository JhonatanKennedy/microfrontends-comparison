import React, { Suspense, lazy } from "react";
import { createRoot } from "react-dom/client";

const Home = lazy(() => import("HomeApp/Home"));

function App() {
  return (
    <div>
      <h1>E-Commerce Shell asasssa</h1>
      <nav>
        <a href="#products">Products</a>
        <a href="#cart">Cart</a>
      </nav>
      <Suspense fallback={<div>Loading...</div>}>
        <section>
          <h2>Product List</h2>
          <Home />
        </section>
      </Suspense>
    </div>
  );
}

const container = document.getElementById("root");

if (container) {
  const root = createRoot(container);
  root.render(<App />);
} else {
  console.error("Elemento com ID 'root' não encontrado no DOM.");
}
