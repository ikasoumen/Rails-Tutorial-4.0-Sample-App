require 'spec_helper'

describe "User Pages" do

	subject { page }

	describe "index" do
		let(:user) { FactoryGirl.create(:user) }

		before(:each) do
			sign_in user
			visit users_path
		end

		it { should have_title('All users') }
		it { should have_content('All users') }

		describe "pagination" do

			before(:all) { 30.times { FactoryGirl.create(:user) } }
			after(:all) { User.delete_all }

			it { should have_selector('div.pagination') }

			it "should list each user" do
				User.paginate(page: 1).each do |user|
					expect(page).to have_selector('li', text: user.name)
				end
			end
		end

		describe "delete links" do
			it { should_not have_link('delete') }

			describe "as an admin user" do
				let(:admin) { FactoryGirl.create(:admin) }
				before do
					sign_in admin
					visit users_path
				end

				it { should have_link('delete', href: user_path(User.first)) }
				it "should be able to delete another user" do
					expect do 
						click_link('delete', match: :first)
					end.to change(User, :count).by(-1)
				end
				it { should_not have_link('delete', href: user_path(admin)) }
			end
		end

		describe "forbbiden attributes" do
			let(:params) do
				{ user: { admin: true, password: user.password,
						  password_confirmation: user.password } }
			end

			before do 
				sign_in user, no_capybara: true
				patch user_path(user), params
			end
			specify { expect(user.reload).not_to be_admin }
		end
	end

	describe "profile page" do
		let(:user) { FactoryGirl.create(:user) }
		let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
		let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }
		before { visit user_path(user) }

		it { should have_content(user.name) }
		it { should have_title(user.name) }

		describe "microposts" do
			it { should have_content(m1.content) }
			it { should have_content(m2.content) }
			it { should have_content(user.microposts.count) }

			describe "with signed-in" do
				before { sign_in user }
				it { should have_link('delete', href: micropost_path(m1)) }
			end

			describe "microposts posted by another user" do
				let(:another_user) { FactoryGirl.create(:user) }
				let!(:m3) { FactoryGirl.create(:micropost, user: another_user, content: "FooBar") }
				before do 
					sign_in user
					visit user_path(another_user)
				end
				it { should_not have_link('delete', href: micropost_path(m3)) }
			end
		end
	end

	describe "home page" do
		let(:user) { FactoryGirl.create(:user) }
		before do
			FactoryGirl.create(:micropost, user: user, content: "Foo")
			sign_in user
			visit root_path
		end

		it { should have_content("1 micropost") }
		it { should_not have_content("microposts") }

		describe "with multiple posts" do 
			before do # ここで再読み込みして、post数を更新している
				FactoryGirl.create(:micropost, user: user, content: "Bar")
				visit root_path
			end 
			it { should have_content("2 microposts")}
		end

		describe "pagination" do
			before do # ここで再読み込みして、paginationを更新している
				30.times { FactoryGirl.create(:micropost, user: user, content: "FooBar") }
				visit root_path
			end

			it { should have_selector('div.pagination') }
		end
	end
 	
 	describe "signup page" do
		before { visit signup_path }

		it { should have_content('Sign up')}
		it { should have_title(full_title('Sign up')) }
	end

	describe "signup" do

		before { visit signup_path }

		let(:submit) { "Create my account" }

		describe "with invalid information" do
			it "should not create a user" do
				expect { click_button submit }.not_to change(User, :count)
			end

			describe "after submission" do
				before { click_button submit }

				it { should have_title('Sign up') }
				it { should have_content('error') }
			end
		end

		describe "with valid information" do
			before do
				fill_in "Name",			with: "Example User"
				fill_in "Email",		with: "user@example.com"
				fill_in "Password",		with: "foobar"
				fill_in "Confirm password",	with: "foobar"
			end

			it "should create a user" do
				expect { click_button submit }.to change(User, :count).by(1)
			end

			describe "after saving the user" do
				before { click_button submit }
				let(:user) { User.find_by( email: 'user@example.com' )}

				it { should have_link('Sign out')}
				it { should have_title(user.name) }
				it { should have_selector('div.alert.alert-success', text: 'Welcome' ) }
			end
		end
	end

	describe "edit" do
		let(:user) { FactoryGirl.create(:user) }
		before do
			sign_in user
			visit edit_user_path(user)
		end

		describe "page" do
			it { should have_content("Update your profile") }
			it { should have_title("Edit user") }
			it { should have_link('Change gravatar', href: 'http://gravatar.com/emails') }
		end

		describe "with valid information" do
			let(:new_name) { "New Name" }
			let(:new_email) { "new@example.com"}

			before do
				fill_in "Name", with: new_name
				fill_in "Email", with: new_email
				fill_in "Password", with: user.password
				fill_in "Confirm password", with: user.password
				click_button "Save changes"
			end

			it { should have_title(new_name) }
			it { should have_selector('div.alert.alert-success') }
			it { should have_link('Sign out', href: signout_path) }
			specify { expect(user.reload.name).to eq new_name }
			specify { expect(user.reload.email).to eq new_email }
		end

		describe "with invalid information" do
			before { click_button "Save changes" }
			it { should have_content "error"}
		end
	end
end
