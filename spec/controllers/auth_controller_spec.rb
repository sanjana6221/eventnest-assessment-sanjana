require "rails_helper"

RSpec.describe Api::V1::AuthController, type: :request do
  let(:attendee) { create(:user, role: "attendee") }
  let(:admin) { create(:user, role: "admin") }

  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      {
        name: "New User",
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: "admin", # malicious attempt
        phone: "9999999999"
      }
    end

    it "allows public user registration" do
      post "/api/v1/auth/register", params: valid_params

      expect(response).to have_http_status(:created)

      data = JSON.parse(response.body)
      expect(data["user"]["email"]).to eq("newuser@example.com")
      expect(data["token"]).to be_present
    end

    it "ignores role parameter and assigns default attendee role" do
      post "/api/v1/auth/register", params: valid_params

      expect(response).to have_http_status(:created)

      data = JSON.parse(response.body)
      expect(data["user"]["role"]).to eq("attendee")
      expect(User.last.role).to eq("attendee")
    end

    it "fails with invalid data" do
      post "/api/v1/auth/register", params: { email: "" }

      expect(response).to have_http_status(:unprocessable_entity)

      data = JSON.parse(response.body)
      expect(data["errors"]).to be_present
    end
  end

  describe "POST /api/v1/auth/login" do
    it "allows an attendee to login" do
      post "/api/v1/auth/login", params: {
        email: attendee.email,
        password: "password123"
      }

      expect(response).to have_http_status(:ok)

      data = JSON.parse(response.body)
      expect(data["token"]).to be_present
      expect(data["user"]["role"]).to eq("attendee")
    end

    it "allows an admin to login" do
      post "/api/v1/auth/login", params: {
        email: admin.email,
        password: "password123"
      }

      expect(response).to have_http_status(:ok)

      data = JSON.parse(response.body)
      expect(data["token"]).to be_present
      expect(data["user"]["role"]).to eq("admin")
    end

    it "returns error for wrong password" do
      post "/api/v1/auth/login", params: {
        email: attendee.email,
        password: "wrongpassword"
      }

      expect(response).to have_http_status(:unauthorized)

      data = JSON.parse(response.body)
      expect(data["error"]).to eq("Invalid password")
    end

    it "returns error for non-existent user" do
      post "/api/v1/auth/login", params: {
        email: "unknown@example.com",
        password: "password123"
      }

      expect(response).to have_http_status(:unauthorized)

      data = JSON.parse(response.body)
      expect(data["error"]).to eq("No account found with that email")
    end
  end
end
