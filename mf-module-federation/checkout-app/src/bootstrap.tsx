import { createRoot } from "react-dom/client";
import Checkout from "./Checkout";

const container = document.getElementById("root");

if (container) {
  const root = createRoot(container);
  root.render(<Checkout />);
} else {
  console.error("Elemento com ID 'root' não encontrado no DOM.");
}
