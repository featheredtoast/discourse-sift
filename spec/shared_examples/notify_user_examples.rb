# frozen_string_literal: true

shared_examples 'It notifies users when the setting is enabled' do
  it 'Notifies user if the setting is enabled' do
    SiteSetting.sift_notify_user = true
    perform_action
    expect(Jobs::SendSystemMessage.jobs.length).to eq(1)
  end

  it 'Does nothing when the setting is disabled' do
    SiteSetting.sift_notify_user = false
    perform_action
    expect(Jobs::SendSystemMessage.jobs.length).to eq(0)
  end
end
