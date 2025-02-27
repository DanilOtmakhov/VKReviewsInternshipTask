/// Модель отзыва.
struct Review: Decodable {
    
    /// URL фотографии профиля.
    let avatarUrl: String?
    /// Имя пользователя.
    let firstName, lastName: String
    /// Рейтинг.
    let rating: Int
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    /// Ссылки на фотографии, добавленные к отзыву.
    let photoUrls: [String]?
}
