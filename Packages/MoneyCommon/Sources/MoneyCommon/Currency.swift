// This file was automatically generated and should not be edited.

/// A monetary unit.
public struct Currency: Equatable, Hashable, Codable {
    /// The three letter ISO 4217 currency code.
    public let code: String

    /// The name of the currency.
    public let name: String

    /**
        The number of decimal places used to express
        any minor units for the currency.

        For example, the US Dollar (USD)
        has a minor unit (cents)
        equal to 1/100 of a dollar,
        and therefore takes 2 decimal places.
        The Japanese Yen (JPY)
        doesn't have a minor unit,
        and therefore takes 0 decimal places.
    */
    public let minorUnit: Int

    /// Returns the ISO 4217 currency associated with a given code.
    ///
    /// Currency codes are checked according to a strict, case-sensitive equality comparison.
    ///
    /// - Important: This method returns only currencies defined in the `Money` module.
    ///              For example,
    ///              if you define a custom `Currency` type,
    ///              calling this method with that currency type's `code` returns `nil`.
    ///
    /// - Parameter code: The ISO 4217 currency code
    /// - Returns: A `Currency` type, if one is found
    static public func iso4217Currency(for code: String) -> Currency? {
        switch code {
        case "AED": return .AED
        case "AFN": return .AFN
        case "ALL": return .ALL
        case "AMD": return .AMD
        case "ANG": return .ANG
        case "AOA": return .AOA
        case "ARS": return .ARS
        case "AUD": return .AUD
        case "AWG": return .AWG
        case "AZN": return .AZN
        case "BAM": return .BAM
        case "BBD": return .BBD
        case "BDT": return .BDT
        case "BGN": return .BGN
        case "BHD": return .BHD
        case "BIF": return .BIF
        case "BMD": return .BMD
        case "BND": return .BND
        case "BOB": return .BOB
        case "BOV": return .BOV
        case "BRL": return .BRL
        case "BSD": return .BSD
        case "BTN": return .BTN
        case "BWP": return .BWP
        case "BYN": return .BYN
        case "BZD": return .BZD
        case "CAD": return .CAD
        case "CDF": return .CDF
        case "CHE": return .CHE
        case "CHF": return .CHF
        case "CHW": return .CHW
        case "CLF": return .CLF
        case "CLP": return .CLP
        case "CNY": return .CNY
        case "COP": return .COP
        case "COU": return .COU
        case "CRC": return .CRC
        case "CUC": return .CUC
        case "CUP": return .CUP
        case "CVE": return .CVE
        case "CZK": return .CZK
        case "DJF": return .DJF
        case "DKK": return .DKK
        case "DOP": return .DOP
        case "DZD": return .DZD
        case "EGP": return .EGP
        case "ERN": return .ERN
        case "ETB": return .ETB
        case "EUR": return .EUR
        case "FJD": return .FJD
        case "FKP": return .FKP
        case "GBP": return .GBP
        case "GEL": return .GEL
        case "GHS": return .GHS
        case "GIP": return .GIP
        case "GMD": return .GMD
        case "GNF": return .GNF
        case "GTQ": return .GTQ
        case "GYD": return .GYD
        case "HKD": return .HKD
        case "HNL": return .HNL
        case "HRK": return .HRK
        case "HTG": return .HTG
        case "HUF": return .HUF
        case "IDR": return .IDR
        case "ILS": return .ILS
        case "INR": return .INR
        case "IQD": return .IQD
        case "IRR": return .IRR
        case "ISK": return .ISK
        case "JMD": return .JMD
        case "JOD": return .JOD
        case "JPY": return .JPY
        case "KES": return .KES
        case "KGS": return .KGS
        case "KHR": return .KHR
        case "KMF": return .KMF
        case "KPW": return .KPW
        case "KRW": return .KRW
        case "KWD": return .KWD
        case "KYD": return .KYD
        case "KZT": return .KZT
        case "LAK": return .LAK
        case "LBP": return .LBP
        case "LKR": return .LKR
        case "LRD": return .LRD
        case "LSL": return .LSL
        case "LYD": return .LYD
        case "MAD": return .MAD
        case "MDL": return .MDL
        case "MGA": return .MGA
        case "MKD": return .MKD
        case "MMK": return .MMK
        case "MNT": return .MNT
        case "MOP": return .MOP
        case "MRU": return .MRU
        case "MUR": return .MUR
        case "MVR": return .MVR
        case "MWK": return .MWK
        case "MXN": return .MXN
        case "MXV": return .MXV
        case "MYR": return .MYR
        case "MZN": return .MZN
        case "NAD": return .NAD
        case "NGN": return .NGN
        case "NIO": return .NIO
        case "NOK": return .NOK
        case "NPR": return .NPR
        case "NZD": return .NZD
        case "OMR": return .OMR
        case "PAB": return .PAB
        case "PEN": return .PEN
        case "PGK": return .PGK
        case "PHP": return .PHP
        case "PKR": return .PKR
        case "PLN": return .PLN
        case "PYG": return .PYG
        case "QAR": return .QAR
        case "RON": return .RON
        case "RSD": return .RSD
        case "RUB": return .RUB
        case "RWF": return .RWF
        case "SAR": return .SAR
        case "SBD": return .SBD
        case "SCR": return .SCR
        case "SDG": return .SDG
        case "SEK": return .SEK
        case "SGD": return .SGD
        case "SHP": return .SHP
        case "SLL": return .SLL
        case "SOS": return .SOS
        case "SRD": return .SRD
        case "SSP": return .SSP
        case "STN": return .STN
        case "SVC": return .SVC
        case "SYP": return .SYP
        case "SZL": return .SZL
        case "THB": return .THB
        case "TJS": return .TJS
        case "TMT": return .TMT
        case "TND": return .TND
        case "TOP": return .TOP
        case "TRY": return .TRY
        case "TTD": return .TTD
        case "TWD": return .TWD
        case "TZS": return .TZS
        case "UAH": return .UAH
        case "UGX": return .UGX
        case "USD": return .USD
        case "UYI": return .UYI
        case "UYU": return .UYU
        case "UZS": return .UZS
        case "VEF": return .VEF
        case "VND": return .VND
        case "VUV": return .VUV
        case "WST": return .WST
        case "XCD": return .XCD
        case "YER": return .YER
        case "ZAR": return .ZAR
        case "ZMW": return .ZMW
        case "ZWL": return .ZWL
        default:
            return nil
        }
    }
}

