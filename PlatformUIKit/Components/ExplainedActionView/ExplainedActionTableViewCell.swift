//
//  ExplainedActionTableViewCell.swift
//  PlatformUIKit
//
//  Created by Daniel on 16/06/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

public final class ExplainedActionTableViewCell: UITableViewCell {

    // MARK: - Injected
    
    public var viewModel: ExplainedActionViewModel! {
        didSet {
            explainedActionView.viewModel = viewModel
        }
    }
    
    // MARK: - UI Properties
    
    private let explainedActionView = ExplainedActionView()

    // MARK: - Setup
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(explainedActionView)
        explainedActionView.fillSuperview()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
