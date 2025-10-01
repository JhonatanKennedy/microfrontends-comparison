import { CSSProperties, ReactNode } from "react";
import { FlexDirection } from "./css-rules";

export type TBoxProps = {
  children?: ReactNode;
  direction?: FlexDirection;
  gap?: number;
  align?: CSSProperties["alignItems"];
  justify?: CSSProperties["justifyContent"];
  wrap?: boolean;
  className?: string;
  style?: CSSProperties;
};
