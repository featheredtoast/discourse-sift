import showModal from "discourse/lib/show-modal";
import loadScript from "discourse/lib/load-script";

export function showReportReason(reviewable, callback, opts) {
  opts = opts || {};

  return loadScript("defer/html-sanitizer-bundle").then(() => {
    const controller = showModal("report-reason", {
      reviewable,
      title: "sift.report_reason.title",
      addModalBodyView: true
    });

    controller.reset();

    controller.setProperties({
      callback: callback
    });

    return controller;
  });
}
