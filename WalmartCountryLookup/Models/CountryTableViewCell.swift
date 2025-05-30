import UIKit

struct UIConstants {
    static let padding: CGFloat = 16
    static let interItemSpacing: CGFloat = 8
}

class CountryTableViewCell: UITableViewCell {
    static let reuseID = "CountryCell"

    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let capitalLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        codeLabel.text = nil
        capitalLabel.text = nil
    }

    private func setupUI() {
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        codeLabel.font = .preferredFont(forTextStyle: .subheadline)
        codeLabel.textAlignment = .right
        capitalLabel.font = .preferredFont(forTextStyle: .subheadline)
        capitalLabel.numberOfLines = 0

        let headerStack = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = UIConstants.interItemSpacing
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        codeLabel.setContentHuggingPriority(.required, for: .horizontal)

        let mainStack = UIStackView(arrangedSubviews: [headerStack, capitalLabel])
        mainStack.axis = .vertical
        mainStack.spacing = UIConstants.interItemSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UIConstants.padding),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.padding),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.padding),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.padding)
        ])
    }

    func configure(with country: Country) {
        nameLabel.text = "\(country.name), \(country.region)"
        codeLabel.text = country.code
        capitalLabel.text = country.capital
    }
}
