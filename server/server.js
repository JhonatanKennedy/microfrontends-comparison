const express = require("express");
const path = require("path");
const app = express();
const cors = require("cors");
const port = 3000;
const data = require("./data");

app.use(cors());

app.use(express.static(path.join(__dirname, "public")));

app.get("/products", (req, res) => {
  const baseUrl = `http://localhost:${port}`;

  const newData = data.module.map((product) => {
    return { ...product, photoURL: `${baseUrl}/${product.photoURL}` };
  });

  res.json(newData);
});

app.listen(port, () => {
  console.log(`Server up and running at http://localhost:${port}`);
});
