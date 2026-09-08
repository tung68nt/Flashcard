import SwiftUI
import AppKit

private func findPlatterView(from view: NSView) -> NSView? {
    var curr: NSView? = view.superview
    while let c = curr {
        if String(describing: type(of: c)) == "NSToolbarPlatterView" {
            return c
        }
        curr = c.superview
    }
    return nil
}

public class CompactPlatterHelperView: NSView {
    public var targetHeight: CGFloat = 24
    private var applied = false
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleAdjust()
    }
    
    private func scheduleAdjust(attempt: Int = 0) {
        guard attempt < 15 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            if self.adjustPlatter() {
                // Succeeded
            } else {
                self.scheduleAdjust(attempt: attempt + 1)
            }
        }
    }
    
    @discardableResult
    private func adjustPlatter() -> Bool {
        guard let platter = findPlatterView(from: self), let pSuper = platter.superview else {
            return false
        }
        if !applied {
            platter.translatesAutoresizingMaskIntoConstraints = false
            for c in platter.constraints where c.firstAttribute == .height {
                c.isActive = false
            }
            NSLayoutConstraint.activate([
                platter.heightAnchor.constraint(equalToConstant: self.targetHeight),
                platter.centerYAnchor.constraint(equalTo: pSuper.centerYAnchor)
            ])
            pSuper.needsLayout = true
            pSuper.layoutSubtreeIfNeeded()
            applied = true
        }
        return true
    }
}

public struct CompactToolbarPlatter: NSViewRepresentable {
    public let height: CGFloat
    
    public init(height: CGFloat = 24) {
        self.height = height
    }
    
    public func makeNSView(context: Context) -> NSView {
        let v = CompactPlatterHelperView()
        v.targetHeight = height
        return v
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {}
}
