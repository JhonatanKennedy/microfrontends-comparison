import { Box, Typography, useStore } from "@single-spa/ui-utils";
import { Header } from "../components/Header";
import { Order } from "../components/Order";
import { OrderResume } from "../components/OrderResume";
import { TOrder } from "mf-tgc-types";

const FIXED_FEE = 16;
const FIXED_DISCOUNT = 2;

export function Checkout() {
  const { order, addOrder, removeOrder, deleteOrder } = useStore();

  function handleAddQuantity(value: TOrder) {
    addOrder(value);
  }

  function handleRemoveQuantity(value: TOrder) {
    removeOrder(value.name);
  }

  function handleDeleteProduct(value: TOrder) {
    deleteOrder(value.name);
  }

  const subTotal = order.reduce(
    (acc, product) => acc + product.value * product.quantity,
    0
  );

  return (
    <Box direction="column" align="center" gap={20}>
      <Header />

      <Box direction="column" style={{ width: "70%", gap: "24px" }}>
        <Typography component="h1" variant="h1">
          Carrinho
        </Typography>

        <Box>
          <Box direction="column" style={{ width: "70%" }}>
            {order.length === 0 ? (
              <Box
                direction="column"
                align="center"
                gap={40}
                style={{
                  width: "100%",
                  padding: "16px",
                  justifyContent: "center",
                  height: "300px",
                }}
              >
                <Typography variant="h1">Nenhum pedido feito</Typography>
              </Box>
            ) : null}

            {order.map((product) => (
              <Order
                key={product.name}
                photoURL={product.photoURL}
                name={product.name}
                description={product.description}
                value={product.value}
                quantity={product.quantity}
                onAddProduct={handleAddQuantity}
                onRemoveProduct={handleRemoveQuantity}
                onEraseProduct={handleDeleteProduct}
              />
            ))}
          </Box>

          <Box style={{ width: "30%" }}>
            <OrderResume
              discount={FIXED_DISCOUNT}
              fee={FIXED_FEE}
              subTotal={subTotal}
            />
          </Box>
        </Box>
      </Box>
    </Box>
  );
}
