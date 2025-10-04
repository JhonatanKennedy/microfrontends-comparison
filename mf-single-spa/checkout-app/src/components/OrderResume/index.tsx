import {
  Box,
  Typography,
  Button,
  formatCurrency,
  convertToPercentage,
} from "@single-spa/ui-utils";

type OrderResumeProps = {
  subTotal: number;
  fee: number;
  discount: number;
};

export function OrderResume({ subTotal, fee, discount }: OrderResumeProps) {
  const formattedSubTotal = formatCurrency(subTotal);
  const formattedFee = convertToPercentage(fee);
  const formattedDiscount = formatCurrency(discount);

  const totalValue = subTotal + subTotal * (fee / 100) - discount;
  const formattedTotalValue = formatCurrency(totalValue);

  function handleClickBuy() {
    alert("Compra feita!!");
  }

  if (subTotal === 0) {
    return (
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
    );
  }

  return (
    <Box
      direction="column"
      align="center"
      gap={40}
      style={{ width: "100%", padding: "16px" }}
    >
      <Typography variant="h1">Resumo</Typography>

      <Box direction="column" style={{ width: "100%" }}>
        <Box justify="space-between" align="center" style={{ width: "100%" }}>
          <Typography variant="h2">Subtotal</Typography>
          <Typography variant="h2">{formattedSubTotal}</Typography>
        </Box>

        <Box justify="space-between" align="center" style={{ width: "100%" }}>
          <Typography variant="h2">Taxas</Typography>
          <Typography variant="h2">{formattedFee}</Typography>
        </Box>

        <Box justify="space-between" align="center" style={{ width: "100%" }}>
          <Typography variant="h2">Desconto</Typography>
          <Typography variant="h2">{formattedDiscount}</Typography>
        </Box>
      </Box>

      <Box direction="column" gap={32} style={{ width: "100%" }}>
        <Box justify="space-between" align="center" style={{ width: "100%" }}>
          <Typography variant="h2">Total</Typography>
          <Typography variant="h2">{formattedTotalValue}</Typography>
        </Box>

        <Button onClick={handleClickBuy} aria-label="button-checkout">
          Comprar
        </Button>
      </Box>
    </Box>
  );
}
