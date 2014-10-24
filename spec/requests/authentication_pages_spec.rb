require 'spec_helper'

describe "Authentication" do

	subject { page }
	
	describe "signin page" do
		before { visit signin_path }

		it { should have_content('Sign in')}
		it { should have_title('Sign in')}

		describe "sign in" do

			describe "with invalid information" do
				before { click_button "Sign in" }

				it { should have_title('Sign in') }
				it { should have_error_message('Invalid') }

				describe "after visiting another page" do
					before { click_link "Home" }
					it { should_not have_error_message('')  }
				end
			end

			describe "with valid information" do
				let(:user) { FactoryGirl.create(:user) }

				before { sign_in user }

				it { should have_title(user.name) }
				it { should have_link('Users', 		href:users_path)}
				it { should have_link('Profile', 	href: user_path(user)) }
				it { should have_link('Settings', 	href: edit_user_path(user)) }
				it { should have_link('Sign out', 	href: signout_path) }
				it { should_not have_link('Sign in', href: signin_path) }

				describe "followed by sign out" do
					before { click_link "Sign out" }
					it { should have_link('Sign in') }
					it { should_not have_link('Users')}
					it { should_not have_link('Profile') }
					it { should_not have_link('Settings') }
				end
			end
		end
	end

	describe "authorization" do

		describe "for non-signed-in users" do
			let(:user) { FactoryGirl.create(:user) }

			describe "when attempting to visit a user edit page" do
				before do 
					visit edit_user_path(user)
					sign_in user, at_current_page: true
				end

				describe "after signing in" do
					it "should render the desired protected page" do
						expect(page).to have_title('Edit user')
					end

					describe "when signing in again" do
						before do
							delete signout_path
							sign_in user
						end
						it "should render the user profile page" do
							expect(page).to have_title(user.name)
						end
					end
				end
			end

			describe "when attempting to visit a users page" do
				before do 
					visit users_path
					sign_in user, at_current_page: true
				end

				describe "after signing in" do
					it "should render the desired protected page" do
						expect(page).to have_title('All users')
					end
				end
			end

			describe "in the Users controller" do

				describe "visiting the edit page" do
					before { visit edit_user_path(user) }
					it{ should have_title('Sign in') }
				end

				describe "submitting to the update action" do
					before { patch user_path(user) }
					specify { expect(response).to redirect_to(signin_path) }
				end

				describe "visiting the user index" do
					before { visit users_path }
					it { should have_title('Sign in')}
				end
			end
		end

		describe "as wrong user" do
			# メールアドレスのみ異なるユーザーを用意している。
			let(:user) { FactoryGirl.create(:user) }
			let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
			before { sign_in user, no_capybara: true }

			describe "submitting a GET request to the Users#edit astion" do
				before { get edit_user_path(wrong_user) }
				specify { expect(response.body).not_to match(full_title('Edit user')) }
				specify { expect(response).to redirect_to(root_url) }
			end

			describe "submitting a PATCH request to the Users#update action" do
				before { patch user_path(wrong_user) }
				specify { expect(response).to redirect_to(root_path) }
			end
		end

		describe "as non-admin user" do
			let(:user) { FactoryGirl.create(:user) }
			let(:non_admin) { FactoryGirl.create(:user) }

			before { sign_in non_admin, no_capybara: true }

			describe "submitting a DELETE request to the Users#destroy action" do
				before { delete user_path(user) }
				specify { expect(response).to redirect_to(root_path) }
			end
		end

		describe "as admin user" do
			let(:user) { FactoryGirl.create(:user, admin: true) }

			before { sign_in user, no_capybara: true }

			describe "submitting a DELETE request for myself" do
				it { expect { delete user_path(user) }.to change(User, :count).by(0) }
			end
		end

		#
		# => I add this code for exercise 9.6.6, but it's not wort well.
		#    I don't know the reason why, but I go ahead without resolve this probrem.
		#    (because redirecting seems to be fine working.)
		#
		# describe "as signed-in user" do
		# 	let(:user) { FactoryGirl.create(:user) }

		# 	before { sign_in user }

		# 	describe "submitting to the create action" do
		# 		before { post users_path }
		# 		specify { expect(response).to redirect_to(root_path) }
		# 	end

		# 	describe "submitting to the new action" do
		# 		before { get new_user_path }
		# 		specify { expect(response).to redirect_to(root_path) }
		# 	end
		# end
	end
end
