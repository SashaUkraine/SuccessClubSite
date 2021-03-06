# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161114231657) do

  create_table "businesses", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "logo",             limit: 255
    t.text     "description",      limit: 65535
    t.string   "video_link",       limit: 255
    t.string   "instruction",      limit: 255
    t.datetime "opened_at"
    t.integer  "min_investitions", limit: 4
    t.string   "status",           limit: 255
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "link_template",    limit: 255,   default: "https://"
  end

  create_table "comments", force: :cascade do |t|
    t.text     "content",          limit: 65535
    t.integer  "rate",             limit: 4,     default: 5
    t.integer  "user_id",          limit: 4
    t.integer  "commentable_id",   limit: 4
    t.string   "commentable_type", limit: 255
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "comments", ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id", using: :btree

  create_table "identities", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "provider",   limit: 255
    t.string   "uid",        limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "identities", ["user_id"], name: "index_identities_on_user_id", using: :btree

  create_table "landings", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "logo",        limit: 255
    t.integer  "price",       limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "path",        limit: 255
    t.string   "description", limit: 255
    t.string   "short_path",  limit: 255
    t.integer  "business_id", limit: 4
    t.string   "preview",     limit: 255
  end

  add_index "landings", ["path"], name: "index_landings_on_path", unique: true, using: :btree
  add_index "landings", ["short_path"], name: "index_landings_on_short_path", unique: true, using: :btree

  create_table "partner_links", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "link",       limit: 255
    t.string   "use_for",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "partner_links", ["user_id"], name: "index_partner_links_on_user_id", using: :btree

  create_table "partnership_depths", force: :cascade do |t|
    t.integer  "percent",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "payments", force: :cascade do |t|
    t.float    "amount",       limit: 24
    t.datetime "created_at",               null: false
    t.integer  "from_user_id", limit: 4
    t.integer  "to_user_id",   limit: 4
    t.string   "from",         limit: 10
    t.string   "to",           limit: 10
    t.string   "method",       limit: 20
    t.string   "code",         limit: 255
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.string   "description",           limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "switch_price",          limit: 4
    t.integer  "month_price",           limit: 4
    t.integer  "spam_per_week",         limit: 4
    t.integer  "adv_per_month",         limit: 4
    t.integer  "online_event_per_week", limit: 4
    t.integer  "landing_pages_number",  limit: 4
    t.integer  "month_team_bonus_ppm",  limit: 4
    t.integer  "partnership_depth",     limit: 4
    t.boolean  "can_edit_video",                    default: false
    t.boolean  "can_start_auction",                 default: false
    t.boolean  "know_partners_backref",             default: false
    t.boolean  "have_investment_belay",             default: false
  end

  create_table "user_businesses", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "business_id",     limit: 4
    t.integer  "partner_link_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "block_reg"
  end

  create_table "user_landings", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "landing_id",      limit: 4
    t.datetime "activated_at"
    t.datetime "reactivate_at"
    t.string   "video_link",      limit: 255
    t.boolean  "has_photo",                   default: false
    t.boolean  "has_vk",                      default: false
    t.boolean  "has_fb",                      default: false
    t.boolean  "has_ok",                      default: false
    t.boolean  "has_youtube",                 default: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "partner_link_id", limit: 4
    t.integer  "viewed",          limit: 4
    t.integer  "registrations",   limit: 4
    t.boolean  "is_club"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "last_name",              limit: 255
    t.date     "birthday"
    t.integer  "sex",                    limit: 4
    t.string   "country",                limit: 255
    t.string   "city",                   limit: 255
    t.string   "about",                  limit: 255
    t.string   "avatar",                 limit: 255
    t.text     "ancestry",               limit: 65535
    t.integer  "role_id",                limit: 8
    t.integer  "parent_id",              limit: 8
    t.integer  "status_id",              limit: 8
    t.integer  "security_id",            limit: 8
    t.integer  "referral_code",          limit: 4
    t.string   "phone",                  limit: 255
    t.string   "skype",                  limit: 255
    t.string   "vk",                     limit: 255
    t.string   "fb",                     limit: 255
    t.string   "ok",                     limit: 255
    t.string   "youtube",                limit: 255
    t.string   "email",                  limit: 255,   default: "",                null: false
    t.string   "encrypted_password",     limit: 255,   default: "",                null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,     default: 0,                 null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.datetime "last_seen"
    t.integer  "refback_percent",        limit: 4,     default: 0
    t.string   "came_from",              limit: 255,   default: "social_networks"
    t.datetime "activated_at"
    t.datetime "reactivate_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "wallets", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.float    "main_balance",  limit: 24, default: 0.0
    t.float    "bonus_balance", limit: 24, default: 0.0
  end

  create_table "withdrawals", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.float    "amount",       limit: 24
    t.string   "method",       limit: 255
    t.boolean  "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "user_account", limit: 255
  end

  add_foreign_key "identities", "users"
  add_foreign_key "partner_links", "users"
end
