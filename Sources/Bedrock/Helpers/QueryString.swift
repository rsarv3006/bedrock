import Foundation
    
public struct QueryStringHelpers {
    public static func createQueryString(items: [String]) -> String {
        var returnString = ""
        for item in items {
            returnString += "\(item),"
        }
        
        if returnString.last == "," {
            _ = returnString.popLast()
        }
        
        return returnString
    }
}
