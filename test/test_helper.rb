ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

# gem minitest-reporters setup
require 'minitest/reporters'
Minitest::Reporters.use!

class ActiveSupport::TestCase # プロセスが分岐した直後に呼び出される # # 並列テスト ... 複数のプロセスを分岐させテスト時間の短縮を行う機能
  parallelize_setup do |worker|
    load "#{Rails.root}/db/seeds.rb"
  end

  # Run tests in parallel with specified workers
  # 並列テストの有効化・無効化
  # workers: プロセス数を渡す(2以上 => 有効、2未満 => 無効)
  # number_of_processors => 使用しているマシンのコア数(2)
  parallelize(workers: :number_of_processors) # parallelize(workers: 1) # 並列テストを無効にしたい場合

  # 追加
  # アクティブなユーザーを返す
  def active_user
    User.find_by(activated: true)
  end
end
