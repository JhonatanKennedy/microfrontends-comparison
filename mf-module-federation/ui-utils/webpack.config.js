const path = require("path");
const ModuleFederationPlugin = require("webpack/lib/container/ModuleFederationPlugin");

module.exports = {
  mode: "development",
  entry: "./src/index",
  resolve: {
    extensions: [".ts", ".tsx", ".js", ".jsx"],
    alias: {
      interfaces: path.resolve(__dirname, "../../interfaces/src"),
    },
  },
  output: {
    publicPath: "http://localhost:7000/",
  },
  devServer: {
    port: 7000,
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
    new ModuleFederationPlugin({
      name: "uiUtils",
      filename: "remoteEntry.js",
      exposes: {
        "./Button": "./src/Button",
        "./Box": "./src/Box",
        "./Icon": "./src/Icon",
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
