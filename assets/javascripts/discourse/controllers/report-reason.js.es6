import {
  default as computed,
  on
} from "ember-addons/ember-computed-decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Controller.extend({
  reported_reason: null,
  other_reason: null,

  @on("init")
  reset() {
    this.setProperties({ reported_reason: null, other_reason: null });
  },

  @computed("reported_reason", "other_reason")
  attachDisabled(reported_reason, other_reason) {
    if (reported_reason === "other") {
      return !other_reason || other_reason.length === 0;
    }
    else {
      return !reported_reason;
    }
  },

  actions: {
    submitReport() {
      if (this.callback) {
        this.callback(this.reported_reason, this.other_reason);
      }

      console.log("after callback");
      this.modal.send("closeModal");
    },

  }
});
