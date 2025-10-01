import { MouseEvent } from "react";
import { navigateToUrl } from "single-spa";

export function navigateOnButtonPress(e: MouseEvent<HTMLButtonElement>) {
  navigateToUrl(e.currentTarget.name);
}
