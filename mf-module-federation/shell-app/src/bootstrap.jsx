import React, { Suspense, lazy } from 'react';
import { createRoot } from 'react-dom/client';

const Home = lazy(() => import('HomeApp/Home'));

function App() {
  return (
    <div>
      <h1>E-Commerce Shell</h1>
      <nav>
        <a href="#products">Products</a>
        <a href="#cart">Cart</a>
      </nav>
      <Suspense fallback={<div>Loading...</div>}>
        <section>
          <h2>Product List</h2>
          <Home />
        </section>
        {/* <section>
          <h2>Shopping Cart</h2>
          <Cart />
        </section> */}
      </Suspense>
    </div>
  );
}
const root = createRoot(document.getElementById('root'));
root.render(<App />);