public extension Currency {
    /// UAE Dirham (AED)
    static let AED = Currency(code: "AED", name: "UAE Dirham", minorUnit: 2)
    /// Afghani (AFN)
    static let AFN = Currency(code: "AFN", name: "Afghani", minorUnit: 2)
    /// Lek (ALL)
    static let ALL = Currency(code: "ALL", name: "Lek", minorUnit: 2)
    /// Armenian Dram (AMD)
    static let AMD = Currency(code: "AMD", name: "Armenian Dram", minorUnit: 2)
    /// Netherlands Antillean Guilder (ANG)
    static let ANG = Currency(code: "ANG", name: "Netherlands Antillean Guilder", minorUnit: 2)
    /// Kwanza (AOA)
    static let AOA = Currency(code: "AOA", name: "Kwanza", minorUnit: 2)
    /// Argentine Peso (ARS)
    static let ARS = Currency(code: "ARS", name: "Argentine Peso", minorUnit: 2)
    /// Australian Dollar (AUD)
    static let AUD = Currency(code: "AUD", name: "Australian Dollar", minorUnit: 2)
    /// Aruban Florin (AWG)
    static let AWG = Currency(code: "AWG", name: "Aruban Florin", minorUnit: 2)
    /// Azerbaijan Manat (AZN)
    static let AZN = Currency(code: "AZN", name: "Azerbaijan Manat", minorUnit: 2)
    /// Convertible Mark (BAM)
    static let BAM = Currency(code: "BAM", name: "Convertible Mark", minorUnit: 2)
    /// Barbados Dollar (BBD)
    static let BBD = Currency(code: "BBD", name: "Barbados Dollar", minorUnit: 2)
    /// Taka (BDT)
    static let BDT = Currency(code: "BDT", name: "Taka", minorUnit: 2)
    /// Bulgarian Lev (BGN)
    static let BGN = Currency(code: "BGN", name: "Bulgarian Lev", minorUnit: 2)
    /// Bahraini Dinar (BHD)
    static let BHD = Currency(code: "BHD", name: "Bahraini Dinar", minorUnit: 3)
    /// Burundi Franc (BIF)
    static let BIF = Currency(code: "BIF", name: "Burundi Franc", minorUnit: 0)
    /// Bermudian Dollar (BMD)
    static let BMD = Currency(code: "BMD", name: "Bermudian Dollar", minorUnit: 2)
    /// Brunei Dollar (BND)
    static let BND = Currency(code: "BND", name: "Brunei Dollar", minorUnit: 2)
    /// Boliviano (BOB)
    static let BOB = Currency(code: "BOB", name: "Boliviano", minorUnit: 2)
    /// Mvdol (BOV)
    static let BOV = Currency(code: "BOV", name: "Mvdol", minorUnit: 2)
    /// Brazilian Real (BRL)
    static let BRL = Currency(code: "BRL", name: "Brazilian Real", minorUnit: 2)
    /// Bahamian Dollar (BSD)
    static let BSD = Currency(code: "BSD", name: "Bahamian Dollar", minorUnit: 2)
    /// Ngultrum (BTN)
    static let BTN = Currency(code: "BTN", name: "Ngultrum", minorUnit: 2)
    /// Pula (BWP)
    static let BWP = Currency(code: "BWP", name: "Pula", minorUnit: 2)
    /// Belarusian Ruble (BYN)
    static let BYN = Currency(code: "BYN", name: "Belarusian Ruble", minorUnit: 2)
    /// Belize Dollar (BZD)
    static let BZD = Currency(code: "BZD", name: "Belize Dollar", minorUnit: 2)
    /// Canadian Dollar (CAD)
    static let CAD = Currency(code: "CAD", name: "Canadian Dollar", minorUnit: 2)
    /// Congolese Franc (CDF)
    static let CDF = Currency(code: "CDF", name: "Congolese Franc", minorUnit: 2)
    /// WIR Euro (CHE)
    static let CHE = Currency(code: "CHE", name: "WIR Euro", minorUnit: 2)
    /// Swiss Franc (CHF)
    static let CHF = Currency(code: "CHF", name: "Swiss Franc", minorUnit: 2)
    /// WIR Franc (CHW)
    static let CHW = Currency(code: "CHW", name: "WIR Franc", minorUnit: 2)
    /// Unidad de Fomento (CLF)
    static let CLF = Currency(code: "CLF", name: "Unidad de Fomento", minorUnit: 4)
    /// Chilean Peso (CLP)
    static let CLP = Currency(code: "CLP", name: "Chilean Peso", minorUnit: 0)
    /// Yuan Renminbi (CNY)
    static let CNY = Currency(code: "CNY", name: "Yuan Renminbi", minorUnit: 2)
    /// Colombian Peso (COP)
    static let COP = Currency(code: "COP", name: "Colombian Peso", minorUnit: 2)
    /// Unidad de Valor Real (COU)
    static let COU = Currency(code: "COU", name: "Unidad de Valor Real", minorUnit: 2)
    /// Costa Rican Colon (CRC)
    static let CRC = Currency(code: "CRC", name: "Costa Rican Colon", minorUnit: 2)
    /// Peso Convertible (CUC)
    static let CUC = Currency(code: "CUC", name: "Peso Convertible", minorUnit: 2)
    /// Cuban Peso (CUP)
    static let CUP = Currency(code: "CUP", name: "Cuban Peso", minorUnit: 2)
    /// Cabo Verde Escudo (CVE)
    static let CVE = Currency(code: "CVE", name: "Cabo Verde Escudo", minorUnit: 2)
    /// Czech Koruna (CZK)
    static let CZK = Currency(code: "CZK", name: "Czech Koruna", minorUnit: 2)
    /// Djibouti Franc (DJF)
    static let DJF = Currency(code: "DJF", name: "Djibouti Franc", minorUnit: 0)
    /// Danish Krone (DKK)
    static let DKK = Currency(code: "DKK", name: "Danish Krone", minorUnit: 2)
    /// Dominican Peso (DOP)
    static let DOP = Currency(code: "DOP", name: "Dominican Peso", minorUnit: 2)
    /// Algerian Dinar (DZD)
    static let DZD = Currency(code: "DZD", name: "Algerian Dinar", minorUnit: 2)
    /// Egyptian Pound (EGP)
    static let EGP = Currency(code: "EGP", name: "Egyptian Pound", minorUnit: 2)
    /// Nakfa (ERN)
    static let ERN = Currency(code: "ERN", name: "Nakfa", minorUnit: 2)
    /// Ethiopian Birr (ETB)
    static let ETB = Currency(code: "ETB", name: "Ethiopian Birr", minorUnit: 2)
    /// Euro (EUR)
    static let EUR = Currency(code: "EUR", name: "Euro", minorUnit: 2)
    /// Fiji Dollar (FJD)
    static let FJD = Currency(code: "FJD", name: "Fiji Dollar", minorUnit: 2)
    /// Falkland Islands Pound (FKP)
    static let FKP = Currency(code: "FKP", name: "Falkland Islands Pound", minorUnit: 2)
    /// Pound Sterling (GBP)
    static let GBP = Currency(code: "GBP", name: "Pound Sterling", minorUnit: 2)
    /// Lari (GEL)
    static let GEL = Currency(code: "GEL", name: "Lari", minorUnit: 2)
    /// Ghana Cedi (GHS)
    static let GHS = Currency(code: "GHS", name: "Ghana Cedi", minorUnit: 2)
    /// Gibraltar Pound (GIP)
    static let GIP = Currency(code: "GIP", name: "Gibraltar Pound", minorUnit: 2)
    /// Dalasi (GMD)
    static let GMD = Currency(code: "GMD", name: "Dalasi", minorUnit: 2)
    /// Guinean Franc (GNF)
    static let GNF = Currency(code: "GNF", name: "Guinean Franc", minorUnit: 0)
    /// Quetzal (GTQ)
    static let GTQ = Currency(code: "GTQ", name: "Quetzal", minorUnit: 2)
    /// Guyana Dollar (GYD)
    static let GYD = Currency(code: "GYD", name: "Guyana Dollar", minorUnit: 2)
    /// Hong Kong Dollar (HKD)
    static let HKD = Currency(code: "HKD", name: "Hong Kong Dollar", minorUnit: 2)
    /// Lempira (HNL)
    static let HNL = Currency(code: "HNL", name: "Lempira", minorUnit: 2)
    /// Kuna (HRK)
    static let HRK = Currency(code: "HRK", name: "Kuna", minorUnit: 2)
    /// Gourde (HTG)
    static let HTG = Currency(code: "HTG", name: "Gourde", minorUnit: 2)
    /// Forint (HUF)
    static let HUF = Currency(code: "HUF", name: "Forint", minorUnit: 2)
    /// Rupiah (IDR)
    static let IDR = Currency(code: "IDR", name: "Rupiah", minorUnit: 2)
    /// New Israeli Sheqel (ILS)
    static let ILS = Currency(code: "ILS", name: "New Israeli Sheqel", minorUnit: 2)
    /// Indian Rupee (INR)
    static let INR = Currency(code: "INR", name: "Indian Rupee", minorUnit: 2)
    /// Iraqi Dinar (IQD)
    static let IQD = Currency(code: "IQD", name: "Iraqi Dinar", minorUnit: 3)
    /// Iranian Rial (IRR)
    static let IRR = Currency(code: "IRR", name: "Iranian Rial", minorUnit: 2)
    /// Iceland Krona (ISK)
    static let ISK = Currency(code: "ISK", name: "Iceland Krona", minorUnit: 0)
    /// Jamaican Dollar (JMD)
    static let JMD = Currency(code: "JMD", name: "Jamaican Dollar", minorUnit: 2)
    /// Jordanian Dinar (JOD)
    static let JOD = Currency(code: "JOD", name: "Jordanian Dinar", minorUnit: 3)
    /// Yen (JPY)
    static let JPY = Currency(code: "JPY", name: "Yen", minorUnit: 0)
    /// Kenyan Shilling (KES)
    static let KES = Currency(code: "KES", name: "Kenyan Shilling", minorUnit: 2)
    /// Som (KGS)
    static let KGS = Currency(code: "KGS", name: "Som", minorUnit: 2)
    /// Riel (KHR)
    static let KHR = Currency(code: "KHR", name: "Riel", minorUnit: 2)
    /// Comorian Franc (KMF)
    static let KMF = Currency(code: "KMF", name: "Comorian Franc", minorUnit: 0)
    /// North Korean Won (KPW)
    static let KPW = Currency(code: "KPW", name: "North Korean Won", minorUnit: 2)
    /// Won (KRW)
    static let KRW = Currency(code: "KRW", name: "Won", minorUnit: 0)
    /// Kuwaiti Dinar (KWD)
    static let KWD = Currency(code: "KWD", name: "Kuwaiti Dinar", minorUnit: 3)
    /// Cayman Islands Dollar (KYD)
    static let KYD = Currency(code: "KYD", name: "Cayman Islands Dollar", minorUnit: 2)
    /// Tenge (KZT)
    static let KZT = Currency(code: "KZT", name: "Tenge", minorUnit: 2)
    /// Lao Kip (LAK)
    static let LAK = Currency(code: "LAK", name: "Lao Kip", minorUnit: 2)
    /// Lebanese Pound (LBP)
    static let LBP = Currency(code: "LBP", name: "Lebanese Pound", minorUnit: 2)
    /// Sri Lanka Rupee (LKR)
    static let LKR = Currency(code: "LKR", name: "Sri Lanka Rupee", minorUnit: 2)
    /// Liberian Dollar (LRD)
    static let LRD = Currency(code: "LRD", name: "Liberian Dollar", minorUnit: 2)
    /// Loti (LSL)
    static let LSL = Currency(code: "LSL", name: "Loti", minorUnit: 2)
    /// Libyan Dinar (LYD)
    static let LYD = Currency(code: "LYD", name: "Libyan Dinar", minorUnit: 3)
    /// Moroccan Dirham (MAD)
    static let MAD = Currency(code: "MAD", name: "Moroccan Dirham", minorUnit: 2)
    /// Moldovan Leu (MDL)
    static let MDL = Currency(code: "MDL", name: "Moldovan Leu", minorUnit: 2)
    /// Malagasy Ariary (MGA)
    static let MGA = Currency(code: "MGA", name: "Malagasy Ariary", minorUnit: 2)
    /// Denar (MKD)
    static let MKD = Currency(code: "MKD", name: "Denar", minorUnit: 2)
    /// Kyat (MMK)
    static let MMK = Currency(code: "MMK", name: "Kyat", minorUnit: 2)
    /// Tugrik (MNT)
    static let MNT = Currency(code: "MNT", name: "Tugrik", minorUnit: 2)
    /// Pataca (MOP)
    static let MOP = Currency(code: "MOP", name: "Pataca", minorUnit: 2)
    /// Ouguiya (MRU)
    static let MRU = Currency(code: "MRU", name: "Ouguiya", minorUnit: 2)
    /// Mauritius Rupee (MUR)
    static let MUR = Currency(code: "MUR", name: "Mauritius Rupee", minorUnit: 2)
    /// Rufiyaa (MVR)
    static let MVR = Currency(code: "MVR", name: "Rufiyaa", minorUnit: 2)
    /// Malawi Kwacha (MWK)
    static let MWK = Currency(code: "MWK", name: "Malawi Kwacha", minorUnit: 2)
    /// Mexican Peso (MXN)
    static let MXN = Currency(code: "MXN", name: "Mexican Peso", minorUnit: 2)
    /// Mexican Unidad de Inversion (UDI) (MXV)
    static let MXV = Currency(code: "MXV", name: "Mexican Unidad de Inversion (UDI)", minorUnit: 2)
    /// Malaysian Ringgit (MYR)
    static let MYR = Currency(code: "MYR", name: "Malaysian Ringgit", minorUnit: 2)
    /// Mozambique Metical (MZN)
    static let MZN = Currency(code: "MZN", name: "Mozambique Metical", minorUnit: 2)
    /// Namibia Dollar (NAD)
    static let NAD = Currency(code: "NAD", name: "Namibia Dollar", minorUnit: 2)
    /// Naira (NGN)
    static let NGN = Currency(code: "NGN", name: "Naira", minorUnit: 2)
    /// Cordoba Oro (NIO)
    static let NIO = Currency(code: "NIO", name: "Cordoba Oro", minorUnit: 2)
    /// Norwegian Krone (NOK)
    static let NOK = Currency(code: "NOK", name: "Norwegian Krone", minorUnit: 2)
    /// Nepalese Rupee (NPR)
    static let NPR = Currency(code: "NPR", name: "Nepalese Rupee", minorUnit: 2)
    /// New Zealand Dollar (NZD)
    static let NZD = Currency(code: "NZD", name: "New Zealand Dollar", minorUnit: 2)
    /// Rial Omani (OMR)
    static let OMR = Currency(code: "OMR", name: "Rial Omani", minorUnit: 3)
    /// Balboa (PAB)
    static let PAB = Currency(code: "PAB", name: "Balboa", minorUnit: 2)
    /// Sol (PEN)
    static let PEN = Currency(code: "PEN", name: "Sol", minorUnit: 2)
    /// Kina (PGK)
    static let PGK = Currency(code: "PGK", name: "Kina", minorUnit: 2)
    /// Philippine Piso (PHP)
    static let PHP = Currency(code: "PHP", name: "Philippine Piso", minorUnit: 2)
    /// Pakistan Rupee (PKR)
    static let PKR = Currency(code: "PKR", name: "Pakistan Rupee", minorUnit: 2)
    /// Zloty (PLN)
    static let PLN = Currency(code: "PLN", name: "Zloty", minorUnit: 2)
    /// Guarani (PYG)
    static let PYG = Currency(code: "PYG", name: "Guarani", minorUnit: 0)
    /// Qatari Rial (QAR)
    static let QAR = Currency(code: "QAR", name: "Qatari Rial", minorUnit: 2)
    /// Romanian Leu (RON)
    static let RON = Currency(code: "RON", name: "Romanian Leu", minorUnit: 2)
    /// Serbian Dinar (RSD)
    static let RSD = Currency(code: "RSD", name: "Serbian Dinar", minorUnit: 2)
    /// Russian Ruble (RUB)
    static let RUB = Currency(code: "RUB", name: "Russian Ruble", minorUnit: 2)
    /// Rwanda Franc (RWF)
    static let RWF = Currency(code: "RWF", name: "Rwanda Franc", minorUnit: 0)
    /// Saudi Riyal (SAR)
    static let SAR = Currency(code: "SAR", name: "Saudi Riyal", minorUnit: 2)
    /// Solomon Islands Dollar (SBD)
    static let SBD = Currency(code: "SBD", name: "Solomon Islands Dollar", minorUnit: 2)
    /// Seychelles Rupee (SCR)
    static let SCR = Currency(code: "SCR", name: "Seychelles Rupee", minorUnit: 2)
    /// Sudanese Pound (SDG)
    static let SDG = Currency(code: "SDG", name: "Sudanese Pound", minorUnit: 2)
    /// Swedish Krona (SEK)
    static let SEK = Currency(code: "SEK", name: "Swedish Krona", minorUnit: 2)
    /// Singapore Dollar (SGD)
    static let SGD = Currency(code: "SGD", name: "Singapore Dollar", minorUnit: 2)
    /// Saint Helena Pound (SHP)
    static let SHP = Currency(code: "SHP", name: "Saint Helena Pound", minorUnit: 2)
    /// Leone (SLL)
    static let SLL = Currency(code: "SLL", name: "Leone", minorUnit: 2)
    /// Somali Shilling (SOS)
    static let SOS = Currency(code: "SOS", name: "Somali Shilling", minorUnit: 2)
    /// Surinam Dollar (SRD)
    static let SRD = Currency(code: "SRD", name: "Surinam Dollar", minorUnit: 2)
    /// South Sudanese Pound (SSP)
    static let SSP = Currency(code: "SSP", name: "South Sudanese Pound", minorUnit: 2)
    /// Dobra (STN)
    static let STN = Currency(code: "STN", name: "Dobra", minorUnit: 2)
    /// El Salvador Colon (SVC)
    static let SVC = Currency(code: "SVC", name: "El Salvador Colon", minorUnit: 2)
    /// Syrian Pound (SYP)
    static let SYP = Currency(code: "SYP", name: "Syrian Pound", minorUnit: 2)
    /// Lilangeni (SZL)
    static let SZL = Currency(code: "SZL", name: "Lilangeni", minorUnit: 2)
    /// Baht (THB)
    static let THB = Currency(code: "THB", name: "Baht", minorUnit: 2)
    /// Somoni (TJS)
    static let TJS = Currency(code: "TJS", name: "Somoni", minorUnit: 2)
    /// Turkmenistan New Manat (TMT)
    static let TMT = Currency(code: "TMT", name: "Turkmenistan New Manat", minorUnit: 2)
    /// Tunisian Dinar (TND)
    static let TND = Currency(code: "TND", name: "Tunisian Dinar", minorUnit: 3)
    /// Pa’anga (TOP)
    static let TOP = Currency(code: "TOP", name: "Pa’anga", minorUnit: 2)
    /// Turkish Lira (TRY)
    static let TRY = Currency(code: "TRY", name: "Turkish Lira", minorUnit: 2)
    /// Trinidad and Tobago Dollar (TTD)
    static let TTD = Currency(code: "TTD", name: "Trinidad and Tobago Dollar", minorUnit: 2)
    /// New Taiwan Dollar (TWD)
    static let TWD = Currency(code: "TWD", name: "New Taiwan Dollar", minorUnit: 2)
    /// Tanzanian Shilling (TZS)
    static let TZS = Currency(code: "TZS", name: "Tanzanian Shilling", minorUnit: 2)
    /// Hryvnia (UAH)
    static let UAH = Currency(code: "UAH", name: "Hryvnia", minorUnit: 2)
    /// Uganda Shilling (UGX)
    static let UGX = Currency(code: "UGX", name: "Uganda Shilling", minorUnit: 0)
    /// US Dollar (USD)
    static let USD = Currency(code: "USD", name: "US Dollar", minorUnit: 2)
    /// Uruguay Peso en Unidades Indexadas (UI) (UYI)
    static let UYI = Currency(code: "UYI", name: "Uruguay Peso en Unidades Indexadas (UI)", minorUnit: 0)
    /// Peso Uruguayo (UYU)
    static let UYU = Currency(code: "UYU", name: "Peso Uruguayo", minorUnit: 2)
    /// Uzbekistan Sum (UZS)
    static let UZS = Currency(code: "UZS", name: "Uzbekistan Sum", minorUnit: 2)
    /// Bolívar (VEF)
    static let VEF = Currency(code: "VEF", name: "Bolívar", minorUnit: 2)
    /// Dong (VND)
    static let VND = Currency(code: "VND", name: "Dong", minorUnit: 0)
    /// Vatu (VUV)
    static let VUV = Currency(code: "VUV", name: "Vatu", minorUnit: 0)
    /// Tala (WST)
    static let WST = Currency(code: "WST", name: "Tala", minorUnit: 2)
    /// East Caribbean Dollar (XCD)
    static let XCD = Currency(code: "XCD", name: "East Caribbean Dollar", minorUnit: 2)
    /// Yemeni Rial (YER)
    static let YER = Currency(code: "YER", name: "Yemeni Rial", minorUnit: 2)
    /// Rand (ZAR)
    static let ZAR = Currency(code: "ZAR", name: "Rand", minorUnit: 2)
    /// Zambian Kwacha (ZMW)
    static let ZMW = Currency(code: "ZMW", name: "Zambian Kwacha", minorUnit: 2)
    /// Zimbabwe Dollar (ZWL)
    static let ZWL = Currency(code: "ZWL", name: "Zimbabwe Dollar", minorUnit: 2)
}
