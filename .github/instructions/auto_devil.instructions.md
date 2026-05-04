# Rules
- các mục nên được gọi sang file game_utils.au3 để thực hiện, tránh việc gọi trực tiếp trong các file feature
- các file feature chỉ nên chứa logic liên quan đến feature đó, tránh việc gọi các hàm tiện ích chung trực tiếp trong file feature, thay vào đó nên gọi qua file game_utils.au3 để đảm bảo tính modular và dễ bảo trì
- các hàm tiện ích chung nên được tổ chức trong file game_utils.au3 theo từng nhóm chức năng (ví dụ: nhóm hàm liên quan đến kiểm tra trạng thái game, nhóm hàm liên quan đến thao tác chuột/phím, nhóm hàm liên quan đến logging, v.v.) để dễ dàng tìm kiếm và sử dụng