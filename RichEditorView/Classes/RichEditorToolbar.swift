//
//  RichEditorToolbar.swift
//
//  Created by Caesar Wirth on 4/2/15.
//  Copyright (c) 2015 Caesar Wirth. All rights reserved.
//

import UIKit

/// RichEditorToolbarDelegate is a protocol for the RichEditorToolbar.
/// Used to receive actions that need extra work to perform (eg. display some UI)
@objc public protocol RichEditorToolbarDelegate: class {

    /// Called when the Text Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeTextColor(_ toolbar: RichEditorToolbar)

    /// Called when the Background Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeBackgroundColor(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Image toolbar item is pressed.
    @objc optional func richEditorToolbarInsertImage(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Link toolbar item is pressed.
    @objc optional func richEditorToolbarInsertLink(_ toolbar: RichEditorToolbar)
}

/// RichBarButtonItem is a subclass of UIBarButtonItem that takes a callback as opposed to the target-action pattern
@objcMembers open class RichBarButtonItem: UIBarButtonItem {
    open var actionHandler: (() -> Void)?
    open var option: RichEditorDefaultOption?
    public convenience init(image: UIImage? = nil, selectImage: UIImage? = nil, handler: (() -> Void)? = nil, option: RichEditorDefaultOption? = nil) {
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.setBackgroundImage(selectImage, for: .selected)
        button.frame = CGRect(origin: .zero, size: image?.size ?? .zero)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        self.init(customView: button)
        button.addTarget(self, action: #selector(RichBarButtonItem.buttonWasTapped), for: .touchUpInside)
        actionHandler = handler
        self.option = option
    }
    
    public convenience init(title: String = "", handler: (() -> Void)? = nil, option: RichEditorDefaultOption? = nil) {
        self.init(title: title, style: .plain, target: nil, action: nil)
        target = self
        action = #selector(RichBarButtonItem.buttonWasTapped)
        actionHandler = handler
        self.option = option
    }
    
    @objc func buttonWasTapped() {
        actionHandler?()
    }
}

/// RichEditorToolbar is UIView that contains the toolbar for actions that can be performed on a RichEditorView
@objcMembers open class RichEditorToolbar: UIView {

    /// The delegate to receive events that cannot be automatically completed
    open weak var delegate: RichEditorToolbarDelegate?

    /// A reference to the RichEditorView that it should be performing actions on
    open weak var editor: RichEditorView?

    /// The list of options to be displayed on the toolbar
    open var options: [RichEditorDefaultOption] = [] {
        didSet {
            updateToolbar()
        }
    }

    /// The tint color to apply to the toolbar background.
    open var barTintColor: UIColor? {
        get { return backgroundToolbar.barTintColor }
        set { backgroundToolbar.barTintColor = newValue }
    }

    private var toolbarScroll: UIScrollView
    private var toolbar: UIToolbar
    private var backgroundToolbar: UIToolbar
    
    public override init(frame: CGRect) {
        toolbarScroll = UIScrollView()
        toolbar = UIToolbar()
        backgroundToolbar = UIToolbar()
        // 隐藏顶部分割线
        backgroundToolbar.clipsToBounds = true
        super.init(frame: frame)
        setup()

    }
    
    public required init?(coder aDecoder: NSCoder) {
        toolbarScroll = UIScrollView()
        toolbar = UIToolbar()
        backgroundToolbar = UIToolbar()
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear

        backgroundToolbar.frame = bounds
        backgroundToolbar.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        toolbar.autoresizingMask = .flexibleWidth
        toolbar.backgroundColor = .clear
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)

        toolbarScroll.frame = bounds
        toolbarScroll.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        toolbarScroll.showsHorizontalScrollIndicator = false
        toolbarScroll.showsVerticalScrollIndicator = false
        toolbarScroll.backgroundColor = .clear

        toolbarScroll.addSubview(toolbar)

        addSubview(backgroundToolbar)
        addSubview(toolbarScroll)
        updateToolbar()
    }
    
    private func updateToolbar() {
        var buttons = [UIBarButtonItem]()
        for option in options {
            let handler = { [weak self] in
                if let strongSelf = self {
                    option.action(strongSelf)
                }
            }
            // 创建一个固定的空间，用来调整两个 UIBarButtonItem 之间的间距
            let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            fixedSpace.width = 8 // 设置固定空间的宽度

            if let image = option.image {
                let button = RichBarButtonItem(image: image, handler: handler, option: option)
                buttons.append(button)
            } else {
                let title = option.title
                let button = RichBarButtonItem(title: title, handler: handler, option: option)
                buttons.append(button)
            }
            buttons.append(fixedSpace)
        }
        toolbar.items = buttons

        let defaultIconWidth: CGFloat = 28
        let barButtonItemMargin: CGFloat = 12
        let width: CGFloat = buttons.reduce(0) {sofar, new in
            if let view = new.value(forKey: "view") as? UIView {
                return sofar + view.frame.size.width + barButtonItemMargin
            } else {
                return sofar + (defaultIconWidth + barButtonItemMargin)
            }
        }
        
        if width < frame.size.width {
            toolbar.frame.size.width = frame.size.width + barButtonItemMargin
        } else {
            toolbar.frame.size.width = width + barButtonItemMargin
        }
        toolbar.frame.size.height = 44
        toolbarScroll.contentSize.width = width
        
    }
    
    
    /// 更新选中的item样式
   public func updateToolbarSelectedItem(options: [RichEditorDefaultOption]) {
        let hasOrderList = options.contains(where: {$0 == RichEditorDefaultOption.orderedList})
        let hasUnOrderList = options.contains(where: {$0 == RichEditorDefaultOption.unorderedList})
        toolbar.items?.forEach { item in
            if let button = item as? RichBarButtonItem {
                guard let customView = button.customView as? UIButton else {
                    return
                }
                customView.isSelected = options.contains(where: {$0 == button.option})
                customView.backgroundColor = customView.isSelected ? UIColor.init(red: 0.8, green: 0.89, blue: 1, alpha: 1) : .white
            }
            
        }

    }

}
