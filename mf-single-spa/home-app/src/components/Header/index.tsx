import {
  colors,
  Box,
  Input,
  Typography,
  IconButton,
} from "@single-spa/ui-utils";
import { MouseEvent } from "react";

type THeaderProps = {
  countCar: number;
  onChangeName: (value: string) => void;
};

export function Header({ onChangeName, countCar }: THeaderProps) {
  const count = countCar > 9 ? "9+" : String(countCar);

  function handleCart(e: MouseEvent<HTMLButtonElement>) {
    window.location.pathname = e.currentTarget.name;
  }

  return (
    <Box
      justify="space-evenly"
      align="center"
      gap={12}
      style={{
        backgroundColor: colors.primary,
        padding: "30px 0px",
        width: "100%",
        flexWrap: "wrap",
      }}
    >
      <Typography
        component="span"
        variant="h1"
        style={{ color: colors.background }}
      >
        LOGO
      </Typography>

      <Input name="search" placeholder="Pesquisa" onChangeName={onChangeName} />

      <Box style={{ position: "relative" }}>
        <IconButton
          name="/checkout"
          icon="cart"
          variant="secondary"
          onClick={handleCart}
        />
        <Typography
          style={{
            fontSize: "10px",
            color: colors.background,
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            position: "absolute",
            backgroundColor: colors.error,
            height: "15px",
            width: "15px",
            borderRadius: "50%",
            top: -5,
            right: -5,
          }}
        >
          {count}
        </Typography>
      </Box>
    </Box>
  );
}
