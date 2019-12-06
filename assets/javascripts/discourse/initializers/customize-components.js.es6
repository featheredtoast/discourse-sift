import { withPluginApi } from "discourse/lib/plugin-api";
export default {
  name: "customize-components",
  after: "inject-objects",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    withPluginApi("0.8.14", api => {
      const { h } = api;

      api.modifyClass("component:reviewable-item", {
        clientTest(reviewable, performAction) {
          console.log("doing a client test action yay");
        }
      });
    });
  }
};
