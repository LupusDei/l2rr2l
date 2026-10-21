# Swift Package Manager Dependencies

This document specifies the SPM dependencies for the L2RR2L iOS app.

## Required Packages

### 1. ConfettiSwiftUI (UI Celebrations)

- **URL**: `https://github.com/simibac/ConfettiSwiftUI.git`
- **Version**: 1.1.0+
- **Purpose**: Confetti animations for correct answers and achievements
- **Usage**: Import in views that need celebration effects

```swift
import ConfettiSwiftUI

struct GameView: View {
    @State private var confettiCounter = 0

    var body: some View {
        ZStack {
            // Game content
            Button("Celebrate!") {
                confettiCounter += 1
            }
        }
        .confettiCannon(counter: $confettiCounter)
    }
}
```

### 2. ViewInspector (Testing)

- **URL**: `https://github.com/nalexn/ViewInspector.git`
- **Version**: 0.9.0+
- **Purpose**: SwiftUI view testing and inspection
- **Target**: Test target only (not main app)

```swift
import XCTest
import ViewInspector
@testable import L2RR2L

final class HomeViewTests: XCTestCase {
    func testHomeViewShowsWelcome() throws {
        let view = HomeView()
        let text = try view.inspect().find(text: "Welcome")
        XCTAssertNotNil(text)
    }
}
```

## Optional Packages

### 3. swift-dependencies (Dependency Injection)

- **URL**: `https://github.com/pointfreeco/swift-dependencies.git`
- **Version**: 1.0.0+
- **Purpose**: Lightweight DI for better testability
- **Recommendation**: Add if testing complexity grows

## Adding Packages in Xcode

1. Open `L2RR2L.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to "Package Dependencies" tab
4. Click "+" to add a package
5. Enter the package URL and select version requirements
6. Choose targets to add the dependency to:
   - ConfettiSwiftUI → L2RR2L (main target)
   - ViewInspector → L2RR2LTests (test target only)

## Version Policy

- Use "Up to Next Major Version" for stability
- Pin to specific versions if needed for reproducible builds
