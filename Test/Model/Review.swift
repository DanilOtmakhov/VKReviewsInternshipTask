/// Модель отзыва.
struct Review: Decodable {
    
    /// Имя пользователя.
    let firstName, lastName: String
    /// Рейтинг.
    let rating: Int
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String

}
