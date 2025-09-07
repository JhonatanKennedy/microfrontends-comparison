import React, { useState, useEffect } from 'react';
import axios from 'axios';

function Home() {
  const [products, setProducts] = useState([]);

  useEffect(() => {
    axios.get('https://api.example.com/products')
      .then(res => setProducts(res.data))
      .catch(err => console.error('Failed to fetch products:', err));
  }, []);

  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '20px' }}>
      teste do mf
      {products.map(product => (
        <div key={product.id} style={{ width: '200px', border: '1px solid #ccc', padding: '10px' }}>
          <img src={product.image} alt={product.name} style={{ width: '100%' }} />
          <h3>{product.name}</h3>
          <p>${product.price}</p>
          <button onClick={() => alert('Add to cart clicked!')}>Add to Cart</button>
        </div>
      ))}
    </div>
  );
}

export default Home;