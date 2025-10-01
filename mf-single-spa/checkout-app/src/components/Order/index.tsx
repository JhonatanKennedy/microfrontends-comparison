import {
  Box,
  Typography,
  IconButton,
  colors,
  formatCurrency,
} from "@single-spa/ui-utils";
import { useState } from "react";

type TOrder = {
  name: string;
  value: number;
  description: string;
  photoURL: string;
  quantity: number;
};

type TOrderProps = TOrder & {
  onAddProduct: (value: TOrder) => void;
  onRemoveProduct: (value: TOrder) => void;
  onEraseProduct: (value: TOrder) => void;
};

export function Order({
  photoURL,
  name,
  description,
  value,
  quantity: qty,
  onAddProduct,
  onRemoveProduct,
  onEraseProduct,
}: TOrderProps) {
  const [quantity, setQuantity] = useState(qty);
  const formattedValue = formatCurrency(value);

  function handleAddQuantity() {
    setQuantity((prev) => prev + 1);

    onAddProduct({ photoURL, name, description, value, quantity });
  }

  function handleSubtractQuantity() {
    setQuantity((prev) => {
      if (prev - 1 < 0) return prev;

      return prev - 1;
    });

    onRemoveProduct({
      photoURL,
      name,
      description,
      value,
      quantity,
    });
  }

  function handleDeleteProduct() {
    onEraseProduct({ photoURL, name, description, value, quantity });
  }

  return (
    <Box style={{ width: "100%" }}>
      <Box style={{ width: "20%" }}>
        <img
          src={require(`../../../public/assets/${photoURL}`)}
          width="100%"
          height="100px"
          style={{ objectFit: "cover" }}
        />
      </Box>

      <Box direction="column" style={{ width: "70%" }}>
        <Typography style={{ fontWeight: 600, fontSize: "16px" }}>
          {name}
        </Typography>
        <Typography variant="caption">{description}</Typography>

        <Box justify="space-between">
          <Box
            style={{
              border: "1px solid",
              borderRadius: "14px",
              borderColor: colors.textSecondary,
              height: "15px",
              borderCollapse: "collapse",
            }}
          >
            <IconButton
              icon="minus"
              variant="outlined"
              size={10}
              style={{
                color: colors.textSecondary,
                borderColor: colors.textSecondary,
                width: "15px",
                height: "15px",
                marginLeft: "-1px",
              }}
              onClick={handleSubtractQuantity}
            />
            <Typography color="secondary" style={{ fontWeight: 600 }}>
              {quantity}
            </Typography>
            <IconButton
              icon="plus"
              variant="outlined"
              size={10}
              style={{
                color: colors.textSecondary,
                borderColor: colors.textSecondary,
                width: "15px",
                height: "15px",
                marginRight: "-1px",
              }}
              onClick={handleAddQuantity}
            />
          </Box>

          <Typography style={{ fontWeight: 600, fontSize: "16px" }}>
            {formattedValue}
          </Typography>
        </Box>
      </Box>

      <Box justify="center" align="center" style={{ width: "10%" }}>
        <IconButton
          icon="trash"
          variant="outlined"
          onClick={handleDeleteProduct}
          style={{
            color: colors.textSecondary,
            borderColor: colors.textSecondary,
          }}
        />
      </Box>
    </Box>
  );
}
