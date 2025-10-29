import data from "../data/index.json";
import { useEffect, useState } from "react";
import { Container } from "../components/Container";
import { Product } from "../components/Product";
import { Typography, Box, useStore } from "uiUtils";
import { Header } from "../components/Header";
import { TProduct } from "mf-tgc-types";
import "../global.css";

type ResponseApi = {
  products: TProduct[];
};

export function Home() {
  const [products, setProducts] = useState<TProduct[]>([]);
  const [search, setSearch] = useState("");
  const { order, addOrder, removeOrder } = useStore();

  function handleAddProduct(value: TProduct) {
    addOrder(value);
  }

  function handleRemoveProduct(value: TProduct) {
    removeOrder(value.name);
  }

  async function fetchDefaultData() {
    const response = await fetch("http://localhost:3000/products");
    const productArray: TProduct[] = await response.json();

    setProducts(productArray);
  }

  useEffect(() => {
    void fetchDefaultData();
  }, []);

  const filteredProducts = products.filter((product) =>
    product.name.toLowerCase().includes(search.toLowerCase())
  );

  function hasOrderQuantity(product: TProduct) {
    const prod = order.find((o) => o.name === product.name);
    if (prod) {
      return prod.quantity;
    }
    return 0;
  }

  const countOrder = order.reduce((acc, product) => acc + product.quantity, 0);

  return (
    <Box direction="column" align="center">
      <Header onChangeName={setSearch} countCar={countOrder} />
      <Box direction="column" style={{ width: "70%" }}>
        <Typography component="h1" variant="h1">
          Pratos
        </Typography>
        <Container>
          {filteredProducts.map((product) => (
            <Product
              key={product.name}
              name={product.name}
              description={product.description}
              value={product.value}
              photoURL={product.photoURL}
              onAddProduct={handleAddProduct}
              onRemoveProduct={handleRemoveProduct}
              quantity={hasOrderQuantity(product)}
            />
          ))}
        </Container>
      </Box>
    </Box>
  );
}
