import { Suspense, lazy } from "react";
import { createRoot } from "react-dom/client";

const Home = lazy(() => import("homeApp/Home"));

function App() {
  //TODO trazer um react router dom pra um arquivo proximo e importar aqui
  return (
    <div>
      <Suspense fallback={<div>Loading...</div>}>
        <Home />
      </Suspense>
    </div>
  );
}

const container = document.getElementById("root");

if (container) {
  const root = createRoot(container);
  root.render(<App />);
} else {
  console.error("Elemento com ID 'root' não encontrado no DOM.");
}
