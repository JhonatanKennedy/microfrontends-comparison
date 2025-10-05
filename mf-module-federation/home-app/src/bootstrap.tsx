import { createRoot } from "react-dom/client";
import Home from "./Home";
import { BrowserRouter } from "react-router";

const container = document.getElementById("root");

if (container) {
  const root = createRoot(container);
  root.render(
    <BrowserRouter>
      <Home />
    </BrowserRouter>
  );
} else {
  console.error("Elemento com ID 'root' não encontrado no DOM.");
}
