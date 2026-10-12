require "io/console"

namespace :admin do
  # 実行例：bin/rails "admin:create[管理者名,admin@example.com,password]"
  # パスワードを省略すると入力を求める（シェルの履歴にパスワードを残したくない場合）
  desc "管理者を作成する"
  task :create, [ :name, :email_address, :password ] => [ :environment ] do |_, args|
    password = args[:password] || STDIN.getpass("パスワード: ")

    administrator = Administrator.new(name: args[:name], email_address: args[:email_address], password: password)

    if administrator.save
      puts "管理者を作成しました：#{administrator.name}（#{administrator.email_address}）"
    else
      abort "管理者を作成できませんでした：#{administrator.errors.full_messages.join('、')}"
    end
  end
end
