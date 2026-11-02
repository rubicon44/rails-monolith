class AddVenueAddressToEvents < ActiveRecord::Migration[8.0]
  def change
    # 既存のイベントがあると null: false の追加に失敗するため、既定値 "未定" で埋めてから、既定値を外す（以降は作成時に必ず入力する）
    add_column :events, :venue_address, :string, null: false, default: "未定"
    change_column_default :events, :venue_address, from: "未定", to: nil
  end
end
