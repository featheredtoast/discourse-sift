require_dependency 'reviewable'

class ReviewableSiftPost < Reviewable
  def post
    @post ||= (target || Post.with_deleted.find_by(id: target_id))
  end

  def build_actions(actions, guardian, _args)
    return [] unless pending?


    delete = actions.add_bundle("#{id}-disagree", icon: "thumbs-down", label: "reviewables.actions.disagree.title")
    build_action_nested(actions, :disagree_due_to_false_positive, icon: 'thumbs-down', bundle: delete)
    build_action_nested(actions, :disagree_due_to_too_strict, icon: 'thumbs-down', bundle: delete)
    build_action_nested(actions, :disagree_due_to_user_edited, icon: 'thumbs-down', bundle: delete)
    build_action_nested(actions, :disagree_due_to_other_reasons, icon: 'thumbs-down', bundle: delete)

    # build_action(actions, :confirm_failed, icon: 'check', key: 'confirm_fails_policy')
    build_action(actions, :allow, icon: 'thumbs-up', key: 'confirm_passes_policy')
    build_action(actions, :ignore, icon: 'times', key: 'dismiss')
  end

  def build_action_nested(actions, id, icon:, bundle: nil, client_action: nil, confirm: false)
    actions.add(id, bundle: bundle) do |action|
      prefix = "reviewables.actions.#{id}"
      action.icon = icon
      action.label = "#{prefix}.title"
      action.description = "#{prefix}.description"
      action.client_action = client_action
      action.confirm_message = "#{prefix}.confirm" if confirm
    end
  end

  def perform_confirm_failed(performed_by, _args)
    # If post has not been deleted (i.e. if setting is on)
    # Then delete it now
    if post.deleted_at.blank?
      PostDestroyer.new(performed_by, post).destroy

      if SiteSetting.sift_notify_user
        SystemMessage.create(
          post.user,
          'sift_has_moderated',
          topic_title: post.topic.title
        )
      end
    end

    log_confirmation(performed_by, 'sift_confirmed_failed')
    successful_transition :approved, :agreed
  end

  def perform_allow(performed_by, _args)
    # It's possible the post was recovered already
    PostDestroyer.new(performed_by, post).recover if post.deleted_at

    log_confirmation(performed_by, 'sift_confirmed_passed')
    result = successful_transition :rejected, :disagreed

    report_to_action_queue('agree', nil )

    return result
  end

  def perform_disagree_due_to_false_positive(performed_by, _args)

    result = perform_confirm_failed(performed_by, _args)
    # Rails.logger.debug("sift_debug: report_to_action_queue Enter: performed_by='#{performed_by}'")
    report_to_action_queue('false_positive', nil )
    return result
  end

  def perform_disagree_due_to_too_strict(performed_by, _args)

    result = perform_confirm_failed(performed_by, _args)
    # Rails.logger.debug("sift_debug: report_to_action_queue Enter: performed_by='#{performed_by}'")
    report_to_action_queue('too_strict', nil )
    return result
  end

  def perform_disagree_due_to_user_edited(performed_by, _args)

    result = perform_confirm_failed(performed_by, _args)
    # Rails.logger.debug("sift_debug: report_to_action_queue Enter: performed_by='#{performed_by}'")
    report_to_action_queue('user_edited', nil )
    return result
    end

  def perform_disagree_due_to_user_edited(performed_by, _args)

    result = perform_confirm_failed(performed_by, _args)
    # Rails.logger.debug("sift_debug: report_to_action_queue Enter: performed_by='#{performed_by}'")
    # <%= javascript_tag "alert('hello welcome')" unless result %>
    report_to_action_queue('user_edited', nil )
    return result
  end

  def perform_ignore(performed_by, _args)
    log_confirmation(performed_by, 'sift_ignored')
    successful_transition :ignored, :ignored
  end

  private

  def build_action(actions, id, icon:, bundle: nil, key:)
    actions.add(id, bundle: bundle) do |action|
      action.icon = icon
      action.label = "js.sift.#{key}"
    end
  end

  def successful_transition(to_state, update_flag_status, recalculate_score: true)
    create_result(:success, to_state)  do |result|
      result.recalculate_score = recalculate_score
      result.update_flag_stats = { status: update_flag_status, user_ids: [created_by_id] }
    end
  end

  def log_confirmation(performed_by, custom_type)
    StaffActionLogger.new(performed_by).log_custom(custom_type,
      post_id: post.id, topic_id: post.topic_id
    )
  end

  def report_to_action_queue(reason, extra_reason_remarks)
    # Only call Sift if the setting is set
    # TODO: should there also be a boolean toggle or is this suffcient?

    Rails.logger.debug("sift_debug: report_to_action_queue Enter: reason='#{reason}'")

    if !SiteSetting.sift_action_end_point.blank?
      DiscourseSift.with_client do |client|
        result = client.submit_for_post_action(self, reason, extra_reason_remarks)
      end
    end
  end

end
