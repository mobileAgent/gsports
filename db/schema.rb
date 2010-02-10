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

ActiveRecord::Schema.define(:version => 20100209225400) do

  create_table "access_contacts", :force => true do |t|
    t.integer "access_group_id", :limit => 11
    t.string  "contact_type",    :limit => 3
    t.string  "destination"
  end

  create_table "access_groups", :force => true do |t|
    t.string  "name",        :limit => 30
    t.string  "description", :limit => 30
    t.integer "team_id",     :limit => 11
    t.boolean "enabled"
    t.integer "parent_id",   :limit => 11
  end

  create_table "access_items", :force => true do |t|
    t.integer "access_group_id", :limit => 11
    t.string  "item_type"
    t.integer "item_id",         :limit => 11
  end

  add_index "access_items", ["item_type", "item_id"], :name => "index_access_items_on_item_type_and_item_id"

  create_table "access_users", :force => true do |t|
    t.integer "access_group_id", :limit => 11
    t.integer "user_id",         :limit => 11
  end

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

  create_table "channel_videos", :force => true do |t|
    t.string  "video_type"
    t.integer "video_id",   :limit => 11
    t.integer "channel_id", :limit => 11
  end

  create_table "channels", :force => true do |t|
    t.string  "name",         :limit => 30
    t.integer "layout",       :limit => 3
    t.integer "team_id",      :limit => 11
    t.integer "league_id",    :limit => 11
    t.integer "height",       :limit => 11
    t.integer "width",        :limit => 11
    t.integer "thumb_height", :limit => 11
    t.integer "thumb_width",  :limit => 11
    t.integer "thumb_count",  :limit => 11
    t.integer "frame_height", :limit => 11
    t.integer "frame_width",  :limit => 11
    t.integer "thumb_span",   :limit => 11
    t.string  "allow_url"
    t.boolean "autoplay"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "displayable_number"
    t.binary   "number_encrypted"
    t.integer  "user_id",            :limit => 11
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

  create_table "gamex_leagues", :force => true do |t|
    t.integer "league_id",    :limit => 11
    t.integer "release_time", :limit => 11
  end

  create_table "gamex_users", :force => true do |t|
    t.integer "user_id",         :limit => 11
    t.integer "league_id",       :limit => 11
    t.integer "access_group_id", :limit => 11
  end

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
    t.integer  "state_id",      :limit => 11
    t.integer  "avatar_id",     :limit => 11
    t.string   "address1"
    t.string   "address2"
    t.string   "phone"
    t.string   "zip"
    t.string   "email"
    t.boolean  "delta",                       :default => false
    t.integer  "can_publish",   :limit => 1
    t.integer  "publish_limit", :limit => 11
    t.integer  "staff_limit",   :limit => 11
  end

  create_table "membership_billing_histories", :force => true do |t|
    t.string   "authorization_reference_number"
    t.string   "payment_method"
    t.integer  "membership_id",                  :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "credit_card_id",                 :limit => 11
  end

  create_table "membership_cancellations", :force => true do |t|
    t.integer  "membership_id", :limit => 11, :null => false
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "membership_cancellations", ["membership_id"], :name => "index_mem_cancellations_on mem_id"

  create_table "memberships", :force => true do |t|
    t.string   "name"
    t.string   "billing_method"
    t.decimal  "cost",                            :precision => 8, :scale => 2, :default => 0.0
    t.integer  "address_id",        :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "promotion_id",      :limit => 11
    t.integer  "credit_card_id",    :limit => 11
    t.datetime "expiration_date"
    t.string   "status",            :limit => 1,                                :default => "a"
    t.integer  "user_id",           :limit => 11,                                                :null => false
    t.integer  "purchase_order_id", :limit => 11
  end

  add_index "memberships", ["status"], :name => "index_memberships_on_status"
  add_index "memberships", ["user_id"], :name => "index_memberships_on_user_id"
  add_index "memberships", ["created_at"], :name => "index_memberships_on_created_at"

  create_table "message_threads", :force => true do |t|
    t.string   "title",               :limit => 250,                    :null => false
    t.integer  "from_id",             :limit => 11,                     :null => false
    t.datetime "created_at"
    t.string   "to_ids"
    t.text     "to_emails"
    t.string   "to_access_group_ids"
    t.text     "to_phones"
    t.string   "to_roster_entry_ids"
    t.boolean  "is_sms",                             :default => false
  end

  create_table "messages", :force => true do |t|
    t.integer  "thread_id",       :limit => 11,                    :null => false
    t.integer  "sent_message_id", :limit => 11
    t.integer  "to_id",           :limit => 11,                    :null => false
    t.datetime "created_at"
    t.boolean  "read",                          :default => false
    t.boolean  "deleted",                       :default => false
  end

  add_index "messages", ["thread_id"], :name => "index_messages_on_thread_id"
  add_index "messages", ["to_id"], :name => "index_messages_on_to_id"

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

  create_table "permissions", :force => true do |t|
    t.string  "blessed_type"
    t.integer "blessed_id",   :limit => 11
    t.string  "role",         :limit => 30
    t.string  "scope_type"
    t.integer "scope_id",     :limit => 11
  end

  add_index "permissions", ["blessed_type", "blessed_id"], :name => "index_permissions_on_blessed_type_and_blessed_id"
  add_index "permissions", ["scope_type", "scope_id"], :name => "index_permissions_on_scope_type_and_scope_id"

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

  create_table "promotions", :force => true do |t|
    t.string   "promo_code",           :limit => 30,                               :null => false
    t.integer  "subscription_plan_id", :limit => 11
    t.string   "name"
    t.decimal  "cost",                               :precision => 8, :scale => 2
    t.text     "html_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content"
    t.boolean  "enabled"
    t.boolean  "reusable"
    t.integer  "period_days",          :limit => 11
    t.integer  "access_group_id",      :limit => 11
  end

  add_index "promotions", ["promo_code"], :name => "index_promotions_on_promo_code", :unique => true

  create_table "purchase_orders", :force => true do |t|
    t.string   "rep_name"
    t.string   "po_number"
    t.integer  "user_id",     :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "accepted",                  :default => false
    t.datetime "accepted_at"
    t.integer  "accepted_by", :limit => 11
    t.datetime "due_date"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "rating",        :limit => 11, :default => 0
    t.datetime "created_at",                                  :null => false
    t.string   "rateable_type", :limit => 32, :default => "", :null => false
    t.integer  "rateable_id",   :limit => 11, :default => 0,  :null => false
    t.integer  "user_id",       :limit => 11, :default => 0,  :null => false
  end

  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "report_details", :force => true do |t|
    t.integer "report_id",  :limit => 11
    t.string  "video_type"
    t.integer "video_id",   :limit => 11
    t.integer "orderby",    :limit => 11
  end

  create_table "reports", :force => true do |t|
    t.string   "name"
    t.integer  "author_id",   :limit => 11
    t.string   "owner_type"
    t.integer  "owner_id",    :limit => 11
    t.string   "report_type", :limit => 30
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "dockey"
  end

  create_table "roles", :force => true do |t|
    t.string  "name"
    t.integer "subscription_plan_id", :limit => 11
  end

  create_table "roster_entries", :force => true do |t|
    t.integer  "access_group_id", :limit => 11
    t.string   "number"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "email"
    t.string   "phone"
    t.string   "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",         :limit => 11
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
    t.integer  "thread_id",        :limit => 11,                    :null => false
    t.integer  "from_id",          :limit => 11,                    :null => false
    t.text     "body"
    t.datetime "created_at"
    t.integer  "shared_access_id", :limit => 11
    t.boolean  "owner_deleted",                  :default => false
    t.boolean  "sms_notify",                     :default => false
  end

  add_index "sent_messages", ["thread_id"], :name => "index_sent_messages_on_thread_id"
  add_index "sent_messages", ["from_id"], :name => "index_sent_messages_on_from_id"

  create_table "sessions", :force => true do |t|
    t.string   "sessid"
    t.text     "data"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "sessions", ["sessid"], :name => "index_sessions_on_sessid"

  create_table "shared_accesses", :force => true do |t|
    t.string   "key",        :limit => 20
    t.string   "item_type",                :null => false
    t.integer  "item_id",    :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shared_accesses", ["key"], :name => "index_shared_accesses_on_key", :unique => true

  create_table "skills", :force => true do |t|
    t.string "name"
  end

  create_table "sor_configs", :force => true do |t|
    t.integer  "state_id",   :limit => 11,                   :null => false
    t.string   "state_code", :limit => 5,                    :null => false
    t.string   "state_name", :limit => 5,                    :null => false
    t.string   "website",                                    :null => false
    t.boolean  "is_check",                 :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sor_search_logs", :force => true do |t|
    t.integer  "user_id",      :limit => 11
    t.string   "lastname"
    t.string   "firstname"
    t.string   "state_name"
    t.string   "link"
    t.boolean  "is_sor"
    t.string   "html_content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "states", :force => true do |t|
    t.string "name"
    t.string "long_name", :limit => 15
  end

  create_table "subscription_plans", :force => true do |t|
    t.string   "name"
    t.decimal  "cost",        :precision => 8, :scale => 2, :default => 0.0
    t.text     "description"
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

  create_table "team_sports", :force => true do |t|
    t.string   "name"
    t.integer  "team_id",               :limit => 11
    t.integer  "access_group_id",       :limit => 11
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "avatar_id",             :limit => 11
    t.integer  "staff_access_group_id", :limit => 11
  end

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.string   "city"
    t.string   "description"
    t.boolean  "active"
    t.integer  "league_id",     :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "avatar_id",     :limit => 11
    t.string   "county_name"
    t.integer  "state_id",      :limit => 11
    t.integer  "ad_zone",       :limit => 11, :default => 1
    t.string   "nickname"
    t.string   "address1"
    t.string   "address2"
    t.string   "phone"
    t.string   "zip"
    t.string   "email"
    t.boolean  "delta",                       :default => false
    t.integer  "tab_id",        :limit => 11
    t.integer  "can_publish",   :limit => 1
    t.integer  "publish_limit", :limit => 11
    t.integer  "staff_limit",   :limit => 11
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
    t.boolean  "notify_message_email",                    :default => true
    t.boolean  "notify_message_sms",                      :default => true
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
    t.integer  "league_id",              :limit => 11
    t.integer  "team_id",                :limit => 11
    t.integer  "user_id",                :limit => 11
    t.string   "sport"
    t.datetime "game_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "home_team_id",           :limit => 11
    t.integer  "visiting_team_id",       :limit => 11
    t.string   "uploaded_file_path"
    t.string   "game_level"
    t.string   "game_gender"
    t.integer  "view_count",             :limit => 11,  :default => 0
    t.boolean  "public_video",                          :default => true
    t.boolean  "delta",                                 :default => false
    t.integer  "home_score",             :limit => 11
    t.integer  "visitor_score",          :limit => 11
    t.string   "game_type"
    t.string   "gsan"
    t.boolean  "ignore_game_day",                       :default => false
    t.boolean  "ignore_game_month",                     :default => false
    t.string   "game_date_str"
    t.text     "internal_notes"
    t.boolean  "missing_audio",                         :default => false
    t.string   "filmed_by_name",         :limit => 100
    t.integer  "filmed_by",              :limit => 11
    t.string   "announcer_name",         :limit => 100
    t.integer  "announcer",              :limit => 11
    t.integer  "shared_access_id",       :limit => 11
    t.integer  "gamex_league_id",        :limit => 11
    t.datetime "ready_at"
    t.boolean  "gamex_release_override"
  end

  create_table "video_clips", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.string   "video_length"
    t.string   "dockey"
    t.integer  "video_asset_id",   :limit => 11
    t.integer  "user_id",          :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "view_count",       :limit => 11, :default => 0
    t.boolean  "public_video",                   :default => true
    t.boolean  "delta",                          :default => false
    t.integer  "shared_access_id", :limit => 11
  end

  create_table "video_histories", :force => true do |t|
    t.integer  "user_id",        :limit => 11
    t.integer  "team_id",        :limit => 11
    t.integer  "video_asset_id", :limit => 11
    t.string   "activity_type",  :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "video_reel_sources", :force => true do |t|
    t.integer "video_reel_id", :limit => 11
    t.integer "video_clip_id", :limit => 11
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
    t.integer  "shared_access_id", :limit => 11
  end

  create_table "video_users", :force => true do |t|
    t.integer  "user_id",            :limit => 11
    t.string   "title"
    t.string   "description"
    t.integer  "view_count",         :limit => 11, :default => 0
    t.boolean  "public_video",                     :default => true
    t.boolean  "delta",                            :default => false
    t.integer  "shared_access_id",   :limit => 11
    t.string   "dockey"
    t.string   "video_length"
    t.string   "video_type"
    t.string   "video_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ignore_game_day",                  :default => false
    t.boolean  "ignore_game_month",                :default => false
    t.string   "game_date_str"
    t.datetime "game_date"
    t.boolean  "missing_audio",                    :default => false
    t.string   "gsan"
    t.text     "internal_notes"
    t.string   "uploaded_file_path"
  end

  create_table "votes", :force => true do |t|
    t.string   "user_id"
    t.integer  "poll_id",    :limit => 11
    t.integer  "choice_id",  :limit => 11
    t.datetime "created_at"
  end

end
