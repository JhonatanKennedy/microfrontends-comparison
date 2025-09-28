const HtmlWebpackPlugin = require("html-webpack-plugin");
const path = require("path");
const ModuleFederationPlugin = require("webpack/lib/container/ModuleFederationPlugin");

module.exports = {
  mode: "development",
  entry: "./src/index.js",
  resolve: {
    extensions: [".ts", ".tsx", ".js", ".jsx"],
    alias: {
      interfaces: path.resolve(__dirname, "../../interfaces/src"),
    },
  },
  output: {
    publicPath: "http://localhost:8001/",
  },
  devServer: {
    port: 8001,
  },
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: "ts-loader",
        exclude: /node_modules/,
      },
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: "./public/index.html",
    }),
    new ModuleFederationPlugin({
      name: "homeApp",
      filename: "remoteEntry.js",
      exposes: {
        "./Home": "./src/home.tsx",
      },
      remotes: {
        uiUtils: "uiUtils@http://localhost:7000/remoteEntry.js",
      },
      shared: {
        react: {
          singleton: true,
          requiredVersion: "^18.2.0",
        },
        "react-dom": {
          singleton: true,
          requiredVersion: "^18.2.0",
        },
      },
    }),
  ],
};
