require 'spec_helper'

describe User do
  before do
    @user = User.new( name: 'Example Name',
                      email: 'user@example.com',
                      password: 'foobar',
                      password_confirmation: 'foobar',
                    )
  end

  subject { @user }

  it { should respond_to(:admin) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:email) }
  it { should respond_to(:feed) }
  it { should respond_to(:microposts) }
  it { should respond_to(:name) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:remember_token) }

  it { should be_valid }

  describe "when name is not present" do
    before { @user.name = '' }
    it { should_not be_valid }
  end

  describe "when email is not present" do
    before { @user.email = ' ' }
    it { should_not be_valid }
  end

  describe "when name is too long" do
    before { @user.name = 'a' * 257 }
    it { should_not be_valid }
  end

  describe "when email is malformed" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo. foo@bar_baz.com foo@bar+baz.com foo@bar..com]

      addresses.each do | invalid_address |
        @user.email = invalid_address
        expect(@user).not_to be_valid
      end
    end
  end

  describe "when email is wellformed" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]

      addresses.each do | address |
       @user.email = address
       expect(@user).to be_valid
      end
    end
  end

  describe "when email is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email.upcase!
      user_with_same_email.save
    end

    it { should_not be_valid }
  end

  describe "when password is not present" do
    before do
      @user = User.new( name: 'Example Name',
                        email: 'user@example.com',
                        password: ' ',
                        password_confirmation: ' ',
                      )
    end

    it { should_not be_valid }
  end

  describe "when password is not confirmed" do
    before { @user.password_confirmation = 'barfoo' }

    it { should_not be_valid }
  end

  describe "return value of authenticate method" do
    before { @user.save }
    let(:found_user) { User.find_by(email: @user.email) }

    describe "with valid password" do
      it { should eq found_user.authenticate(@user.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }
      it { should_not eq user_for_invalid_password }
      specify { expect(user_for_invalid_password).to be_false }
    end
  end

  describe "with a password that is too short" do
    before { @user.password = @user.password_confirmation = 'a' * Random.new.rand(1..5)}
    it { should_not be_valid }
  end

  describe "with a email stored is downcased" do
    let(:mixed_case_email_address) { 'EXAMPLE@example.INfo' }

    it "should have an equal value" do
      @user.email = mixed_case_email_address
      @user.save
      expect(@user.email).to eq mixed_case_email_address.downcase
    end
  end

  describe "remember token" do

    before { @user.save }
    its(:remember_token) { should_not be_blank }
  end

  describe "with admin set to true" do
    before do
      @user.save!
      @user.toggle(:admin)
    end

    it "should be an admin" do
      expect(@user).to be_admin
    end
  end

  describe "micropost associations" do

    before { @user.save }

    let!(:older_micropost) { FactoryGirl.create(:micropost, user: @user, created_at: 1.month.ago)}
    let!(:newer_micropost) { FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)}

    it "should have the right microposts in the correct order" do
      expect(@user.microposts.to_a).to eq [newer_micropost, older_micropost]
    end

    it "should destroy microposts upon user deletion" do
      microposts = @user.microposts.to_a
      @user.destroy
      expect(microposts).not_to be_empty

      microposts.each do |micropost|
        expect(Micropost.where(id: micropost.id)).to be_empty
      end

      expect(Micropost.where(user_id: @user.id)).to be_empty
    end

    describe "status" do
      let(:unfollowed_post) { FactoryGirl.create(:micropost, user: FactoryGirl.create(:user)) }

      it "should not display unfollowed posts" do
        expect(@user.feed).to include(newer_micropost)
        expect(@user.feed).to include(older_micropost)
        expect(@user.feed).not_to include(unfollowed_post)
      end
    end
  end
end
