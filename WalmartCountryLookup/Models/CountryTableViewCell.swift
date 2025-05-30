import UIKit

class CountryTableViewCell: UITableViewCell {
    static let reuseID = "CountryCell"

    private let nameLabel    = UILabel()
    private let codeLabel    = UILabel()
    private let capitalLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setupUI() {
        
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 0

        
        codeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        codeLabel.adjustsFontForContentSizeCategory = true
        codeLabel.textAlignment = .right

       
        capitalLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        capitalLabel.adjustsFontForContentSizeCategory = true
        capitalLabel.numberOfLines = 0

      
        let headerStack = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .firstBaseline
        headerStack.distribution = .fill
        headerStack.spacing = 8

        
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        codeLabel.setContentHuggingPriority(.required, for: .horizontal)

        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, capitalLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    func configure(with country: Country) {
        nameLabel.text    = "\(country.name), \(country.region)"
        codeLabel.text    = country.code
        capitalLabel.text = country.capital
    }
}
