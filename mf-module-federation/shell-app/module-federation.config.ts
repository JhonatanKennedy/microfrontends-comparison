import { createModuleFederationConfig } from "@module-federation/rsbuild-plugin";

export default createModuleFederationConfig({
  name: "shell_app",
  dts: false,
  remotes: {
    homeApp: "homeApp@http://localhost:8001/mf-manifest.json",
    checkoutApp: "checkoutApp@http://localhost:8002/mf-manifest.json",
  },
  shareStrategy: "loaded-first",
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
