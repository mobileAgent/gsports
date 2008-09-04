# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080904124857) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id",    :limit => 10
    t.string   "action",     :limit => 50
    t.integer  "item_id",    :limit => 10
    t.string   "item_type"
    t.datetime "created_at"
  end

  add_index "activities", ["created_at"], :name => "index_activities_on_created_at"
  add_index "activities", ["user_id"], :name => "index_activities_on_user_id"

  create_table "addresses", :force => true do |t|
    t.string   "firstname"
    t.string   "minitial"
    t.string   "lastname"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "phone"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "zip"
    t.integer  "addressable_id",   :limit => 11
    t.string   "addressable_type"
  end

  create_table "ads", :force => true do |t|
    t.string   "name"
    t.text     "html"
    t.integer  "frequency",        :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "location"
    t.boolean  "published",                      :default => false
    t.boolean  "time_constrained",               :default => false
    t.string   "audience",                       :default => "all"
  end

  create_table "applied_monikers", :force => true do |t|
    t.integer  "moniker_id", :limit => 11, :null => false
    t.integer  "user_id",    :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", :force => true do |t|
    t.string   "filename"
    t.integer  "width",           :limit => 11
    t.integer  "height",          :limit => 11
    t.string   "content_type"
    t.integer  "size",            :limit => 11
    t.string   "attachable_type"
    t.integer  "attachable_id",   :limit => 11
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "thumbnail"
    t.integer  "parent_id",       :limit => 11
  end

  create_table "categories", :force => true do |t|
    t.string "name"
    t.text   "tips"
    t.string "new_post_text"
    t.string "nav_text"
  end

  create_table "choices", :force => true do |t|
    t.integer "poll_id",     :limit => 11
    t.string  "description"
    t.integer "votes_count", :limit => 11, :default => 0
  end

  create_table "clippings", :force => true do |t|
    t.string   "url"
    t.integer  "user_id",         :limit => 11
    t.string   "image_url"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "favorited_count", :limit => 11, :default => 0
  end

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment"
    t.datetime "created_at",                                     :null => false
    t.integer  "commentable_id",   :limit => 11, :default => 0,  :null => false
    t.string   "commentable_type", :limit => 15, :default => "", :null => false
    t.integer  "user_id",          :limit => 11, :default => 0,  :null => false
    t.integer  "recipient_id",     :limit => 11
  end

  add_index "comments", ["user_id"], :name => "fk_comments_user"
  add_index "comments", ["recipient_id"], :name => "index_comments_on_recipient_id"
  add_index "comments", ["created_at"], :name => "index_comments_on_created_at"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_id", "commentable_type"], :name => "index_comments_on_commentable_id_and_commentable_type"

  create_table "contests", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "begin"
    t.datetime "end"
    t.text     "raw_post"
    t.text     "post"
    t.string   "banner_title"
    t.string   "banner_subtitle"
  end

  create_table "countries", :force => true do |t|
    t.string "name"
  end

  create_table "credit_cards", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "month"
    t.string   "year"
    t.string   "verification_value"
    t.integer  "membership_id",      :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "displayable_number"
    t.binary   "number_encrypted"
  end

  create_table "deleted_videos", :force => true do |t|
    t.integer  "video_id",   :limit => 11, :null => false
    t.string   "dockey",                   :null => false
    t.string   "title"
    t.integer  "deleted_by", :limit => 11
    t.string   "video_type"
    t.datetime "deleted_at"
  end

  create_table "events", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",       :limit => 11
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "description"
    t.integer  "metro_area_id", :limit => 11
    t.string   "location"
  end

  create_table "favorites", :force => true do |t|
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "favoritable_type"
    t.integer  "favoritable_id",   :limit => 11
    t.integer  "user_id",          :limit => 11
    t.string   "ip_address",                     :default => ""
  end

  add_index "favorites", ["user_id"], :name => "fk_favorites_user"

  create_table "forums", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "topics_count",     :limit => 11, :default => 0
    t.integer "sb_posts_count",   :limit => 11, :default => 0
    t.integer "position",         :limit => 11
    t.text    "description_html"
    t.string  "owner_type"
    t.integer "owner_id",         :limit => 11
  end

  create_table "friendship_statuses", :force => true do |t|
    t.string "name"
  end

  create_table "friendships", :force => true do |t|
    t.integer  "friend_id",            :limit => 11
    t.integer  "user_id",              :limit => 11
    t.boolean  "initiator",                          :default => false
    t.datetime "created_at"
    t.integer  "friendship_status_id", :limit => 11
  end

  add_index "friendships", ["user_id"], :name => "index_friendships_on_user_id"
  add_index "friendships", ["friendship_status_id"], :name => "index_friendships_on_friendship_status_id"

  create_table "homepage_features", :force => true do |t|
    t.datetime "created_at"
    t.string   "url"
    t.string   "title"
    t.text     "description"
    t.datetime "updated_at"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "parent_id",    :limit => 11
    t.string   "thumbnail"
    t.integer  "size",         :limit => 11
    t.integer  "width",        :limit => 11
    t.integer  "height",       :limit => 11
  end

  create_table "invitations", :force => true do |t|
    t.string   "email_addresses"
    t.string   "message"
    t.string   "user_id"
    t.datetime "created_at"
  end

  create_table "leagues", :force => true do |t|
    t.string   "name"
    t.string   "city"
    t.string   "description"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "state_id",    :limit => 11
    t.integer  "avatar_id",   :limit => 11
  end

  create_table "membership_billing_histories", :force => true do |t|
    t.string   "authorization_reference_number"
    t.string   "payment_method"
    t.integer  "membership_id",                  :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "memberships", :force => true do |t|
    t.string   "name"
    t.string   "billing_method"
    t.decimal  "cost",                         :precision => 8, :scale => 2, :default => 0.0
    t.integer  "address_id",     :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.text     "body"
    t.boolean  "read",                     :default => false
    t.integer  "replied",    :limit => 1
    t.integer  "to_id",      :limit => 11
    t.integer  "from_id",    :limit => 11
  end

  create_table "metro_areas", :force => true do |t|
    t.string  "name"
    t.integer "state_id",    :limit => 11
    t.integer "country_id",  :limit => 11
    t.integer "users_count", :limit => 11, :default => 0
  end

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id", :limit => 11
    t.integer "user_id",  :limit => 11
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

  create_table "monikers", :force => true do |t|
    t.string   "name",                             :null => false
    t.boolean  "user_generated", :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "monitorships", :force => true do |t|
    t.integer "topic_id", :limit => 11
    t.integer "user_id",  :limit => 11
    t.boolean "active",                 :default => true
  end

  create_table "offerings", :force => true do |t|
    t.integer "skill_id", :limit => 11
    t.integer "user_id",  :limit => 11
  end

  create_table "pages", :force => true do |t|
    t.string   "name"
    t.string   "permalink"
    t.text     "content"
    t.text     "html_content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",      :limit => 11
    t.string   "content_type"
    t.string   "filename"
    t.integer  "size",         :limit => 11
    t.integer  "parent_id",    :limit => 11
    t.string   "thumbnail"
    t.integer  "width",        :limit => 11
    t.integer  "height",       :limit => 11
  end

  add_index "photos", ["parent_id"], :name => "index_photos_on_parent_id"

  create_table "polls", :force => true do |t|
    t.string   "question"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "post_id",     :limit => 11
    t.integer  "votes_count", :limit => 11, :default => 0
  end

  create_table "posts", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "raw_post"
    t.text     "post"
    t.string   "title"
    t.integer  "category_id",     :limit => 11
    t.integer  "user_id",         :limit => 11
    t.integer  "view_count",      :limit => 11, :default => 0
    t.integer  "contest_id",      :limit => 11
    t.integer  "emailed_count",   :limit => 11, :default => 0
    t.integer  "favorited_count", :limit => 11, :default => 0
    t.string   "published_as",    :limit => 16, :default => "draft"
    t.datetime "published_at"
    t.integer  "team_id",         :limit => 11
    t.integer  "league_id",       :limit => 11
    t.boolean  "delta",                         :default => false
  end

  add_index "posts", ["category_id"], :name => "index_posts_on_category_id"
  add_index "posts", ["published_at"], :name => "index_posts_on_published_at"
  add_index "posts", ["published_as"], :name => "index_posts_on_published_as"

  create_table "roles", :force => true do |t|
    t.string  "name"
    t.integer "subscription_plan_id", :limit => 11
  end

  create_table "sb_posts", :force => true do |t|
    t.integer  "user_id",    :limit => 11
    t.integer  "topic_id",   :limit => 11
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_id",   :limit => 11
    t.text     "body_html"
  end

  add_index "sb_posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
  add_index "sb_posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"

  create_table "sent_messages", :force => true do |t|
    t.string   "title"
    t.integer  "from_id",    :limit => 11
    t.string   "to_ids"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "sessid"
    t.text     "data"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "sessions", ["sessid"], :name => "index_sessions_on_sessid"

  create_table "skills", :force => true do |t|
    t.string "name"
  end

  create_table "states", :force => true do |t|
    t.string "name"
  end

  create_table "subscription_plans", :force => true do |t|
    t.string   "name"
    t.decimal  "cost",        :precision => 8, :scale => 2, :default => 0.0
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriptions", :force => true do |t|
    t.integer  "membership_id", :limit => 11
    t.integer  "user_id",       :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer "tag_id",        :limit => 11
    t.integer "taggable_id",   :limit => 11
    t.string  "taggable_type"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_type"], :name => "index_taggings_on_taggable_type"
  add_index "taggings", ["taggable_id"], :name => "index_taggings_on_taggable_id"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.string   "city"
    t.string   "description"
    t.boolean  "active"
    t.integer  "league_id",   :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "avatar_id",   :limit => 11
    t.string   "county_name"
    t.integer  "state_id",    :limit => 11
    t.integer  "ad_zone",     :limit => 11, :default => 1
    t.string   "nickname"
  end

  create_table "topics", :force => true do |t|
    t.integer  "forum_id",       :limit => 11
    t.integer  "user_id",        :limit => 11
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hits",           :limit => 11, :default => 0
    t.integer  "sticky",         :limit => 11, :default => 0
    t.integer  "sb_posts_count", :limit => 11, :default => 0
    t.datetime "replied_at"
    t.boolean  "locked",                       :default => false
    t.integer  "replied_by",     :limit => 11
    t.integer  "last_post_id",   :limit => 11
  end

  add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"
  add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
  add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.text     "description"
    t.integer  "avatar_id",                 :limit => 11
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.text     "stylesheet"
    t.integer  "view_count",                :limit => 11, :default => 0
    t.boolean  "vendor",                                  :default => false
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.integer  "state_id",                  :limit => 11
    t.integer  "metro_area_id",             :limit => 11
    t.string   "login_slug"
    t.boolean  "notify_comments",                         :default => true
    t.boolean  "notify_friend_requests",                  :default => true
    t.boolean  "notify_community_news",                   :default => true
    t.integer  "country_id",                :limit => 11
    t.boolean  "featured_writer",                         :default => false
    t.datetime "last_login_at"
    t.string   "zip"
    t.date     "birthday"
    t.string   "gender"
    t.boolean  "profile_public",                          :default => true
    t.integer  "activities_count",          :limit => 11, :default => 0
    t.integer  "sb_posts_count",            :limit => 11, :default => 0
    t.datetime "sb_last_seen_at"
    t.integer  "role_id",                   :limit => 11
    t.string   "firstname"
    t.string   "minitial"
    t.string   "lastname"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "phone"
    t.integer  "team_id",                   :limit => 11
    t.boolean  "enabled"
    t.integer  "league_id",                 :limit => 11
    t.boolean  "delta",                                   :default => false
  end

  add_index "users", ["avatar_id"], :name => "index_users_on_avatar_id"
  add_index "users", ["featured_writer"], :name => "index_users_on_featured_writer"
  add_index "users", ["activated_at"], :name => "index_users_on_activated_at"
  add_index "users", ["vendor"], :name => "index_users_on_vendor"
  add_index "users", ["login_slug"], :name => "index_users_on_login_slug"

  create_table "vidavees", :force => true do |t|
    t.string   "uri"
    t.string   "servlet"
    t.string   "key"
    t.string   "secret"
    t.string   "context"
    t.string   "username"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "video_assets", :force => true do |t|
    t.string   "dockey"
    t.string   "title"
    t.string   "description"
    t.string   "video_length"
    t.string   "video_type"
    t.string   "video_status"
    t.integer  "sponsor_id",         :limit => 11
    t.integer  "member_id",          :limit => 11
    t.integer  "user_id",            :limit => 11
    t.string   "sport"
    t.datetime "game_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "home_team_id",       :limit => 11
    t.integer  "visiting_team_id",   :limit => 11
    t.string   "uploaded_file_path"
    t.string   "game_level"
    t.string   "game_gender"
    t.integer  "view_count",         :limit => 11, :default => 0
    t.integer  "team_id",            :limit => 11
    t.integer  "league_id",          :limit => 11
    t.boolean  "public_video",                     :default => true
    t.boolean  "delta",                            :default => false
    t.integer  "home_score",         :limit => 11
    t.integer  "visitor_score",      :limit => 11
    t.string   "game_type"
    t.string   "gsan"
    t.boolean  "ignore_game_day",                  :default => false
    t.boolean  "ignore_game_month",                :default => false
    t.string   "game_date_str"
    t.text     "internal_notes"
    t.boolean  "missing_audio",                    :default => false
  end

  create_table "video_clips", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.string   "video_length"
    t.string   "dockey"
    t.integer  "video_asset_id", :limit => 11
    t.integer  "user_id",        :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "view_count",     :limit => 11, :default => 0
    t.boolean  "public_video",                 :default => true
    t.boolean  "delta",                        :default => false
  end

  create_table "video_reels", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.integer  "user_id",          :limit => 11
    t.string   "dockey"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "video_length"
    t.string   "thumbnail_dockey"
    t.integer  "view_count",       :limit => 11, :default => 0
    t.boolean  "public_video",                   :default => true
    t.boolean  "delta",                          :default => false
  end

  create_table "votes", :force => true do |t|
    t.string   "user_id"
    t.integer  "poll_id",    :limit => 11
    t.integer  "choice_id",  :limit => 11
    t.datetime "created_at"
  end

end
