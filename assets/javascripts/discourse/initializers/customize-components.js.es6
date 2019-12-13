import { withPluginApi } from "discourse/lib/plugin-api";
import SiftMod from 'discourse/plugins/discourse-sift/admin/models/sift-mod';
import { showReportReason } from "discourse/plugins/discourse-sift/discourse-sift/lib/report-reason";

export default {
  name: "customize-components",
  after: "inject-objects",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    withPluginApi("0.8.14", api => {
      const { h } = api;

      api.modifyClass("component:reviewable-item", {

        clientSiftDisagree(reviewable, performAction) {
          // Popup disagree reason
          var post_id = reviewable.post_id;
          var moderator_id = api.getCurrentUser().id;

          var report_controller = showReportReason(reviewable, (reason, other_reason) => {
            // console.log("In showReportReason callback: reason=" + reason + ", other_reason=" + other_reason);
            // console.log("In showReportReason callback: post_id=" + post_id);
            // console.log("In showReportReason callback: moderator_id=" + moderator_id);

            // Call the perform action to complete the mod action, and on the promise completion call Sift
            performAction().then(function (result) {
              // console.log("in perform action then()");

              // Call the Sift Reporting endpoint
              SiftMod.disagree_action(reason, post_id, moderator_id, other_reason);

            });


          });

        }

      });
    });
  }
};
