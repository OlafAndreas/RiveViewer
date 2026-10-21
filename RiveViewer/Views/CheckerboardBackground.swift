import SwiftUI

/// Transparent-artboard backdrop, like an image editor's.
struct CheckerboardBackground: View {
    var square: CGFloat = 12

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let light = Color(nsColor: .windowBackgroundColor)
            let dark = Color(nsColor: .quaternaryLabelColor)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(light))
            var y: CGFloat = 0
            var rowIndex = 0
            while y < size.height {
                var x: CGFloat = rowIndex.isMultiple(of: 2) ? 0 : square
                while x < size.width {
                    context.fill(Path(CGRect(x: x, y: y, width: square, height: square)), with: .color(dark))
                    x += square * 2
                }
                y += square
                rowIndex += 1
            }
        }
    }
}
