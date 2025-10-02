import { IconButton, Typography, Box, colors } from "@single-spa/ui-utils";
import { TProduct } from "mf-tgc-types";
import { useState } from "react";

type TProductProps = TProduct & {
  onAddProduct: (value: TProduct) => void;
  onRemoveProduct: (value: TProduct) => void;
};

export function Product({
  photoURL,
  name,
  description,
  value,
  onAddProduct,
  onRemoveProduct,
}: TProductProps) {
  const [quantity, setQuantity] = useState(0);

  const formattedValue = new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(value);

  function handleAddQuantity() {
    setQuantity((prev) => prev + 1);
    onAddProduct({ photoURL, name, description, value });
  }

  function handleSubtractQuantity() {
    setQuantity((prev) => prev - 1);
    onRemoveProduct({ photoURL, name, description, value });
  }

  return (
    <Box direction="column" align="center">
      <img
        src={require(`../../../public/assets/${photoURL}`)}
        width="100%"
        height="100px"
        style={{ objectFit: "cover" }}
      />

      <Typography variant="body">{name}</Typography>

      <Typography
        variant="caption"
        style={{
          display: "-webkit-box",
          height: "45px",
          overflow: "hidden",
          textOverflow: "ellipsis",
          WebkitBoxOrient: "vertical",
          WebkitLineClamp: 3,
        }}
      >
        {description}
      </Typography>

      <Typography variant="body">{formattedValue}</Typography>

      <Box align="center">
        <IconButton
          icon="minus"
          variant="outlined"
          style={{
            color: colors.textSecondary,
            borderColor: colors.textSecondary,
          }}
          onClick={handleSubtractQuantity}
          hide={quantity === 0}
        />

        <Typography color="secondary" style={{ fontWeight: 600 }}>
          {quantity > 0 ? quantity : null}
        </Typography>

        <IconButton
          icon="plus"
          variant="outlined"
          style={{
            color: colors.textSecondary,
            borderColor: colors.textSecondary,
          }}
          onClick={handleAddQuantity}
        />
      </Box>
    </Box>
  );
}
