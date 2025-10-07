import { defineConfig } from "@rsbuild/core";
import { pluginReact } from "@rsbuild/plugin-react";
import { pluginModuleFederation } from "@module-federation/rsbuild-plugin";
import moduleFederationConfig from "./module-federation.config";

export default defineConfig({
  plugins: [pluginReact(), pluginModuleFederation(moduleFederationConfig)],
  server: {
    port: 9000,
  },
  html: {
    template: "./public/index.html",
  },
  output: {
    assetPrefix: "http://localhost:9000/",
  },
  performance: {
    bundleAnalyze: process.env.BUNDLE_ANALYZE
      ? {
          analyzerMode: "static",
          openAnalyzer: true,
        }
      : undefined,
  },
});
