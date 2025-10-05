import { createModuleFederationConfig } from "@module-federation/rsbuild-plugin";

export default createModuleFederationConfig({
  name: "ui_utils",
  dts: false,
  exposes: {
    ".": "./src/Utils.tsx",
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
});
