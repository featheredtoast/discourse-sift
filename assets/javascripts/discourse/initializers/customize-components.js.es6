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
        clientSiftDisagree(reviewable, performAction) {
          console.log("in clientDisagree yay");
          console.log(performAction);
          console.log(reviewable);

          // Popup disagree reason
          //   Pass in all needed to call SiftMod.disagree_action from the popup's controller
          performAction().then(function (result) {
            console.log("in perform action then()");
            console.log("in perform action then(): result = " + result);
            console.log(result);

            SiftMod.disagree_action()

          });
        }

      });
    });
  }
};
