import { withPluginApi } from "discourse/lib/plugin-api";
import SiftMod from 'discourse/plugins/discourse-sift/admin/models/sift-mod';

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
          console.log(performAction);
          console.log(reviewable);

          console.log("before SiftMod");
          SiftMod.disagree_action(reviewable.id, "user_edited");
          console.log("after SiftMod");

          console.log("before performAction");
          var result = performAction();
          result.then(result => {
            console.log("in result => then");
            console.log(result);
          });
          console.log("after performAction");
          console.log("after performAction: result = " + result.toString());
          console.log(result);
        },

        clientSiftDisagree(reviewable, performAction) {
          console.log("in clientDisagree yay");
          console.log(performAction);
          console.log(reviewable);
        }

      });
    });
  }
};
