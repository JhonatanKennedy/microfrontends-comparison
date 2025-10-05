import { createModuleFederationConfig } from "@module-federation/rsbuild-plugin";

export default createModuleFederationConfig({
  name: "home_app",
  dts: false,
  exposes: {
    "./Home": "./src/Home.tsx",
  },
  remotes: {
    uiUtils: "uiUtils@http://localhost:7000/mf-manifest.json",
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
    "react-router": {
      singleton: true,
      requiredVersion: "^7.9.3",
      eager: false,
    },
  },
});
