import Foundation
import RNCryptor

func encryptMessage(message: String, encryptionKey: String) -> String {
    let messageData = message.data(using: .utf8)!
    let cipherData = RNCryptor.encrypt(data: messageData, withPassword: encryptionKey)

    return cipherData.base64EncodedString()
}

func decryptMessage(encryptedMessage: String, encryptionKey: String) -> String {
    do {
        let encryptedData = Data.init(base64Encoded: encryptedMessage)!
        let decryptedData = try RNCryptor.decrypt(data: encryptedData, withPassword: encryptionKey)
        let decryptedString = String(data: decryptedData, encoding: .utf8)!

        return decryptedString
    } catch {
        return ""
    }
}

// For adding a "change password" feature: rather than using the user's password as the encryption key, the app will generate a random key and encrpyt that key using the user's password.  Rather than decrypting and re-encrypting all the notes in the database, changing the password would simply decrypt the encryption key and re-encrypt it with the new password
func generateEncryptionKey(withPassword password:String) throws -> String {
    let randomData = RNCryptor.randomData(ofLength: 32)
    let cipherData = RNCryptor.encrypt(data: randomData, withPassword: password)
    return cipherData.base64EncodedString()
}


