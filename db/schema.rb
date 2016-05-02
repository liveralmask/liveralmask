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

ActiveRecord::Schema.define(version: 20160501124443) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provider_accounts", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "uid",          null: false
    t.text     "info",         null: false
    t.text     "access_token", null: false
    t.integer  "account_id",   null: false
    t.string   "login_key",    null: false
  end

  add_index "provider_accounts", ["account_id"], name: "index_provider_accounts_on_account_id", using: :btree
  add_index "provider_accounts", ["login_key"], name: "index_provider_accounts_on_login_key", unique: true, using: :btree
  add_index "provider_accounts", ["uid"], name: "index_provider_accounts_on_uid", unique: true, using: :btree

  create_table "simpolle_question_choices", force: :cascade do |t|
    t.integer  "simpolle_question_id", null: false
    t.integer  "account_id",           null: false
    t.integer  "choice",               null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "simpolle_question_choices", ["account_id"], name: "index_simpolle_question_choices_on_account_id", using: :btree
  add_index "simpolle_question_choices", ["simpolle_question_id"], name: "index_simpolle_question_choices_on_simpolle_question_id", using: :btree

  create_table "simpolle_questions", force: :cascade do |t|
    t.text     "question",   null: false
    t.text     "result",     null: false
    t.integer  "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "simpolle_questions", ["account_id"], name: "index_simpolle_questions_on_account_id", using: :btree

end
