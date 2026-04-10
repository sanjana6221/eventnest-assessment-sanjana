require "rails_helper"

RSpec.describe Api::V1::AuthController, type: :request do
  let(:admin) { create(:user, :admin) }
  let(:attendee) { create(:user) }

  def auth_headers(user)
    token = user.generate_jwt
    { "Authorization" => "Bearer #{token}" }
  end

  describe "POST /api/v1/auth/register" do
    let(:register_params) do
      {
        name: "New User",
        email: "new-user@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: "admin",
        phone: "9999999999"
      }
    end

    it "allows public user registration" do
      post "/api/v1/auth/register", params: register_params

      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)
      expect(data["user"]["email"]).to eq("new-user@example.com")
    end

    it "ignores role parameter and assigns default attendee role" do
      post "/api/v1/auth/register", params: register_params

      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)
      expect(data["user"]["role"]).to eq("attendee")
      expect(User.last.role).to eq("attendee")
    end
  end

  describe "POST /api/v1/auth/login" do
    it "allows an attendee to login" do
      post "/api/v1/auth/login", params: { email: attendee.email, password: "password123" }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["user"]["role"]).to eq("attendee")
      expect(data["token"]).to be_present
    end

    it "allows an admin to login" do
      post "/api/v1/auth/login", params: { email: admin.email, password: "password123" }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["user"]["role"]).to eq("admin")
      expect(data["token"]).to be_present
    end
  end
end
