import { useEffect, useState } from "react";
import { Container } from "../components/Container";
import { Product } from "../components/Product";
import { Typography, Box } from "@single-spa/ui-utils";
import data from "../../../../data.json";
import { Header } from "../components/Header";

type TProduct = {
  name: string;
  value: number;
  description: string;
  photoURL: string;
};

type ResponseApi = {
  products: TProduct[];
};

type TOrder = TProduct & {
  quantity: number;
};

export function Home() {
  const [products, setProducts] = useState<TProduct[]>([]);
  const [order, setOrder] = useState<TOrder[]>([]);
  const [search, setSearch] = useState("");

  function handleAddProduct(value: TProduct) {
    const product = order.find((product) => product.name === value.name);

    if (product) {
      const newOrder = order.map((product) =>
        product.name === value.name
          ? { ...value, quantity: product.quantity + 1 }
          : product
      );
      setOrder(newOrder);
      return;
    }

    setOrder((prev) => [...prev, { ...value, quantity: 1 }]);
  }

  function handleRemoveProduct(value: TProduct) {
    const product = order.find((product) => product.name === value.name);

    if (product) {
      const newOrder = order.map((product) => {
        if (product.name === value.name) {
          const shouldDeleteProduct = product.quantity - 1 === 0;

          if (shouldDeleteProduct) {
            return;
          }

          return { ...value, quantity: product.quantity - 1 };
        }
        return product;
      });

      setOrder(newOrder.filter((item) => item));
    }
  }

  async function fetchDefaultData() {
    const response: ResponseApi = await new Promise((resolve) => {
      setTimeout(() => {
        resolve(data as unknown as ResponseApi);
      }, 2000);
    });

    setProducts(response.products);
  }

  useEffect(() => {
    void fetchDefaultData();
  }, []);

  const filteredProducts = products.filter((product) =>
    product.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <Box direction="column" align="center">
      <Header onChangeName={setSearch} />
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
            />
          ))}
        </Container>
      </Box>
    </Box>
  );
}
