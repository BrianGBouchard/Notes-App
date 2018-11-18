import Foundation

class Note {
    var stringID: String
    var title: String
    var updateTime: String
    var message: String
    var unix: Double

    init(stringID: String, title: String, updateTime: String, message: String, unix: Double) {
        self.stringID = stringID
        self.title = title
        self.updateTime = updateTime
        self.message = message
        self.unix = unix
    }
}
