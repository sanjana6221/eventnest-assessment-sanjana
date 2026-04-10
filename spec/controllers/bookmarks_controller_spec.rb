require "rails_helper"

RSpec.describe Api::V1::BookmarksController, type: :request do
  let(:attendee) { create(:user, role: "attendee") }
  let(:organizer) { create(:user, role: "organizer") }
  let(:event) { create(:event) }

  def auth_headers(user)
    { "Authorization" => "Bearer #{user.generate_jwt}" }
  end

  describe "POST /events/:event_id/bookmark" do
    it "allows attendee to bookmark" do
      post "/api/v1/events/#{event.id}/bookmark", headers: auth_headers(attendee)

      expect(response).to have_http_status(:created)
    end

    it "rejects duplicate bookmark" do
      create(:bookmark, user: attendee, event: event)

      post "/api/v1/events/#{event.id}/bookmark", headers: auth_headers(attendee)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects organizer bookmarking" do
      post "/api/v1/events/#{event.id}/bookmark", headers: auth_headers(organizer)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /bookmarks" do
    it "lists user bookmarks" do
      create(:bookmark, user: attendee, event: event)

      get "/api/v1/bookmarks", headers: auth_headers(attendee)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end
  end

  describe "DELETE /events/:event_id/bookmark" do
    it "removes bookmark" do
      create(:bookmark, user: attendee, event: event)

      delete "/api/v1/events/#{event.id}/bookmark", headers: auth_headers(attendee)

      expect(response).to have_http_status(:ok)
    end
  end
end
