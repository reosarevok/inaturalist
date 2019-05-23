# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe UserParent, "creation" do
  # Note: to test mail deliver from Devise you have to use transaction cleaning
  # b/c Devise only delivers emails after_commit
  before(:all) { DatabaseCleaner.strategy = :truncation }
  after(:all)  { DatabaseCleaner.strategy = :transaction }

  it "should not trigger the delivery of any emails" do
    deliveries = Devise.mailer.deliveries.size
    # The blueprint makes an active user that was a created a little while ago
    # by default, so we need to make a new user here
    user = User.make
    up = UserParent.make!(
      user: User.new(
        login: user.login,
        email: user.email,
        birthday: 9.years.ago.to_date.to_s,
        password: "foofoo",
        password_confirmation: "foofoo"
      )
    )
    Delayed::Worker.new.work_off
    expect( Devise.mailer.deliveries.size ).to eq deliveries
  end
end

describe UserParent, "donorbox_donor_id" do
  it "should deliver an email when set" do
    up = UserParent.make!
    deliveries = ActionMailer::Base.deliveries.size
    up.update_attributes( donorbox_donor_id: 1 )
    expect( ActionMailer::Base.deliveries.size ).to eq deliveries + 1
  end
end
