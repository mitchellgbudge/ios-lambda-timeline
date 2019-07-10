//
//  Comment.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import FirebaseAuth

class Comment: FirebaseConvertible, Hashable {
    
    static private let textKey = "text"
    static private let audioURLKey = "audioStorageURL"
    static private let authorKey = "author"
    static private let timestampKey = "timestamp"
    
    let text: String?
    var audioURL: URL?
    let author: Author
    let timestamp: Date
    
    init(text: String? = nil, author: Author, timestamp: Date = Date(), audioURL: URL? = nil) {
        self.text = text
        self.author = author
        self.timestamp = timestamp
        self.audioURL = audioURL
    }
    
    init?(dictionary: [String : Any]) {
        guard let authorDictionary = dictionary[Comment.authorKey] as? [String: Any],
            let author = Author(dictionary: authorDictionary),
            let timestampTimeInterval = dictionary[Comment.timestampKey] as? TimeInterval else { return nil }
        
        self.text = dictionary[Comment.textKey] as? String
        self.author = author
        self.timestamp = Date(timeIntervalSince1970: timestampTimeInterval)
        
        if let audioURLString = dictionary[Comment.audioURLKey] as? String {
            self.audioURL = URL(string: audioURLString)
        }
    }
    
    var dictionaryRepresentation: [String: Any] {
        var dictionary: [String: Any] = [Comment.authorKey: author.dictionaryRepresentation,
                                         Comment.timestampKey: timestamp.timeIntervalSince1970]
        
        if let text = text {
            dictionary[Comment.textKey] = text
        }
        
        if let audioURL = audioURL {
            dictionary[Comment.audioURLKey] = audioURL.absoluteString
        }
        
        return dictionary
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(timestamp.hashValue ^ author.displayName!.hashValue)
    }
    //
    //    var hashValue: Int {
    //        return timestamp.hashValue ^
    //            author.displayName!.hashValue
    //    }
    
    static func ==(lhs: Comment, rhs: Comment) -> Bool {
        return lhs.author == rhs.author &&
            lhs.timestamp == rhs.timestamp
    }
}

