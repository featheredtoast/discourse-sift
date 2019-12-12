import { ajax } from 'discourse/lib/ajax';

export default {
    confirmFailed(post) {
        return ajax("/admin/plugins/sift/mod/confirm_failed", {
            type: "POST",
            data: {
                post_id: post.get("id")
            }
        });
    },

    disagree(post, reason){
        return ajax("/admin/plugins/sift/mod/disagree", {
            type: "POST",
            data: {
                post_id: post.get("id"),
                reason: reason
            }
        });
    },

    disagree_action(reason, post_id, moderator_id, extra_reason_remarks){
        console.log("disagree_id enter...");
        return ajax("/admin/plugins/sift/mod/disagree_action", {
            type: "POST",
            data: {
                reason: reason,
                post_id: post_id,
                moderator_id: moderator_id,
                extra_reason_remarks: extra_reason_remarks
            }
        });
    },

    disagreeOther(post, reason, otherReason){
        return ajax("/admin/plugins/sift/mod/disagree_other", {
            type: "POST",
            data: {
                post_id: post.get("id"),
                reason: reason,
                other_reason: otherReason
            }
        });
    },
};
