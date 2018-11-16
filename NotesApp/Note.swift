import Foundation

class Note {
    var stringID: String
    var title: String
    var updateTime: String
    var message: String

    init(stringID: String, title: String, updateTime: String, message: String) {
        self.stringID = stringID
        self.title = title
        self.updateTime = updateTime
        self.message = message
    }
}
