# Before running script, ensure gyb tool is installed on system
# This can be found installed from homebrew:
# brew install nshipster/formulae/gyb
# see article: https://nshipster.com/swift-gyb/ for how to use gyb
gyb --line-directive '' -o Currency.swift Currency.swift.gyb
