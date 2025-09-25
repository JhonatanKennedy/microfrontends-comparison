import { createRoot } from "react-dom/client";
import Home from "./home";

const container = document.getElementById("root");

if (container) {
  const root = createRoot(container);
  root.render(<Home />);
} else {
  console.error("Elemento com ID 'root' não encontrado no DOM.");
}
