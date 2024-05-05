
Reports for YNAB is a mobile app that complements the [YNAB](https://www.ynab.com/) (You Need A Budget) website to provide rich interactive graphs found in the YNAB website in a mobile format. 


## Motivation 

As a YNAB user, I was disappointed not to find some of the rich report charts on the mobile YNAB app that were available on the website. I also 


## Installation



* Open the `Reports.xcodeproj` project in xcode
* You’ll need to [SwiftLint](https://github.com/realm/SwiftLint) installed to build the project or alternatively remove swiftlint from the build phases if you want to build the app without this requirement. 


## Architecture

The app is built using SwiftUI iOS17+ and The composable architecture (TCA) from the [pointfree](https://www.pointfree.co) team. 

**_Why TCA?_**  I was attracted to its state management, composability of screens / features, and powerful features for unit testing code. With addition of Swift Macros, @Observable made TCA more developer friendly, allowing code to be more ergonomic, easier to read by reducing boilerplate code.


## Features

– Login with a YNAB account to see budgets and transactions using one of the provided Chart Reports. The base reports replicate graphs available on the YNAB website but not found in the YNAB Mobile Client.


### Roadmap



* Demo mode access - No YNAB account, no problem, login using an example account to demonstrate app functionality.
* Support 3 types of Reports mirroring those found in the web edition of YNAB
* Export Reports to PDF.
* Support an iPad Edition


## Compatibility

iOS 17+


## License 

Distributed under the MIT License. See `LICENSE.txt` for more information.


## Acknowledgements

* [SwiftYNAB](https://github.com/andrebocchini/swiftynab)

* [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 
