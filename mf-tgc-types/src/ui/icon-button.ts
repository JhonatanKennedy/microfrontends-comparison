import { ButtonHTMLAttributes } from "react";
import { IconList } from "./css-rules";

export type TIconButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "outlined";
  icon?: IconList;
  iconPosition?: "start" | "end";
  hide?: boolean;
  size?: number;
};
