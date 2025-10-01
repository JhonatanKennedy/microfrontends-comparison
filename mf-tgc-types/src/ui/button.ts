import { ButtonHTMLAttributes } from "react";

export type TButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "contained" | "outlined" | "text";
  color?: "primary" | "secondary";
};
