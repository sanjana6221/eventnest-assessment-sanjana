module Api
  module V1
    class BookmarksController < ApplicationController

      # GET /bookmarks
      def index
        bookmarks = current_user.bookmarks.includes(:event)

        render json: bookmarks.map { |b|
          {
            id: b.id,
            event: {
              id: b.event.id,
              title: b.event.title,
              city: b.event.city
            }
          }
        }
      end

      # POST /events/:event_id/bookmark
      def create
        event = Event.find(params[:event_id])

        unless current_user.attendee?
          return render json: { error: "Only attendees can bookmark events" }, status: :forbidden
        end

        bookmark = current_user.bookmarks.new(event: event)

        if bookmark.save
          render json: { message: "Bookmarked successfully" }, status: :created
        else
          render json: { error: "Already bookmarked" }, status: :unprocessable_entity
        end
      end

      # DELETE /events/:event_id/bookmark
      def destroy
        bookmark = current_user.bookmarks.find_by(event_id: params[:event_id])

        if bookmark
          bookmark.destroy
          render json: { message: "Bookmark removed" }
        else
          render json: { error: "Bookmark not found" }, status: :not_found
        end
      end
    end
  end
end
