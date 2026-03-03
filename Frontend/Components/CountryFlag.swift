//
//  CountryFlag.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct CountryFlag: View {
    let countryCode: String
    var size: CGFloat = 32

    private var flagEmoji: String {
        let base: UInt32 = 127397
        var flagString = ""

        for scalar in countryCode.uppercased().unicodeScalars {
            guard scalar.value >= 65 && scalar.value <= 90 else { return "🌐" }
            flagString.unicodeScalars.append(UnicodeScalar(base + scalar.value)!)
        }

        return flagString
    }

    private var flagImage: Image? {
        Image(countryCode.lowercased())
    }

    var body: some View {
        Group {
            if let flagImage {
                flagImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Text(flagEmoji)
                    .font(.system(size: size))
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        CountryFlag(countryCode: "US")
        CountryFlag(countryCode: "GB")
        CountryFlag(countryCode: "DE")
        CountryFlag(countryCode: "JP")
        CountryFlag(countryCode: "XX")
    }
}
