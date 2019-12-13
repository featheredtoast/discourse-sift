# frozen_string_literal: true

#
# Based on https://github.com/discourse/discourse-akismet/blob/master/jobs/check_akismet_post.rb
#
module Jobs
  class ReportPostAction < ::Jobs::Base

    # Send a post to Sift to report agree or disagree with classification
    def execute(args)

      # Rails.logger.debug("sift_debug: report_post job: enter")

      raise Discourse::InvalidParameters.new(:action) unless args[:action].present?
      raise Discourse::InvalidParameters.new(:post_id) unless args[:post_id].present?
      raise Discourse::InvalidParameters.new(:moderator_id) unless args[:moderator_id].present?
      return unless SiteSetting.sift_enabled?

      action = args[:action]
      post_id = args[:post_id]
      moderator_id = args[:moderator_id]

      # Rails.logger.debug("sift_debug: report_post job: action: #{action}, post_id: #{post_id}, moderator_id: #{moderator_id}")

      # Post
      post = Post.where(id: post_id).first
      # Rails.logger.debug("sift_debug: report_post job: post: #{post.inspect}")
      return unless post.present?

      # Moderator
      moderator = User.where(id: moderator_id).first
      # Rails.logger.debug("sift_debug: report_post job: moderator: #{moderator.inspect}")
      return unless post.present?

      Sift::Client.with_client do |client|
        reason = action
        extra_reason_remarks = args[:extra_reason_remarks]

        client.submit_for_post_action(post, moderator, reason, extra_reason_remarks)
      end

    end
  end
end
