//
//  TotalReviewsCell.swift
//  Test
//
//  Created by Danil Otmakhov on 24.02.2025.
//

import UIKit

struct TotalReviewsCellConfig {
    
    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: TotalReviewsCellConfig.self)
    
    /// Общее количество отзывов.
    let countText: NSAttributedString
    
    /// Объект, хранящий посчитанные фреймы для ячейки общего количества отзывов.
    fileprivate let layout = TotalReviewsCellLayout()
    
}

// MARK: - TableCellConfig

extension TotalReviewsCellConfig: TableCellConfig {
    
    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? TotalReviewsCell else { return }
        cell.countLabel.attributedText = countText
        cell.config = self
    }
    
    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
}

// MARK: - Cell

final class TotalReviewsCell: UITableViewCell {
    
    fileprivate var config: TotalReviewsCellConfig?
    
    fileprivate let countLabel = UILabel()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        countLabel.frame = layout.countLabelFrame
    }
}

// MARK: - Private

private extension TotalReviewsCell {
    
    func setupCell() {
        contentView.addSubview(countLabel)
        countLabel.textAlignment = .center
    }
    
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки общего количества отзывов.
/// После расчётов возвращается актуальная высота ячейки.
private final class TotalReviewsCellLayout {
    
    // MARK: - Фреймы
    
    private(set) var countLabelFrame = CGRect.zero
    
    // MARK: - Отступы
    
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: TotalReviewsCellConfig, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right
        let countTextSize = config.countText.boundingRect(width: width).size
        
        countLabelFrame = CGRect(
            origin: CGPoint(x: (maxWidth - countTextSize.width) / 2, y: insets.top),
            size: countTextSize
        )

        return insets.top + countTextSize.height + insets.bottom
    }

    
}
